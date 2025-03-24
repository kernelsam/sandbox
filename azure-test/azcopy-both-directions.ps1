#!/usr/bin/env bash

Invoke-RestMethod -Uri https://aka.ms/downloadazcopy-v10-linux -OutFile azcopy_v10.tar.gz
tar -xvzf azcopy_v10.tar.gz --strip-components=1
./azcopy --version
$AZCOPY_AUTO_LOGIN_TYPE="MSI"
$AZCOPY_MSI_CLIENT_ID=${Env:CLIENTID}
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

echo "[INFO] ./azcopy cp $containerUrl /tmp --recursive --log-level=DEBUG"
./azcopy cp "$containerUrl" /tmp --recursive --log-level=DEBUG

$StorageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}" -Context $storageAccount.Context
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" -Context $storageAccount.Context


$Env:AZCOPY_AUTO_LOGIN_TYPE = "MSI"
$Env:AZCOPY_MSI_CLIENT_ID = ${Env:CLIENTID}
./azcopy login --identity --identity-client-id ${Env:CLIENTID}
ls -tlc "/tmp/openssl${Env:OPENSSLVERSION}"

echo "[INFO] ./azcopy cp /tmp/openssl${Env:OPENSSLVERSION} https://${Env:STORAGEACCOUNT}.file.core.windows.net/senzing/${Env:ARCHITECTURE} --recursive --log-level=DEBUG"
./azcopy cp "/tmp/openssl${Env:OPENSSLVERSION}" "https://${Env:STORAGEACCOUNT}.file.core.windows.net/senzing/${Env:ARCHITECTURE}" --recursive --log-level=DEBUG
