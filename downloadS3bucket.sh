#!/bin/bash
# @auther Sagar Chavan

AWS_KEY=$1
AWS_SECRET=$2
RELEASE=$3
BUILD_ID=$4
CHFORM=$5 
AWS_REGION=us-east-1
BUCKET_NAME=<Bucket Name>
APP_DIR="/mnt/<Bucket Name>/appliance"
DAT=`date +%d%m%Y%H%M`
echo "RELEASE: ${RELEASE}"
echo "BUILD NUMBER: ${BUILD_ID}"
echo "CH FORMFACTOR: ${CHFORM}"
echo "Applince Setup Working Directory : ${APP_DIR}"
##Usage
if [[ $# -ne 5 ]]
then
	echo "--------------------------------------------"
	echo "Script running at :"`date +%d-%m-%Y:%H:%M`
	echo "Usage of Script: $0 AWS_KEY AWS_SECRETE RELEASE BUILD_NUMBER CH_PATTERN"
	echo "Example: $0 ******** ************ rel-1.2 rel-1.2-3 CHFROM"
	echo "--------------------------------------------"
	exit 1
fi  
echo

function downloadSetupFiles(){
	echo "--------------------------------------------"
   	echo "Configuring AWS..."
    	export AWS_ACCESS_KEY_ID=${AWS_KEY}
    	export AWS_SECRET_ACCESS_KEY=${AWS_SECRET}
	    export AWS_REGION=${AWS_REGION}
	    aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID} 
	    aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY} 
	    aws configure set region ${AWS_REGION}
    	if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'
   	  then
		    echo "${BUCKET_NAME} does not exist"
	    else
		    echo "Bucket ${BUCKET_NAME} downloading..."
		    rm -rf ${APP_DIR}
		    mkdir -p ${APP_DIR}
		    aws s3 cp s3://${BUCKET_NAME}/${RELEASE}/${BUILD_ID}/${CHFORM}/ ${APP_DIR}/ --recursive
    	fi
	echo "--------------------------------------------"
    	echo
    	echo
}

function verifyDownload()
{

    echo "Verifying downloaded setup files"
	s3_bucket_tar_size=`aws s3 ls --summarize s3://${BUCKET_NAME}/${RELEASE}/${BUILD_ID}/${CHFORM}/singlefile.tar.gz | awk -F ' ' 'NR==1{print $3}'`
	echo "S3 Tar Size: ${s3_bucket_tar_size}"
	ls ${APP_DIR}/singlefile.tar.gz
	output=`file ${APP_DIR}/singlefile.tar.gz | grep -q 'gzip compressed data' && echo yes || echo no`
	if [ ${output} == "yes" ]
	then 
		downloaded_tar_size=`du -b ${APP_DIR}/singlefile.tar.gz | awk -F ' ' 'NR==1{print $1}'`
		echo "Downloaded Tar size: ${s3_bucket_tar_size}"
		if [ ${downloaded_tar_size} -eq ${s3_bucket_tar_size} ]
		then
			echo "Verification Status: Downloaded Completely!"
		else
			echo "Verification Status: Checksum not matching, please try again!"
			exit
		fi
	else 
		echo "Verification Status: tar file failed to download, please try again!"
		exit
	fi
}
downloadSetupFiles
verifyDownload
