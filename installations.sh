#!/bin/bash
PRIVATE_IP_ADDR=<YOUR IP ADDRESS>
APP_DIR="/home/centos/setup-scripts"
function dockerCheck() {
        echo "--------------------------------------------"
        echo "Docker Check :- "
        dockerOutput=$(rpm -qa | grep docker &> /dev/null)
        if [ $? -eq 0 ]; then
                echo "$(docker --version | head -1 | awk '{print $1,$2,$3}' | cut -d ',' -f1)  is installed!"
        else
            echo "Docker is not installed! Installing..."                   

                # install required prerequisites packages for docker-ce
                sudo yum update -y &> /dev/null
                sudo yum install curl -y &> /dev/null
                # install docker-ce
                echo -en "Installing docker-ce..."
                sudo curl -fsSL https://get.docker.com/ | sh &> /dev/null
                sudo systemctl start docker &> /dev/null
                sudo systemctl status docker
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
	sudo touch /etc/yum.repos.d/mongodb-org.repo
	cat >> /etc/yum.repos.d/mongodb-org.repo <<EOL
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
EOL
	sudo yum install mongodb-org -y
	sudo sed -ie 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf
	sudo systemctl enable mongod
	sudo systemctl start mongod
	sudo systemctl status mongod
	echo "Mongodb installed successfully"
	echo "Running iptables Flush operation"
	iptables -F
	echo "--------------------------------------------"
	echo
	echo
}
function securityEnablement(){
        touch $APP_DIR/security_enablement.js
        cat >> $APP_DIR/security_enablement.js << EOL
var cloudhedgeuser = { "user": "chuser", "pwd": "chpass", "roles": ["readWrite", "dbAdmin" ] };
use ch-db;
db.createUser(cloudhedgeuser);
EOL
        mongo --host ${PRIVATE_IP_ADDR} < $APP_DIR/security_enablement.js
        echo "exit" | mongo --host ${PRIVATE_IP_ADDR} --username chuser --password chpass --authenticationDatabase "ch-db"
        sudo sed -ie "s/#security:/security:\n  authorization: \"enabled\"/g" /etc/mongod.conf
        sudo systemctl restart mongod
        sudo systemctl status mongod
        rm -rf $APP_DIR/security_enablement.js
}

dockerCheck
dockerComposeCheck
installMongo
securityEnablement
