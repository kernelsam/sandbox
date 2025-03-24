#!/usr/bin/env bash

Invoke-RestMethod -Uri https://aka.ms/downloadazcopy-v10-linux -OutFile azcopy_v10.tar.gz
tar -xvzf azcopy_v10.tar.gz --strip-components=1
./azcopy --version
$AZCOPY_AUTO_LOGIN_TYPE="MSI"
$AZCOPY_MSI_CLIENT_ID=${Env:CLIENTID}
echo "principal id: ${Env:PRINCIPALID}"
echo "tenant id: ${Env:TENANTID}"
$AZCOPY_REQUEST_TRY_TIMEOUT=1
          
Write-Host "[INFO] architecture is: ${Env:ARCHITECTURE}"
Write-Host "[INFO] rpm platform path is: ${Env:RPM_PLATFORM_PATH}"
Write-Host "[INFO] deb platform path is: ${Env:DEB_PLATFORM_PATH}"

$containerUrl = "https://senzing.blob.core.windows.net/senzing/${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" 

echo "[INFO] ./azcopy cp $containerUrl /tmp --recursive --log-level=DEBUG"
./azcopy cp "$containerUrl" /tmp --recursive --log-level=DEBUG

$StorageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}" -Context $storageAccount.Context
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" -Context $storageAccount.Context

ls -tlc /tmp/openssl3
cd /tmp/openssl3
$CurrentFolder = (Get-Item .).FullName
$Container = Get-AzStorageShare -Name 'senzing' -Context $StorageAccount.Context
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}" -Context $storageAccount.Context
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" -Context $storageAccount.Context
Get-ChildItem -Recurse | Where-Object { $_.GetType().Name -eq "FileInfo"} | ForEach-Object {
  $path=$_.FullName.Substring($Currentfolder.Length+1).Replace("\","/")
  Write-Host "[INFO] Set-AzStorageFileContent -ShareName 'senzing' -Source $_ -Path $path -Force -Context"
  Set-AzStorageFileContent -ShareName 'senzing' -Source "$_" -Path "$path" -Force -Context $storageAccount.Context
}
