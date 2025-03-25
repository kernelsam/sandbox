#!/usr/bin/env bash

Invoke-RestMethod -Uri https://aka.ms/downloadazcopy-v10-linux -OutFile azcopy_v10.tar.gz
tar -xvzf azcopy_v10.tar.gz --strip-components=1
./azcopy --version
$AZCOPY_AUTO_LOGIN_TYPE="MSI"
$AZCOPY_MSI_CLIENT_ID=${Env:CLIENTID}
#$AZCOPY_REQUEST_TRY_TIMEOUT=10
          
$containerUrl = "https://senzing.blob.core.windows.net/senzing"

if ( ${Env:SENZING_VERSION} -eq 'latest' ) {
  echo "[INFO] Find latest senzing version"
  ./azcopy list $containerUrl | grep "runtime" | awk '{print $1}' | cut -d/ -f3 | rev | cut -c 2- | rev >> packages
  ${Env:SENZING_VERSION}= cat packages | grep rpm | cut -d "-" -f 3 | Sort-Object { $_ -as [version] } | tail -n1
  rm packages
}
else {
  "[INFO] Verify supplied senzing version exists"
  ./azcopy list $containerUrl | awk '{print $1}' | cut -d/ -f3 | rev | cut -c 2- | rev | grep "${Env:SENZING_VERSION}"
  exit_status=$?
  if ( $exit_status -ne 0 ) {
    echo "[ERROR] Failed to find Senzing version: ${Env:SENZING_VERSION}."
    echo "[ERROR] Please refer to https://senzing.com/releases/ for supported versions."
    exit $exit_status
  }
}

echo "[INFO] Senzing version is: ${Env:SENZING_VERSION}"
$dataversion = ""
$architectures = ""
$opensslversions = ""
if ( [System.Version]"3.10.0" -gt [System.Version]"${Env:SENZING_VERSION}" ) {
  $architectures = "x86"
  $dataversion = "v4"
  $opensslversions = "openssl1"
} 
else {
  $architectures = "x86", "arm"
  $dataversion = "v5"
  $opensslversions = "openssl1", "openssl3"
}

$packages = ./azcopy list $containerUrl | awk '{print $1}' | rev | cut -c 2- | rev | grep "${Env:SENZING_VERSION}"
foreach ($package in $packages) {
  echo "[INFO] ./azcopy cp $containerUrl/$package /tmp/$package --recursive --log-level=DEBUG"
  ./azcopy cp "$containerUrl/$package" "/tmp/$package" --recursive --log-level=DEBUG
}

$packages = ./azcopy list $containerUrl | awk '{print $1}' | rev | cut -c 2- | rev | grep "$dataversion"
foreach ($package in $packages) {
  echo "[INFO] ./azcopy cp $containerUrl/$package /tmp/$package --recursive --log-level=DEBUG"
  ./azcopy cp "$containerUrl/$package" "/tmp/$package" --recursive --log-level=DEBUG
}

$StorageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}
foreach ($arch in $architectures) { 
  echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path $arch -Context $storageAccount.Context"
  New-AzStorageDirectory -ShareName 'senzing' -Path "$arch" -Context $storageAccount.Context
  foreach ($opensslversion in $opensslversions) { 
    echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path $arch/$opensslversion -Context $storageAccount.Context"
    New-AzStorageDirectory -ShareName 'senzing' -Path "$arch/$opensslversion" -Context $storageAccount.Context

    cd "/tmp/$arch/$opensslversion"
    $CurrentFolder = (Get-Item .).FullName
    $Container = Get-AzStorageShare -Name 'senzing' -Context $StorageAccount.Context
    Get-ChildItem -Recurse | Where-Object { $_.GetType().Name -eq "FileInfo"} | ForEach-Object {
      $path=$_.FullName.Substring($Currentfolder.Length+1).Replace("\","/")
      Write-Host "[INFO] Set-AzStorageFileContent -ShareName 'senzing' -Source $_ -Path $arch/$opensslversion/$path -Force -Context"
      Set-AzStorageFileContent -ShareName 'senzing' -Source "$_" -Path "$arch/$opensslversion/$path" -Force -Context $storageAccount.Context
    }
  }
}
