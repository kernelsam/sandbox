#!/usr/bin/env bash

Invoke-RestMethod -Uri https://aka.ms/downloadazcopy-v10-linux -OutFile azcopy_v10.tar.gz
tar -xvzf azcopy_v10.tar.gz --strip-components=1
./azcopy --version
$AZCOPY_AUTO_LOGIN_TYPE="MSI"
$AZCOPY_MSI_CLIENT_ID=${Env:CLIENTID}
echo "principal id: ${Env:PRINCIPALID}"
echo "tenant id: ${Env:TENANTID}"
$AZCOPY_REQUEST_TRY_TIMEOUT=1

if ( ${Env:ARCHITECTURE} -eq 'x86' ) {
  ${Env:DEB_ARCHITECTURE} = 'amd64'
  ${Env:RPM_ARCHITECTURE} = 'x86_64'
} 
elseif (${Env:ARCHITECTURE} -eq 'ARM') {
  ${Env:DEB_ARCHITECTURE} = 'arm64'
  ${Env:RPM_ARCHITECTURE} = 'aarch64'
}
else {
  Write-Host '[ERROR] unsupported architecture found.'
  exit 1
}

if ( ${Env:OPENSSLVERSION} -eq '3' ) {
  ${Env:DEB_PLATFORM_PATH} = 'ubuntu/pool/noble'
  ${Env:RPM_PLATFORM_PATH} = 'amazonlinux/2023'
} 
elseif ( ${Env:OPENSSLVERSION} -eq '1' ) {
  ${Env:DEB_PLATFORM_PATH} = 'debian/pool/bullseye'
  ${Env:RPM_PLATFORM_PATH} = 'amazonlinux/2'
}
else {
  Write-Host '[ERROR] unsupported openssl version found.'
  exit 1
}
          
Write-Host "[INFO] architecture is: ${Env:ARCHITECTURE}"
Write-Host "[INFO] rpm platform path is: ${Env:RPM_PLATFORM_PATH}"
Write-Host "[INFO] deb platform path is: ${Env:DEB_PLATFORM_PATH}"

df -h

$containerUrl = "https://senzing.blob.core.windows.net/senzing/${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" 

# Get an access token for managed identities for Azure resources
$response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' `
                              -Headers @{Metadata="true"}
curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true -s  
$content =$response.Content | ConvertFrom-Json
$access_token = $content.access_token
echo "The managed identities for Azure resources access token is $access_token"

echo "[INFO] ./azcopy cp $containerUrl /tmp --recursive --log-level=DEBUG"
./azcopy cp "$containerUrl" /tmp --recursive --log-level=DEBUG

df -h

ls -tlc /tmp

$StorageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}" -Context $storageAccount.Context
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" -Context $storageAccount.Context

$CurrentFolder = (Get-Item .).FullName
ls -tlc
pwd
ls -tlc x86/openssl3/
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
