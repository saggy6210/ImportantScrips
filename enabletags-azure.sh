#!/bin/bash
az login --service-principal -u <CLIENT_ID> -p <CLIENT_SECRET> --tenant <TENANT_ID>
az account set --subscription <SUBSCRIPTION_ID>
list=$(az resource list -g chk8sclustersthree --query [].id --output tsv)
for i in $list
do
	echo $i
	az resource tag --tags 'created_by=sagar@abc.com' 'enddate=31-12-2020' 'team=qa' 'purpose=Regression Testing' --id $i
done
