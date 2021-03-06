#Usage:
#./az-cli-vmstartstop.sh <start/stop/deallocate/restart>
#!/bin/bash
action=$1
az login --service-principal -u <CLIENT_ID> -p <CLIENT_SECRET> --tenant <TENANT_ID>
az account set --subscription <SUB_ID>
list=$(az vm list -g <resource_group_name> --query [].id --output tsv | awk -F "/" '{print $NF}' | sed 's/"//g')
for vmname in $list
do
    echo ${vmname}
    az vm ${action} --resource-group <resource_group_name> --name ${vmname}
done
