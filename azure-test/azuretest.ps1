Invoke-RestMethod -Uri https://aka.ms/downloadazcopy-v10-linux -OutFile azcopy_v10.tar.gz
tar -xvzf azcopy_v10.tar.gz --strip-components=1
ls -tlc
./azcopy --version
$Env:AZCOPY_AUTO_LOGIN_TYPE = 'AZCLI'
./azcopy login

echo \"[INFO] az account show\"
az account show

echo \"[INFO] ./azcopy list https://${Env:STORAGEACCOUNT}.blob.core.windows.net/senzing\"
./azcopy list \"https://${Env:STORAGEACCOUNT}.blob.core.windows.net/senzing\"

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
          
echo \"[INFO] architecture is: ${Env:ARCHITECTURE}\"
echo \"[INFO] rpm platform path is: ${Env:RPM_PLATFORM_PATH}\"
echo \"[INFO] deb platform path is: ${Env:DEB_PLATFORM_PATH}\"

${Env:RPM_PATH} = \"https://senzing-production-yum.s3.amazonaws.com/${Env:RPM_PLATFORM_PATH}/${Env:RPM_ARCHITECTURE}/\"
${Env:DEB_PATH} = \"https://senzing-production-apt.s3.amazonaws.com/${Env:DEB_PLATFORM_PATH}/s/se/\"

echo \"[INFO] ./azcopy copy ${Env:RPM_PATH}senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm https://${Env:STORAGEACCOUNT}.blob.core.windows.net/senzing\"
./azcopy copy \"${Env:RPM_PATH}senzingapi-${Env:SENZING_VERSION}.${Env:RPM_ARCHITECTURE}.rpm\" \"https://${Env:STORAGEACCOUNT}.blob.core.windows.net/senzing\"