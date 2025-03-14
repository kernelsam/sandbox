#!/usr/bin/env bash

#Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/Azure/azure-docs-json-samples/master/mslearn-arm-deploymentscripts-sample/appsettings.json' -OutFile 'appsettings.json'
#$storageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}
#$blob = Set-AzStorageBlobContent -File 'appsettings.json' -Container 'senzing' -Blob 'appsettings.json' -Context $StorageAccount.Context

Invoke-RestMethod -Uri https://aka.ms/downloadazcopy-v10-linux -OutFile azcopy_v10.tar.gz
tar -xvzf azcopy_v10.tar.gz --strip-components=1
./azcopy --version
export AZCOPY_AUTO_LOGIN_TYPE="MSI"
export AZCOPY_MSI_CLIENT_ID=${Env:CLIENTID}
#export AZCOPY_MSI_OBJECT_ID=<object-id>
#export AZCOPY_MSI_RESOURCE_STRING=<resource-id>
./azcopy login --identity --identity-client-id ${Env:CLIENTID}

#echo "[INFO] ./azcopy list https://senzing.blob.core.windows.net/senzing/${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}"
#./azcopy list "https://senzing.blob.core.windows.net/senzing/${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}"

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

df -h

$containerUrl = "https://senzing.blob.core.windows.net/senzing/${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" 

echo "[INFO] ./azcopy cp $containerUrl /tmp --recursive --log-level=DEBUG"
./azcopy cp "$containerUrl" /tmp --recursive --log-level=DEBUG

df -h

ls -tlc /tmp

# cat /root/.azcopy/*.log

# Extract the container name from the URL
# $containerName = ($containerUrl -split "/")[-1]

# Create a local folder
#$localFolder = ".\$containerName"
#if (-Not (Test-Path -Path $localFolder)) {
#    New-Item -ItemType Directory -Path $localFolder
#}

#$restApiUrl = "$($containerUrl)?restype=container&comp=list"
#Write-Host "[INFO] REST API URL: $restApiUrl"

#try {
    # Retrieve information of all files under the container
#    Invoke-RestMethod -Uri $restApiUrl -OutFile .\$containerName.xml
#    [xml]$xmlContent = Get-Content -Path .\$containerName.xml
#}
#catch {
#    Write-Error "[ERROR] Failed to fetch container information. Error: $_"
#    exit 1
#}

#foreach ($blob in $xmlContent.EnumerationResults.Blobs.Blob) {
#    $blobUrl = $blob.Url
#    $blobName = $blob.Name

#    Write-Host "[INFO] Processing Blob: $blobName"

#    $localFilePath = Join-Path $localFolder $blobName

#    $localFileDir = Split-Path $localFilePath -Parent
#    if (-Not (Test-Path -Path $localFileDir)) {
#        New-Item -ItemType Directory -Path $localFileDir
#    }

#    try {
#        Invoke-WebRequest -Uri $blobUrl -OutFile $localFilePath
#        Write-Host "[INFO] Downloaded: $blobUrl to $localFilePath"
#    }
#    catch {
#        Write-Error "[ERROR] Failed to download $blobUrl. Error: $_"
#    }
#}

#Write-Host "[INFO] All files have been downloaded to the $localFolder folder."



$StorageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:RESOURCEGROUP} -Name ${Env:STORAGEACCOUNT}
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}" -Context $storageAccount.Context
echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION} -Context $storageAccount.Context"
New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" -Context $storageAccount.Context

#ls -tlc
#apt update
#apt install -y wget
#wget -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux
#ls -tlc
#echo "[INFO] tar -xvzf azcopy_v10.tar.gz --strip-components=1"
#tar -xvzf azcopy_v10.tar.gz --strip-components=1
#ls -tlc
#./azcopy --version
#$Env:AZCOPY_AUTO_LOGIN_TYPE = "MSI"
#$Env:AZCOPY_MSI_CLIENT_ID = ${Env:CLIENTID}
#./azcopy login --identity --identity-client-id ${Env:CLIENTID}
echo "[INFO] ./azcopy cp /tmp/openssl${Env:OPENSSLVERSION} https://${Env:STORAGEACCOUNT}.file.core.windows.net/senzing/${Env:ARCHITECTURE} --recursive"
./azcopy cp "/tmp/openssl${Env:OPENSSLVERSION}" "https://${Env:STORAGEACCOUNT}.file.core.windows.net/senzing/${Env:ARCHITECTURE}" --recursive --log-level=DEBUG
# ./azcopy cp "https://senzing.blob.core.windows.net/senzing/${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" $localFolder --recursive

#$packages = aws s3 ls ${Env:RPM_PATH}/ --no-sign-request | awk '{print $NF}' | grep "${Env:SENZING_VERSION}" | grep '.rpm'
#for ( package in ${packages} ) {
#  echo "[INFO] download: $package"
#  echo "[INFO] aws s3 sync --exclude=* --include=$package ${Env:RPM_PATH} . --no-sign-request"
#  aws s3 sync --exclude="*" --include="$package" "${Env:RPM_PATH}" . --no-sign-request
################################################################################################################################
# working file share upload
#  $CurrentFolder = (Get-Item .).FullName
#  ls -tlc
#  pwd
#  ls -tlc x86/openssl3/
#  $Container = Get-AzStorageShare -Name 'senzing' -Context $StorageAccount.Context
#  echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE} -Context $storageAccount.Context"
#  New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}" -Context $storageAccount.Context
#  echo "[INFO] New-AzStorageDirectory -ShareName senzing -Path ${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION} -Context $storageAccount.Context"
#  New-AzStorageDirectory -ShareName 'senzing' -Path "${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" -Context $storageAccount.Context
#  Get-ChildItem -Recurse | Where-Object { $_.GetType().Name -eq "FileInfo"} | ForEach-Object {
#    $path=$_.FullName.Substring($Currentfolder.Length+1).Replace("\","/")
#    Write-Host "[INFO] Set-AzStorageFileContent -ShareName 'senzing' -Source $_ -Path $path -Force -Context"
#    Set-AzStorageFileContent -ShareName 'senzing' -Source "$_" -Path "$path" -Force -Context $storageAccount.Context
#  }
################################################################################################################################
  #Set-AzStorageFileContent -ShareName 'senzing' -Source "$package" -Path "${Env:ARCHITECTURE}/openssl${Env:OPENSSLVERSION}" -Context $storageAccount.Context
#}


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