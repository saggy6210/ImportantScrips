#!/bin/bash
#Author: Sagar Chavan

APP_DIR="<WORKING_DIR>"
BUCKET_NAME="<BUCKET_NAME>"
DAT=`date +%d%m%Y%H%M`
PRIVATE_IP_ADDR=`ifconfig eth0 | grep inet | awk 'NR==1 {print $2}'`

function downloadSetupFiles(){
	echo "--------------------------------------------"
    echo "--------------------------------------------"
   	echo "Downloading from AWS S3 buckets..."
    if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'
   	then
		echo "${BUCKET_NAME} does not exist"
	else
		echo "Bucket ${BUCKET_NAME} downloading..."
    aws s3 cp s3://${BUCKET_NAME}/<file_path>/rhel-compose.yaml ${APP_DIR}/ 
  fi
	echo "--------------------------------------------"
    	echo
    	echo
}


function securityEnablement(){
        touch $APP_DIR/security_enablement.js
        cat >> $APP_DIR/security_enablement.js << EOL
var myuser = { "user": "username", "pwd": "password", "roles": ["readWrite", "dbAdmin" ] };
use <db_name>;
db.createUser(myuser);
EOL
        mongo --host ${PRIVATE_IP_ADDR} < $APP_DIR/security_enablement.js
        echo "exit" | mongo --host ${PRIVATE_IP_ADDR} --username username --password password --authenticationDatabase "<db_name>"
        sudo sed -ie "s/#security:/security:\n  authorization: \"enabled\"/g" /etc/mongod.conf
        sudo systemctl restart mongod
        sudo systemctl status mongod
	rm -rf $APP_DIR/security_enablement.js
}


function dataSeed(){
	echo "--------------------------------------------"
	echo "Performing Data seed operation on Mongod.."
	mongo --host ${PRIVATE_IP_ADDR}  --username username --password password --authenticationDatabase "<db_name>" < $APP_DIR/cloud-db-setup-appliance.js
	echo "--------------------------------------------"
	echo 
	echo
}

function dockerLoad(){
	echo "--------------------------------------------"
	echo "Dockerload Operation.."
  aws ecr get-login --registry-ids <ECR_ID>
	$(aws ecr get-login --region us-east-1 --no-include-email)
	docker-compose -f ./compose.yaml up -d
}

function configChange(){
	echo "--------------------------------------------"
	echo "Updating Config YAML & cloudhedgeenv files.."
	cp $APP_DIR/compose.yaml $APP_DIR/compose.yaml_$DAT
	sed -ie "s/host:<IP>/cloudhedgehost:${PRIVATE_IP_ADDR}/g" $APP_DIR/compose.yaml
	sed -ie "s/host:<IP>/cloudhedgehost:${PRIVATE_IP_ADDR}/g" $APP_DIR/compose.yaml
	echo "Successfully updated"
	echo "--------------------------------------------"
	echo
	echo
}

##Download the setup fles 
downloadSetupFiles

## Check if App directory exist
if [[ -d $APP_DIR ]]
then
	cd $APP_DIR
	echo "--------------------------------------------"
	echo "$APP_DIR exist, proceeding with Appliance setup.."
	if [[ -f $APP_DIR/rhel-compose.yaml ]]
	then
		mv $APP_DIR/rhel-compose.yaml $APP_DIR/compose.yaml
    else
        echo "$APP_DIR/rhel-compose.yaml does not exist"
	fi
	if [[ -f $APP_DIR/rhel-cloudhedgeenv ]]
	then
		mv $APP_DIR/rhel-cloudhedgeenv $APP_DIR/cloudhedgeenv
    else
        echo "$APP_DIR/rhel-cloudhedgeenv does not exist"
	fi
else
	echo "$APP_DIR does not exist, plesse create $APP_DIR directory and make sure required files are exist"
	echo "--------------------------------------------"
	exit 1
fi
cd $APP_DIR
echo "Current Working Directory : $APP_DIR"
echo 


## Seed data into MongoDB
#dataSeed

## Update Configuration File 
configChange

container_list=`cat $APP_DIR/compose.yaml | grep image | awk '{print $2}' | awk -F '/' '{print $2}' |awk -F':' '{print $1}'`
services=`docker images | awk '{print $1}' | awk -F '/' '{print $2}'`
a=()
for i in $container_list; do
        found=
        for j in $services; do
                if [ $i == $j ]; then
                        found=1
                        echo "Service Name exist in  compose file: $j"
                        break
                fi
        done
        if [ !$found ]; then
            echo "Service Name does exist in  compose file, Stoping container service: $i"
            docker stop $i
            a+=($i)
        fi
done

images_list=`echo ${a[*]}`
for image in $images_list; do
        image_id=`docker images | grep $image | awk '{print $3}'`
        echo "removing docker image :$image" 
        docker rmi -f $image_id
done
echo "Cleanup Job Completed"



## Bring container up using docker-compose
echo "--------------------------------------------"
echo "Pulling Docker images from ECR and bringing up docker container.."
dockerLoad

echo "--------------------------------------------"
echo 
echo

## Container Status
echo "--------------------------------------------"
echo "checking Container brought up successfully"
data=`curl http://${URL}/api/v0/auth/healthCheckAllServices`
out=`echo $data | jq .services`
container_list=`cat compose.yaml | grep image | awk '{print $2}' | awk -F '/' '{print $2}' |awk -F':' '{print $1}'`
echo "====================================================================="
echo -e " Service_Name\t\tContainer_Status Service_Status"
for i in $container_list
do
        container_status=`docker container ls | grep $i`
        if [ $? -eq 0 ]; then
            status=`echo $out | jq -r --arg service "$i" '.[] | select(.name == $service) | .status'`
            echo "$i UP $status" | awk -v FS=" " 'BEGIN{print "\t\t";print "======================================"}{printf "%s\t%s\t%s%s",$1,$2,$3,ORS}' | column -t
        
        else
            echo "$i UP $status" | awk -v FS=" " 'BEGIN{print "\t\t";print "======================================"}{printf "%s\t%s\t%s%s",$1,$2,$3,ORS}' | column -t
        fi
done
echo "--------------------------------------------"
echo 
echo
