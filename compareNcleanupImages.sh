#!/bin/bash
#________Author: Sagar Chavan______________

container_list=`cat compose.yaml | grep image | awk '{print $2}' | awk -F '/' '{print $2}' |awk -F':' '{print $1}'`
services=`docker images | awk '{print $1}' | awk -F '/' '{print $2}'`
a=()
    for i in $container_list; do
        found=
        for j in $services; do
            if [ $i == $j ]; then
                found=1
                echo "$j"
                break
            fi
        done
        if [ !$found ]; then
            a+=($i)
        fi
    done

    images_list=`echo ${a[*]}`
    for image in $images_list
    do
            image_id=`docker images | grep $image | awk '{print $3}'`
            echo "removing docker image :$image" 
			docker rmi -f $image_id
    done
