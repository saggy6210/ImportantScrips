#!/bin/bash
#___Author: Sagar Chavan ________
while IFS= read -r file
do
	filename=`echo $file | awk '{print $4}'`
	permission=`echo $file | awk '{print $1}'`
	user=`echo $file | awk '{print $2}'`
	group=`echo $file | awk '{print $3}'`
	if [[ -f $filename || -d $filename ]]; then 
		newpermission=`sudo stat -c "%a" $filename`
		newuser=`stat -c "%U" $filename`
		newgroup=`stat -c "%G" $filename`
		if [ $permission -ne $newpermission ]; then 
			echo "permission doesnt match for this file $filename"
			exit
		fi
		if [ $user != $newuser ]; then
                        echo "user doesnt match for this file $filename"
                        exit
                fi
                if [ $group != $newgroup ]; then
                        echo "user doesnt match for this file $filename"
                        exit
                fi

	fi
done < /tmp/mylist
