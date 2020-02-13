#!/bin/bash

function awscliCheck() {
    # Install pip 
    echo "--------------------------------------------"
    echo "pip check:- "
	curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" &> /dev/null
	apt-get -y install python &> /dev/null
	python get-pip.py &> /dev/null
    echo "pip is Installed"
    # Install AWS CLI using pip
    echo "AWS CLI check:- "
	pip install awscli &> /dev/null    
	aws --version
    echo "AWS CLI is Installed"
    echo "--------------------------------------------"
    echo
    echo
}
function dockerCheck(){    
echo "--------------------------------------------"
    echo "Docker Check :- "
    dockerOutput=$(docker -v &> /dev/null)
	if [ $? -eq 0 ]; then
        echo "$(docker --version | head -1 | awk '{print $1,$2,$3}' | cut -d ',' -f1)  is installed!"
    else
        echo "Docker is not installed! Installing..."                   
        # install required prerequisites packages for docker-ce
        apt-get update -y &> /dev/null
		echo
		apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common &> /dev/null
		echo 
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - &> /dev/null
		add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &> /dev/null
		echo 
        # install docker-ce
        echo "Installing docker-ce"
		echo
		apt-get update -y &> /dev/null ; apt-get -y install docker-ce docker-ce-cli containerd.io &> /dev/null
    fi
    echo "--------------------------------------------"
    echo
    echo
}
function dockerComposeCheck(){
	echo "--------------------------------------------"
    echo "Docker-compose Check :- "
	dockerComposeOutput=$(docker-compose -v &> /dev/null)	
	if [ $? -eq 0 ]; then
       	echo "$(docker-compose --version | head -1 | awk '{print $1,$2,$3}' | cut -d ',' -f1)  is installed!"
    else
       	echo "Docker-compose is not installed! Installing..." 
		sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
		sudo chmod +x /usr/local/bin/docker-compose
		sudo mv /usr/local/bin/docker-compose /usr/bin/docker-compose
		sudo docker-compose --version
	fi
    echo "--------------------------------------------"
    echo
    echo
}

function installMongo(){
	echo "--------------------------------------------"
	echo "Installing Mongodb.."
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 4B7C549A058F8B6B
	#Ubuntu 18.4
	echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb.list
	#Ubuntu 16.4
	#echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb.list
	sudo apt-get update -y
	sudo apt-get install -y mongodb-org
	sudo sed -ie 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf
	sudo systemctl start mongod
	sudo systemctl status mongod
	sudo systemctl enable mongod
	echo "Mongodb installed successfully"
	echo "Running iptables Flush operation"
	iptables -F
	echo "--------------------------------------------"
	echo
	echo
}
awscliCheck
dockerCheck
dockerComposeCheck
installMongo
