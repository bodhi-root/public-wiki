---
title: Python Storage APIs
---

## Overview

A major re-design occurred in the Azure Python SDKs with version 12 released in December 2019.  This included widespread breaking changes that fundamentally changed how the Python packages and classes operated.  The new version is better in many ways.  It offers a cleaner design with better object-oriented programming.  This results in the code you write also being cleaner and easier to understand.  In some cases you may still need to use the older versions for compatibility reasons, but whenever possible the new versions should be preferred.

Both versions of the SDK have a package named "azure-storage" to interact with storage accounts.  Both versions are documented at the links below:

* Version 12 (new API): https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-python
* Older (legacy) API: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-python-legacy

Also, prior to December of 2019 ADLS gen2 did not support the Blob API at all.  This made it impossible to interact with it using either of these libraries.  Thankfully, this problem has been remedied.  (After I spent days banging my head against the wall trying to figure out what I was doing wrong.)  Eventually, a separate package was created to support ADLS file systems specifically: azure-storage-file-datalake.  This is also documented below.

## New SDK (version 12 and onward)

Microsoft released an updated version of their Python Azure SDK in November 2019.  The new SDK is much better in terms of overall design and ease-of-use.  The SDK was released in preview mode in July and then officially in November.  See this page for an overview of all SDKs:

* https://github.com/Azure/azure-sdk-for-python

As of December 2019, the most recent versions for all SDKs were:

```
azure-identity==1.1.0
azure-storage-blob==12.1.0
azure-storage-queue==12.1.0
azure-storage-file-share==12.0.0
azure-keyvault-keys==4.0.0
azure-keyvault-secrets==4.0.0

azure-cosmos==4.0.0b6
azure-eventhub==5.0.0b6
```

To avoid conflicts with prior packages and other projects, I installed these into a separate Anaconda environment.

### Authentication

Using the new SDK, the following code now works:

```
import os

os.environ["http_proxy"] = "http://user:password@proxy.company.com:1234"
os.environ["https_proxy"] = os.environ["http_proxy"]

# Service Principal Authentication:
from azure.identity import ClientSecretCredential
credentials = ClientSecretCredential(
        tenant_id='<tenant_id>',
        client_id='<client_id>',
        client_secret='<client_secret>')

# Device Code Authentication:
from azure.identity import DeviceCodeCredential
credentials = DeviceCodeCredential(
        client_id='<client_id>',
        tenant_id='<tenant_id>')

from azure.storage.blob import BlobServiceClient
service = BlobServiceClient(account_url="https://mystorage.blob.core.windows.net/", credential=credentials)

containers = service.list_containers()
for container in containers:
    print(container.name)
```

(Notice how much easier the device code authentication is in the SDK versus the old one!)

As of December 2019, this code is working.  Prior to that it returned an error saying "Blob API is not yet supported for hierarchical namespace accounts."

### Data Lake (ADLS) Library

When interacting with ADLS storage, it may be preferable to use the "azure-storage-file-datalake" library which is intended specifically for this purpose.  While you can use the generic "azure-storage-blob" library, the ADLS specific one will use the ADLS APIs and offer expanded functionality only available in ADLS file systems.  The Microsoft SDK reference for this package is available here:

* https://docs.microsoft.com/en-us/python/api/azure-storage-file-datalake/azure.storage.filedatalake?view=azure-python

As of September 2020, the libraries I'm using for this are:

```
azure-identity=1.4.0
azure-storage-file-datalake==12.1.2
```

Assuming you have obtained a credentials object you can then:

```
from azure.storage.filedatalake import DataLakeServiceClient

# DataLakeServiceClient - interacts with the storage account at the highest level
service_client = DataLakeServiceClient(
    account_url="https://mystorage.dfs.core.windows.net",
    credential=creds)

# List files systems:
file_systems = service_client.list_file_systems()
for file_system in file_systems:
    print(file_system.name)

# FileSystemClient - interacts with a specific ADLS file system (aka "container")
file_system_client = service_client.get_file_system_client(file_system="mycontainer")

# List files in a folder:
paths = file_system_client.get_paths("raw/data/v1", recursive=False)
for path in paths:
    print(path.name + " " + path.last_modified)

# Return a DataLakeFileClient to interact with a specific file
file_client = file_system_client.get_file_client("path/to/file.txt")

# Download a file (to a file)
with open("./local/file.txt", "wb") as my_file:
    download = file_client.download_file()
    download.readinto(my_file)

# Download a file to a string of bytes
download = file_client.download_file()
downloaded_bytes = download.readall()

# Upload a file (from string)
data = """some data..."""

file_client = file_client.create_file()
file_client.append_data(data, 0, len(data)) # can have multiple append_data()'s before flush_data()
file_client.flush_data(len(data))

# Upload a file (from a file)
def upload_file(file_path, file_client, chunk_size=1024*1024):
    total_size = 0
    file_client = file_client.create_file()
    with open(file_path, "rb") as fp:
        data = fp.read(chunk_size)
        while data:
            file_client.append_data(data, 0, len(data))
            total_size += len(data)
            data = fp.read(chunk_size)
    file_client.flush_data(total_size)
```

