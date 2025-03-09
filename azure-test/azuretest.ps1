#!/usr/bin/env bash

#Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/Azure/azure-docs-json-samples/master/mslearn-arm-deploymentscripts-sample/appsettings.json' -OutFile 'appsettings.json'
#$storageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}
#$blob = Set-AzStorageBlobContent -File 'appsettings.json' -Container 'senzing' -Blob 'appsettings.json' -Context $StorageAccount.Context

Invoke-RestMethod -Uri https://aka.ms/downloadazcopy-v10-linux -OutFile azcopy_v10.tar.gz
tar -xvzf azcopy_v10.tar.gz --strip-components=1
ls -tlc
./azcopy --version
$Env:AZCOPY_AUTO_LOGIN_TYPE = "MSI"
$Env:AZCOPY_MSI_CLIENT_ID = ${Env:CLIENTID}
./azcopy login --identity-client-id ${Env:CLIENTID}

echo "[INFO] ./azcopy list https://senzing.blob.core.windows.net/senzing/${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}"
./azcopy list "https://senzing.blob.core.windows.net/senzing/${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}"

cat /etc/os-release
#apt update
#apt install snapd
#apt install -y unzip

#curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#ls -tlc
#echo "[INFO] unzip -q awscli"
#unzip -q awscliv2.zip
#echo "[INFO] install awscli"
#./aws/install

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
elseif ( ${Env:OPENSSLVERSION} -eq '1' ) {
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

#${Env:RPM_PATH} = "s3://senzing-production-yum/${Env:RPM_PLATFORM_PATH}/${Env:RPM_ARCHITECTURE}"
#${Env:DEB_PATH} = "s3://senzing-production-apt/${Env:DEB_PLATFORM_PATH}/s/se/"

#if ( ${Env:SENZING_VERSION} -eq 'latest' ) {
#  echo "[INFO] Find latest senzing version"
#  echo "[INFO aws s3 ls ${Env:RPM_PATH} --no-sign-request"
#  aws s3 ls "${Env:RPM_PATH}/" --no-sign-request
#  aws s3 ls "${Env:RPM_PATH}/" --no-sign-request | grep "runtime" | awk '{print $NF}' >> packages
#  cat packages
#  ${Env:SENZING_VERSION}= cat packages | sort -r | head -n 1 | cut -d "-" -f 3
#  rm packages
#}
#else {
#  "[INFO] Verify supplied senzing version exists"
#  aws s3 ls "${Env:RPM_PATH}/" --no-sign-request | awk '{print $NF}' | grep "${Env:SENZING_VERSION}"
#  exit_status=$?
#  if ( $exit_status -ne 0 ) {
#    echo "[ERROR] Failed to find Senzing version: ${Env:SENZING_VERSION}."
#    echo "[ERROR] Please refer to https://senzing.com/releases/ for supported versions."
#    exit $exit_status
#  }
#}
#echo "[INFO] Senzing version is: ${Env:SENZING_VERSION}"

$StorageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}

mkdir rpm
./azcopy "https://senzing.blob.core.windows.net/senzing/${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" rpm/ --recursive
cd rpm
#$packages = aws s3 ls ${Env:RPM_PATH}/ --no-sign-request | awk '{print $NF}' | grep "${Env:SENZING_VERSION}" | grep '.rpm'
#for ( package in ${packages} ) {
#  echo "[INFO] download: $package"
#  echo "[INFO] aws s3 sync --exclude=* --include=$package ${Env:RPM_PATH} . --no-sign-request"
#  aws s3 sync --exclude="*" --include="$package" "${Env:RPM_PATH}" . --no-sign-request
  $CurrentFolder = (Get-Item .).FullName
  $Container = Get-AzStorageShare -Name ${Env:STORAGEACCOUNT}
  Get-ChildItem -Recurse | Where-Object { $_.GetType().Name -eq "FileInfo"} | ForEach-Object {
    $path=$_.FullName.Substring($Currentfolder.Length+1).Replace("\","/")
    Set-AzStorageFileContent -ShareClient $Container -Source $_.FullName -Path $path -Force -Context $storageAccount.Context
  }
  #Set-AzStorageFileContent -ShareName 'senzing' -Source "$package" -Path "${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" -Context $storageAccount.Context
#}
cd -
rm -rf rpm

#mkdir deb
#cd deb
#$packages= aws s3 ls ${Env:DEB_PATH} --no-sign-request | awk '{print $NF}' | grep "${Env:SENZING_VERSION}" | grep '.deb'
#for ( package in ${packages} ) {
#  echo "[INFO] download: $package"
#  aws s3 sync --exclude="*" --include="$package" "${Env:DEB_PATH}" . --no-sign-request
#  Set-AzStorageFileContent -ShareName 'senzing' -Source "$package" -Path "${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" -Context $storageAccount.Context
#}
#cd -
#rm -rf deb

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