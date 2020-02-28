#!/usr/bin/python
import json, requests, argparse, time

__version__ = '1.0.0'
__description__ = "This script is to start/stop the virtual machine on Azure"
__Author__="Sagar Chavan <SChavan@cloudhedge.io>"

# class AzureInfra:
parser = argparse.ArgumentParser()
parser.add_argument('--sanityfile', default="Unknown")
parser.add_argument('--option', default="Unknown") 
parser.add_argument('--operation', default="Unknown") 
parser.add_argument('--clientid', default="Unknown")
parser.add_argument('--clientsecret', default="Unknown")
parser.add_argument('--subscriptionid', default="Unknown")
parser.add_argument('--tenantid', default="Unknown")
args = parser.parse_args()

def startStopOperation(subscriptionId, resourceGroupName, vmName, operation, requestHeader):
    vmStatus = ""
    try:
        if operation == 'stop':
            print('Shutting Down ', vmName, 'VM')
            requesturl = "https://management.azure.com/subscriptions/" + subscriptionId + "/resourceGroups/"+ resourceGroupName +"/providers/Microsoft.Compute/virtualMachines/"+ vmName +"/powerOff?api-version=2019-03-01"
            status = requests.post(url=requesturl, headers=requestHeader)
            if status.status_code == 200 or status.status_code == 202:
                vmStatus = "stopping"
        elif operation == 'start':
            print("Starting ", vmName, " VM")
            requesturl = "https://management.azure.com/subscriptions/" + subscriptionId + "/resourceGroups/"+ resourceGroupName +"/providers/Microsoft.Compute/virtualMachines/"+ vmName +"/start?api-version=2019-03-01"
            status = requests.post(url=requesturl, headers=requestHeader)
            if status.status_code == 200 or status.status_code == 202:
                vmStatus = "starting"
        else:
            print ("Invalid Operation")
            exit()
    except Exception as e:
        print("error getting in start/stop VM opration, GETALL %s due to exception %s", requesturl, e)
    finally:
        return vmStatus 

def getLoginData(clientId, clientSecret, tenantId): 
    URI = "https://login.microsoftonline.com/"+ tenantId +"/oauth2/token?api-version=1.0"
    data = {
        'grant_type': 'client_credentials',
        'resource': 'https://management.core.windows.net/',
        'client_id': clientId,
        'client_secret': clientSecret
    }
    accesstokendata = requests.post(URI, data=data).content
    accesstoken = (json.loads(accesstokendata).get('access_token'))
    headers = {'Authorization': 'Bearer ' + str(accesstoken)}
    return headers

def verifyStatus(subscriptionId, resourceGroupName, vmName, operation, requestHeader):
    requesturl = "https://management.azure.com/subscriptions/" + subscriptionId + "/resourceGroups/" + resourceGroupName +"/providers/Microsoft.Compute/virtualMachines/" + vmName + "/instanceView?api-version=2019-03-01"
    isSucceeded = 0
    status = {}
    status = requests.get(url=requesturl, headers=requestHeader).content
    response = json.loads(status)
    print ("Curent Status is: ",response['statuses'][1]['displayStatus']," for VM : ", vmName)
    if operation == "start":
        if (response['statuses'][1]['displayStatus']) == 'VM running':
            isSucceeded = 1
            return isSucceeded
        else:
            isSucceeded = 0
            return isSucceeded    
    else:
        if (response['statuses'][1]['displayStatus']) == 'VM stopped':
            isSucceeded = 1
            return isSucceeded   
        else:
            isSucceeded = 0
            return isSucceeded  



def sanityProvision(sanityfile, option, operation, subscriptionId, requestHeader):
    configFile = sanityfile
    jsonConfigData = {}
    vmData = {}
    configReadStatus = 0
    configJsonFile = None
    try:
        with open(configFile) as configJsonFile:
            jsonConfigData = json.load(configJsonFile)
            configReadStatus = 1
    except Exception as e:
        print("Unable to read the json file %s due an exception %s", configFile, e)
    finally:
       configJsonFile.close()
    if configReadStatus == 0:
        print("Error reading the config file %s .. stopping the sanity", configFile)
    if option == 'appliance':
        vmData = jsonConfigData[option]
        vmName = vmData['vmname']
        resourceGroupName = vmData ['resourceGroupName']
        print ("Running ", operation, "operation on ", vmName)
        if operation == "start":
            isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
            if isSucceeded == 1:
                print ("Vm ", vmName, " is Up & Running " )
                print ("----------------------------------")
                print()
            else:
                startStopOperation(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
                while True: 
                    isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
                    if isSucceeded == 1:
                        print ("Vm ", vmName, " is Up & Running " )
                        print ("----------------------------------")
                        print()
                        break
                    else: 
                        print("Waiting to UP and running the vm ", vmName)
                        time.sleep(10)
        else:
            isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
            if isSucceeded == 1:
                print ("Vm ", vmName, " is in stopped state " )
                print ("----------------------------------")
                print()
            else:
                startStopOperation(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
                while True: 
                    isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
                    if isSucceeded == 1:
                        print ("Vm ", vmName, " is in stopped state " )
                        print ("----------------------------------")
                        print()
                        break
                    else: 
                        print ("Waiting to stopped Vm ", vmName )
                        time.sleep(10)
    else:
        nodes = json.dumps(jsonConfigData[option])
        for item in json.loads(nodes):
            vmName = item['vmname']
            resourceGroupName =  item['resourceGroupName']
            print ("Running ", operation, "operation on ", vmName)
            if operation == "start":
                isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
                if isSucceeded == 1:
                    print ("Vm ", vmName, " is Up & Running " )
                    print ("----------------------------------")
                    print()
                else:
                    startStopOperation(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
                    while True: 
                        isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
                        if isSucceeded == 1:
                            print ("Vm ", vmName, " is Up & Running " )
                            print ("----------------------------------")
                            print()
                            break
                        else: 
                            print("Waiting to UP and running the vm ", vmName)
                            time.sleep(10)
            else:
                isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
                if isSucceeded == 1:
                    print ("Vm ", vmName, " is in stopped state " )
                    print ("----------------------------------")
                    print()
                else:
                    startStopOperation(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
                    while True: 
                        isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
                        if isSucceeded == 1:
                            print ("Vm ", vmName, " is in stopped state " )
                            print ("----------------------------------")
                            print()
                            break
                        else: 
                            print ("Waiting to stopped Vm ", vmName )
                            time.sleep(10)

if __name__ == "__main__": 
    sanityfile = args.sanityfile
    option = args.option
    operation = args.operation
    clientid = args.clientid
    clientsecret = args.clientsecret
    subscriptionid = args.subscriptionid
    tenantid = args.tenantid
    requestHeader = getLoginData(clientid, clientsecret, tenantid)
    sanityProvision(sanityfile, option, operation, subscriptionid, requestHeader)