Links to important class documentation:

* [DataLakeServiceClient](https://docs.microsoft.com/en-us/python/api/azure-storage-file-datalake/azure.storage.filedatalake.datalakeserviceclient?view=azure-python) - High-level service to interact with the the storage account as a whole
* [FileSystemClient](https://docs.microsoft.com/en-us/python/api/azure-storage-file-datalake/azure.storage.filedatalake.filesystemclient?view=azure-python) - Interact with a specific ADLS file system (aka "container")
* [DataLakeFileClient](https://docs.microsoft.com/en-us/python/api/azure-storage-file-datalake/azure.storage.filedatalake.datalakefileclient?view=azure-python) - Interact with a specific File
* [DataLakeDirectoryClient](https://docs.microsoft.com/en-us/python/api/azure-storage-file-datalake/azure.storage.filedatalake.datalakedirectoryclient?view=azure-python) - Interact with a specific directory

## Legacy SDK

### Device Code Login

The docs all recommend using a service principal or SAS when authenticating your Python client, but this isn't always an option.  Instead, you can use the "device flow" authentication to authenticate as yourself.  ([This article](https://joonasw.net/view/device-code-flow) provides great detail about what happens behind the scenes with device flow and how it actually works.)  This is the same setup that Azure Storage Explorer uses.  The following Python code gets a credential to interact with the Storage API:

```
import os

os.environ["http_proxy"] = "http://user:password@proxy.company.com:1234"
os.environ["https_proxy"] = os.environ["http_proxy"]

import adal
from msrestazure.azure_active_directory import AADTokenCredentials

def authenticate_device_code():
    """
    Authenticate the end-user using device auth.
    source: https://github.com/Azure-Samples/data-lake-analytics-python-auth-options
            https://github.com/AzureAD/azure-activedirectory-library-for-python
    """
    authority_host_uri = 'https://login.microsoftonline.com'
    tenant = '<tenant_id>'
    authority_uri = authority_host_uri + '/' + tenant
    #resource_uri = 'https://management.core.windows.net/'
    resource_uri = 'https://storage.azure.com/'
    client_id = '04b07795-8ddb-461a-bbee-02f9e1bf7b46'

    context = adal.AuthenticationContext(authority_uri, api_version=None)
    code = context.acquire_user_code(resource_uri, client_id)
    print(code['message'])
    mgmt_token = context.acquire_token_with_device_code(resource_uri, code, client_id)
    credentials = AADTokenCredentials(mgmt_token, client_id)

    return credentials

credentials = authenticate_device_code()
```

The "client_id" in this case ("04b07795-8ddb-461a-bbee-02f9e1bf7b46") is said to be a "well-known" client ID.  It appears to be some existing Microsoft application that is already registered in Azure somewhere.  Interestingly, the application doesn't have to be registered in the same tenant as that for which we are requesting storage access.  The docs do note that you should register your own application and use its client ID in production apps rather than the one above.

### BlockBlobService

The BlockBlobService is the primary object for interacting with a blob storage account.  The code below shows how to create one and then list the containers in the account.  There are multiple ways to authenticate with the service.  A few common ones are demonstrated.

```
from azure.storage.blob import BlockBlobService

# If you have the storage key:
service = BlockBlobService(STORAGE_ACCOUNT, account_key=STORAGE_KEY)

# If you have a device code credentials (stored as 'credentials')
# service = BlockBlobService(STORAGE_ACCOUNT, token_credential = credentials)

# If you are using a service principal:
#from azure.common.credentials import ServicePrincipalCredentials
#from azure.storage.common import TokenCredential
#
#credentials = ServicePrincipalCredentials(
#    client_id = '<id>',
#    secret = '<secret>',
#    tenant = '<tenant>',
#    resource = "https://storage.azure.com/"
#)
#tokenCre = TokenCredential(credentials.token["access_token"])
#service = BlockBlobService(account_name=STORAGE_ACCOUNT, token_credential=tokenCre)

containers = service.list_containers()
for container in containers:
    print(container.name)

blobs = list_blobs(self.container, prefix = prefix, delimiter="/")
for blob in blobs:
    print(blob.name)
```

Originally this failed with an error saying that "Blob API is not yet supported for hierarchical namespace accounts."  Searching the forums, I found that despite Microsoft's promises that ADLS gen 2 would support the Blob API, this was not the case when it was released.  Happily, they have finally fixed this problem as of December 2019.  The above code now works without error.
