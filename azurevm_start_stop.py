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
    isOperationCompletedSuccessfully = 0
    
    try:
        if operation == 'stop':
            isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, requestHeader)
            if isSucceeded == 2:
                print ("VM is already in stopped state", vmName)
                isOperationCompletedSuccessfully = 1
            else: 
                print('Shutting Down This ', vmName, 'VM')
                requesturl = "https://management.azure.com/subscriptions/" + subscriptionId + "/resourceGroups/"+ resourceGroupName +"/providers/Microsoft.Compute/virtualMachines/"+ vmName +"/powerOff?api-version=2019-03-01"
                status = requests.post(url=requesturl, headers=requestHeader)
                print ("Status Code: ", status.status_code)
                if status.status_code == 200 or status.status_code == 202:
                    isOperationCompletedSuccessfully = 1
        elif operation == 'start':
            isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, requestHeader)
            if isSucceeded == 1:
                print ("VM is already in stopped state", vmName)
                isOperationCompletedSuccessfully = 1
            else:
                print('Starting VM ', vmName)
                requesturl = "https://management.azure.com/subscriptions/" + subscriptionId + "/resourceGroups/"+ resourceGroupName +"/providers/Microsoft.Compute/virtualMachines/"+ vmName +"/start?api-version=2019-03-01"
                status = requests.post(url=requesturl, headers=requestHeader)
                print ("Status Code: ", status.status_code)
                if status.status_code == 200 or status.status_code == 202:
                    isOperationCompletedSuccessfully = 1
        else:
            print ("Invalid Operation")
            exit()
    except Exception as e:
        print("error getting in start/stop VM opration, GETALL %s due to exception %s", requesturl, e)
    finally:
        return isOperationCompletedSuccessfully 

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

def verifyStatus(subscriptionId, resourceGroupName, vmName, requestHeader):
    requesturl = "https://management.azure.com/subscriptions/" + subscriptionId + "/resourceGroups/" + resourceGroupName +"/providers/Microsoft.Compute/virtualMachines/" + vmName + "/instanceView?api-version=2019-03-01"
    isSucceeded = 0
    status = {}
    status = requests.get(url=requesturl, headers=requestHeader).content
    response = json.loads(status)
    # print ("Curent Status: ", response['statuses'][1]['code'])
    print ("Curent Status: ",response['statuses'][1]['displayStatus'])
    # print(response['properties']['provisioningState'])
    if (response['statuses'][1]['displayStatus']) == 'VM running':
        isSucceeded = 1
        print ("Operation Completed Successfully")
        return isSucceeded
    elif (response['statuses'][1]['displayStatus']) == 'VM stopped':
        isSucceeded = 2
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
        # verifyStatus(subscriptionId, resourceGroupName, vmName, requestHeader)
        vmStatus = startStopOperation(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
        if vmStatus == 1:
            print ("Running", operation, "operation on ", vmName)
            isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, requestHeader)
            count = 0
            while count <= 6:
                if isSucceeded == 1:
                    print ("Vm is Up & Running :", vmName)
                    break
                elif isSucceeded == 2:
                    print ("Vm is in stopped state :", vmName)
                    break     
                else:
                    print ("Waiting to complete the operation..")
                    count += 1
                    time.sleep(10)
                    isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, requestHeader)
        else: 
            print ("Failed while ", operation, "operation on ", vmName)
    else:
        nodes = json.dumps(jsonConfigData[option])
        for item in json.loads(nodes):
            vmName = item['vmname']
            resourceGroupName =  item['resourceGroupName']
            print (vmName, resourceGroupName)
            # verifyStatus(subscriptionId, resourceGroupName, vmName, requestHeader)
            vmStatus = startStopOperation(subscriptionId, resourceGroupName, vmName, operation, requestHeader)
            if vmStatus == 1:
                print ("Running ", operation, "operation on ", vmName)
                isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, requestHeader)
                count = 0
                while count <= 6:
                    if isSucceeded == 1:
                        print ("Vm is Up & Running :", vmName)
                        break
                    elif isSucceeded == 2:
                        print ("Vm is in stopped state :", vmName)
                        break 
                    else:
                        print ("Waiting to complete the operation..")
                        count += 1
                        time.sleep(20)
                        isSucceeded = verifyStatus(subscriptionId, resourceGroupName, vmName, requestHeader)
            else: 
                print ("Failed while ", operation, "operation on ", vmName)

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
