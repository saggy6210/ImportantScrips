#!/bin/bash

#open port 3000-3200

for port in {0..199..2}
do
	sPort=`expr $port + 1`
	sshPort=`expr $sPort + 3000`
	tomcatPort=`expr $port + 3000`
	echo "ssh Port: $sshPort Tomcat Port: $tomcatPort"
	docker run -d --cap-add=SYS_PTRACE --security-opt seccomp=unconfined --security-opt apparmor=unconfined --rm=true -p $tomcatPort:8080 -p $sshPort:22 <image-name>
	
done
