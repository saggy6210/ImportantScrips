#!/bin/bash

INSTANCE_ID=$1
OPERATION=$2
AWS_KEY=$3
AWS_SECRET=$4
AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=${AWS_KEY}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET}
export AWS_REGION=${AWS_REGION}
aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
aws configure set region ${AWS_REGION}
timer=0
if [ $OPERATION == "start" ];then
	aws ec2 start-instances --instance-ids ${INSTANCE_ID}
	reachablityStatus=`aws ec2 describe-instance-status --instance-id ${INSTANCE_ID} --query "InstanceStatuses[].InstanceStatus[].Details[]" | grep "Status" | awk -F ":" '{print $2}' | sed 's/[" ,]//g'`
	systemstatus=`aws ec2 describe-instance-status --instance-id ${INSTANCE_ID} --query "InstanceStatuses[].SystemStatus[].Details[]" | grep "Status" | awk -F ":" '{print $2}' | sed 's/[" ,]//g'`
	while [ $timer -le 6 ] 
	do
		runningStatus=`aws ec2 describe-instance-status --instance-id ${INSTANCE_ID} --query "InstanceStatuses[].InstanceState[]" | grep "Name" | awk -F ":" '{print $2}' | sed 's/[" ,]//g'`
		timer=$(( $timer + 1 ))		if [ "${runningStatus}" == "running" ];then
			echo "VM $INSTANCE_ID is up and Running"
			break
		else
			timer=$(( $timer + 1 ))
			sleep 10
		fi
	done
	if [ $timer -ge 6 ];then
		echo "VM $INSTANCE_ID is failed to start!"
		exit
	fi
else
	aws ec2 stop-instances --instance-ids ${INSTANCE_ID}
fi
