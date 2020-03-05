#!/bin/bash
#________Author: Sagar Chavan______________
running_container_list=`docker container ls | awk 'FNR > 1 {print $2}' | awk -F '/' '{print $2}'`
service_list=`cat compose.yaml_new | grep image | awk '{print $2}' | awk -F '/' '{print $2}'`
#services=`docker images | awk '{print $1}' | awk -F '/' '{print $2}'`
a=()
for i in $running_container_list; do
	found=
        for j in $service_list; do
            	if [ $i == $j ]; then
			#echo " $i || $j"
                	found=1
			echo "--------------------------------------------------------------"
			echo 
                	echo "Container Name exist in compose file: $j"
                        echo "--------------------------------------------------------------"
                        echo 
                	break
            	fi
        done
        if [ "$found" != "1" ]; then
		echo "--------------------------------------------------------------"
            	echo 
	    	echo "Container does not exist in compose file: $i"
	    	container_id=`docker container ls | grep $i | awk '{print $1}'`
	    	image_name=`echo $i | awk -F':' '{print $1}'`
	    	image_id=`docker images | grep $image_name | awk '{print $3}'`
	    	echo "Stopping the container $container_id"
            	docker stop $container_id
	    	echo "Removing docker Image Name: $image_name, Image ID: $image_id"
	    	docker rmi -f $image_id
            	#a+=($i)
            	echo "--------------------------------------------------------------"
            	echo 
        fi
done
#images_list=`echo ${a[*]}`
#for image in $images_list; do
#	image_id=`docker images | grep $image | awk '{print $3}'`
#	echo "removing docker image :$image" 
#	#docker rmi -f $image_id
#done
echo "Cleanup Job Completed"


