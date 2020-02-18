#!/bin/bash
URL=<Your Healthcheck URL>
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
