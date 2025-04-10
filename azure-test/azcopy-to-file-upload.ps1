#!/usr/bin/env bash

Invoke-RestMethod -Uri https://aka.ms/downloadazcopy-v10-linux -OutFile azcopy_v10.tar.gz
tar -xvzf azcopy_v10.tar.gz --strip-components=1
./azcopy --version
$AZCOPY_AUTO_LOGIN_TYPE="MSI"
$AZCOPY_MSI_CLIENT_ID=${Env:CLIENTID}
echo "principal id: ${Env:PRINCIPALID}"
echo "tenant id: ${Env:TENANTID}"
$AZCOPY_REQUEST_TRY_TIMEOUT=5

$arch=$(${Env:ARCHITECTURE}.ToLower())
          
Write-Host "[INFO] architecture is: $arch"

$containerUrl = "https://senzing.blob.core.windows.net/senzing/$arch/openssl${Env:OPENSSLVERSION}" 

echo "[INFO] ./azcopy cp $containerUrl /tmp/$arch --recursive --log-level=DEBUG"
./azcopy cp "$containerUrl" /tmp/$arch --recursive --log-level=DEBUG

$StorageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path $arch -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "$arch" -Context $storageAccount.Context
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path $arch/openssl${Env:OPENSSLVERSION} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "$arch/openssl${Env:OPENSSLVERSION}" -Context $storageAccount.Context

ls -tlc /tmp/$arch/openssl${Env:OPENSSLVERSION}
cd /tmp/$arch/openssl${Env:OPENSSLVERSION}
$CurrentFolder = (Get-Item .).FullName
$Container = Get-AzStorageShare -Name 'senzing' -Context $StorageAccount.Context

Get-ChildItem -Recurse | Where-Object { $_.GetType().Name -eq "FileInfo"} | ForEach-Object {
  $path=$_.FullName.Substring($Currentfolder.Length+1).Replace("\","/")
  Write-Host "[INFO] Set-AzStorageFileContent -ShareName 'senzing' -Source $_ -Path $arch/openssl${Env:OPENSSLVERSION}/$path -Force -Context"
  Set-AzStorageFileContent -ShareName 'senzing' -Source "$_" -Path "$arch/openssl${Env:OPENSSLVERSION}/$path" -Force -Context $storageAccount.Context
}
