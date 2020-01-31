#!/bin/bash

#title           :install_jenkins_with_tool.sh
#description     :This script will install java8 aws_cli and jenkins
#usage		       :./install_jenkins.sh
#notes           :Install this will install java version 8
#bash_version    :4.4.19(1)-release 
#==============================================================================

script_versioN=0.0 ## Version change is compulsory 

apt-get install apt-transport-https
echo "Running apt update"
apt-get update --yes

#install openjdk8
add-apt-repository ppa:openjdk-r/ppa --yes
apt-get install openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk --yes

# JQ install 
apt-get install jq --yes

curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" &> /dev/null
yum install python -y &> /dev/null
python get-pip.py &> /dev/null
echo "pip is Installed"
# Install AWS CLI using pip
echo "AWS CLI check:- "
pip install awscli &> /dev/null
aws --version
echo "AWS CLI is Installed"
#installing Jenkins
echo "Installing new jenkins..."
echo "--------------------------------------------------"
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update -y
apt-get install jenkins -y
sudo systemctl start jenkins
sudo systemctl status jenkins
