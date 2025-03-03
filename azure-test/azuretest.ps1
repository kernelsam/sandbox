#!/usr/bin/env bash

#Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/Azure/azure-docs-json-samples/master/mslearn-arm-deploymentscripts-sample/appsettings.json' -OutFile 'appsettings.json'
#$storageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}
#$blob = Set-AzStorageBlobContent -File 'appsettings.json' -Container 'senzing' -Blob 'appsettings.json' -Context $StorageAccount.Context

#Invoke-RestMethod -Uri https://aka.ms/downloadazcopy-v10-linux -OutFile azcopy_v10.tar.gz
#tar -xvzf azcopy_v10.tar.gz --strip-components=1
#ls -tlc
#./azcopy --version
#$Env:AZCOPY_AUTO_LOGIN_TYPE = "MSI"
#$Env:AZCOPY_MSI_CLIENT_ID = ${Env:CLIENTID}
#./azcopy login --identity #--identity-client-id ${Env:CLIENTID}

#echo "[INFO] ./azcopy list https://${Env:STORAGEACCOUNT}.blob.core.windows.net/senzing"
#./azcopy list "https://${Env:STORAGEACCOUNT}.blob.core.windows.net/senzing"

cat /etc/os-release
apt update
apt install -y unzip

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

${Env:SENZING_VERSION} = '3.12.5-25031'

if ( ${Env:ARCHITECTURE} -eq 'x86' ) {
  ${Env:DEB_ARCHITECTURE} = 'amd64'
  ${Env:RPM_ARCHITECTURE} = 'x86_64'
} 
elseif (${Env:ARCHITECTURE} -eq 'ARM') {
  ${Env:DEB_ARCHITECTURE} = 'arm64'
  ${Env:RPM_ARCHITECTURE} = 'aarch64'
}
else {
  echo '[ERROR] unsupported architecture found.'
  exit 1
}

if ( ${Env:OPENSSLVERSION} -eq '3' ) {
  ${Env:DEB_PLATFORM_PATH} = 'ubuntu/pool/noble'
  ${Env:RPM_PLATFORM_PATH} = 'amazonlinux/2023'
} 
elseif (${Env:OPENSSLVERSION} -eq '1') {
  ${Env:DEB_PLATFORM_PATH} = 'debian/pool/bullseye'
  ${Env:RPM_PLATFORM_PATH} = 'amazonlinux/2'
}
else {
  echo '[ERROR] unsupported openssl version found.'
  exit 1
}
          
echo "[INFO] architecture is: ${Env:ARCHITECTURE}"
echo "[INFO] rpm platform path is: ${Env:RPM_PLATFORM_PATH}"
echo "[INFO] deb platform path is: ${Env:DEB_PLATFORM_PATH}"

${Env:RPM_PATH} = "https://senzing-production-yum.s3.amazonaws.com/${Env:RPM_PLATFORM_PATH}/${Env:RPM_ARCHITECTURE}"
${Env:DEB_PATH} = "https://senzing-production-apt.s3.amazonaws.com/${Env:DEB_PLATFORM_PATH}/s/se/"

$StorageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}

mkdir rpm
cd rpm
aws s3 cp --recursive --exclude="*" --include="*.rpm" "${Env:RPM_PATH}" . --no-sign-request
Get-ChildItem -File -Recurse | Set-AzStorageBlobContent -Container 'senzing' -Context $StorageAccount.Context
cd -
rm -rf rpm

mkdir deb
cd deb
aws s3 cp --recursive --exclude="*" --include="*.deb" "${Env:DEB_PATH}" . --no-sign-request
Get-ChildItem -File -Recurse | Set-AzStorageBlobContent -Container 'senzing' -Context $StorageAccount.Context
cd -

#echo "[INFO] Invoke-RestMethod -Uri ${Env:RPM_PATH}/senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm -OutFile senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm"
#Invoke-RestMethod -Uri "${Env:RPM_PATH}/senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm" -OutFile "senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm"
#Set-AzStorageBlobContent -File "senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm" -Container 'senzing' -Blob "senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm" -Context $StorageAccount.Context
#rm "senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm"

#echo "[INFO] Invoke-RestMethod -Uri ${Env:RPM_PATH}/senzingapi-runtime-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm -OutFile senzingapi-runtime-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm"
#Invoke-RestMethod -Uri "${Env:RPM_PATH}/senzingapi-runtime-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm" -OutFile "senzingapi-runtime-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm"
#Set-AzStorageBlobContent -File "senzingapi-runtime-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm" -Container 'senzing' -Blob "senzingapi-runtime-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm" -Context $StorageAccount.Context
#rm "senzingapi-runtime-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm"

#echo "[INFO] ./azcopy copy ${Env:RPM_PATH}/senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm https://${Env:STORAGEACCOUNT}.blob.core.windows.net/senzing/senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm"
#./azcopy copy "${Env:RPM_PATH}/senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm" "https://${Env:STORAGEACCOUNT}.blob.core.windows.net/senzing/senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm"

#cat /root/.azcopy/*.log