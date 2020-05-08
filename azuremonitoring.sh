#!/bin/sh

az login --service-principal -u <Client Key> -p <Client Secret> --tenant <Tenant ID>

az account set --subscription <Service Principal>
#az vm list-ip-addresses | jq ".[] |.virtualMachine |.network |.publicIpAddresses[] |.id" | awk -F "/" '{print $NF}' | sed 's/"//g' |wc -l
az group list | jq ".[] |.id" | awk -F "/" '{print $NF}' | sed 's/"//g' > rg.list
while IFS= read -r RG
do
	#az vm list | jq ".[] |.id" | awk -F "/" '{print $NF}' | sed 's/"//g'
	echo "Resource Group : ${RG}"
	az vm list -g "${RG}" | jq ".[] |.id" | awk -F "/" '{print $NF}' | sed 's/"//g' | wc -l
	az vm list -g "${RG}" | jq ".[] |.id" | awk -F "/" '{print $NF}' | sed 's/"//g'
	az vm list-ip-addresses -g "${RG}" | jq ".[] |.virtualMachine |.network |.publicIpAddresses[] |.id" | awk -F "/" '{print $NF}' | sed 's/"//g' | wc -l
	az vm list-ip-addresses -g "${RG}" | jq ".[] |.virtualMachine |.network |.publicIpAddresses[] |.id" | awk -F "/" '{print $NF}' | sed 's/"//g' 
	
done < /home/sagarc/CH-HOME/azure/rg.list
