#!/usr/bin/env bash

Invoke-RestMethod -Uri https://aka.ms/downloadazcopy-v10-linux -OutFile azcopy_v10.tar.gz
tar -xvzf azcopy_v10.tar.gz --strip-components=1
./azcopy --version
$AZCOPY_AUTO_LOGIN_TYPE="MSI"
$AZCOPY_MSI_CLIENT_ID=${Env:CLIENTID}
$AZCOPY_REQUEST_TRY_TIMEOUT=10
          
$containerUrl = "https://senzing.blob.core.windows.net/senzing" 

echo "[INFO] ./azcopy cp $containerUrl /tmp --recursive --log-level=DEBUG"
./azcopy cp "$containerUrl" /tmp --recursive --log-level=DEBUG

if ( ${Env:SENZING_VERSION} -eq 'latest' ) {
  echo "[INFO] Find latest senzing version"
  ls "/tmp/x86/openssl3"
  ls "/tmp/x86/openssl3" | grep "runtime" | awk '{print $NF}' >> packages
  cat packages
  ${Env:SENZING_VERSION}= cat packages | sort -r | head -n 1 | cut -d "-" -f 3
  rm packages
}
else {
  "[INFO] Verify supplied senzing version exists"
  ls "/tmp/x86/openssl3" | awk '{print $NF}' | grep "${Env:SENZING_VERSION}"
  exit_status=$?
  if ( $exit_status -ne 0 ) {
    echo "[ERROR] Failed to find Senzing version: ${Env:SENZING_VERSION}."
    echo "[ERROR] Please refer to https://senzing.com/releases/ for supported versions."
    exit $exit_status
  }
}
echo "[INFO] Senzing version is: ${Env:SENZING_VERSION}"


$StorageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}
$architectures = "x86", "arm"
opensslversions = "openssl1", "openssl3"
foreach ($arch in $architectures) { 
  echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path $arch -Context $storageAccount.Context"
  New-AzStorageDirectory -ShareName 'senzing' -Path "$arch" -Context $storageAccount.Context
  foreach ($opensslversion in $opensslversions) { 
    echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path $arch/$opensslversion -Context $storageAccount.Context"
    New-AzStorageDirectory -ShareName 'senzing' -Path "$arch/$opensslversion" -Context $storageAccount.Context

    cd "/tmp/$arch/$opensslversion"
    $CurrentFolder = (Get-Item .).FullName
    $Container = Get-AzStorageShare -Name 'senzing' -Context $StorageAccount.Context
    Get-ChildItem -Recurse -contains ${Env:SENZING_VERSION} | Where-Object { $_.GetType().Name -eq "FileInfo"} | ForEach-Object {
      $path=$_.FullName.Substring($Currentfolder.Length+1).Replace("\","/")
      Write-Host "[INFO] Set-AzStorageFileContent -ShareName 'senzing' -Source $_ -Path $arch/$opensslversion/$path -Force -Context"
      Set-AzStorageFileContent -ShareName 'senzing' -Source "$_" -Path "$arch/$opensslversion/$path" -Force -Context $storageAccount.Context
    }
  }
}
