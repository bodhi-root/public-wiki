---
title: R Storage API
---

## Overview

The AzureStor package in R provides an API for interacting with Azure storage accounts.  Surprisingly, we have found that this API even has features the Python API is slow to add (such as access to ADLS, which was available 9 months earlier in the R API than in Python).  The library is developed by Revolution Analytics.  More information is available here:

* https://blog.revolutionanalytics.com/2018/12/azurestor.html

## Authenticating

One of the trickier parts when first starting with AzureStor is authentication.  There are several methods of authenticating, including:

* Key-based - Providing one of the 2 "Access Keys" for the storage account.  This is the easiest but also the least secure method of authentication since you are essentially handing out the master keys to your storage account.
* SAS Token - A Shared Access Signature (SAS) Token is a little more secure than Key-Based.  The SAS tokens can be given restricted permissions (such as as read-only) and can be set to expire
* Service Principal - A service principal can be used.  A service principal is identified by 3 pieces of information: the tenant_id, client_id, and client_secret.
* Device Code - This enables your code to run with the permissions of a given user.  Using this type of authentication will require the user to login to Azure using a special URL and code to approve the request.  After this, the program can execute as if it were that user.

The code for each of these methods is slightly different.  Examples of all of these are given below:

```
# Proxy setup is required in order to interact with the Azure REST API:

Sys.setenv(http_proxy="http://proxy.company.com:1234",
           http_proxy_user="user:password")
Sys.setenv(https_proxy=Sys.getenv("http_proxy"),
           https_proxy_user=Sys.getenv("http_proxy_user"))

library(AzureAuth)
library(AzureStor)

# Key-Based Authentication:
endpoint <- storage_endpoint("https://myaccount.dfs.core.windows.net", key="...")

# SAS Authentication:
endpoint <- storage_endpoint("https://myaccount.dfs.core.windows.net", sas="?sv=...")

# Service Principal:
token <- get_azure_token("https://storage.azure.com/",
                  tenant="<tenant_id>",
                  app="<client_id>",
                  password="<client_secret>",
                  auth_type="client_credentials")

endpoint <- storage_endpoint("https://myaccount.dfs.core.windows.net", token=token)

# Device Code Authentication:
token <- get_azure_token("https://storage.azure.com/",
                    tenant="<tenant_id>",  # This should be the tenant_id that contains the storage account
                    app="04b07795-8ddb-461a-bbee-02f9e1bf7b46",  # Use this ID (according to Microsoft, it is a "well-known" app that works in all tenants)
                    auth_type="device_code",
                    use_cache = use_cache)

endpoint <- storage_endpoint("https://myaccount.dfs.core.windows.net", token=token)
```

The first three of these are pretty straight-forward.  The Device Code probably require some explanation.  When you are using device code authentication you are allowing an application to run commands on a user's behalf.  Running the "get_azure_token" command above will print out a line of text asking the user to navigate to a URL in their web browser and enter a special code.  The user will then login to Azure as themselves.  The program will actually ping Azure repeatedly to see if this code has been entered.  Once entered, Azure will provide back a token that will allow your program to authenticate with your permissions.

As indicated in the code, the "tenant" should always be the tenant for which you are requesting access.  The "app" or "client_id" is the ID of the application that is going to be executing the commands.  Ideally, this should be an application that you have registered in your own Azure AD - in which case, you should use the client ID pertaining to that application.  However, for quick testing you can use the client ID shown in the sample code.  Microsoft says this is a "well-known" application that is available in all tenants.  Their documentation says its permissible to use this client ID for testing.

When using Device Code authentication you can also cache credentials (with the "use_cache" parameter).  This is a nice feature to keep your user from having to authenticate repeatedly.  Also, each token has an expiration date/time, but AzureStor is smart enough to refresh the token automatically if needed.  It will print out a message to STDERR indicating that it is doing this.

## Basic Commands

Assuming you have authenticated and connected to a storage account endpoint as described in the previous section, you are now ready to use some of the commands below:

```
# list storage containers:
list_storage_containers(endpoint)

# list files:
container <- storage_container(endpoint, "container_name")
list_storage_files(container)
list_storage_files(container, dir="path/to/dir")

# upload and download files:
SRC_DIR <- "C:/path/to/data"

storage_upload(container, src=file.path(SRC_DIR, "file1.csv"), dest="path/to/file1.csv")
storage_download(container, src="data/file1.csv", dest="file1.csv")

upload_adls_file(container, src=file.path(SRC_DIR, "file2.csv"), dest="path/to/file2.csv")
download_adls_file(container, src="data/file2.csv", dest="file2.csv")

# delete files
delete_storage_file(container, "data/file1.csv", confirm=F)
```

Notice that there are two forms of the upload and download commands:

* storage_upload
* upload_adls_file

"storage_upload" is probably the better one to use.  This is a generic method that will dispatch requests to different method for each type of storage.  In the example above we are interacting with ADLS storage.  The specific upload command for this storage type is "upload_adls_file()".  However, "storage_upload()" is smart enough to look at the URL for the storage account, infer that this is ADLS storage, and dispatch you to that method automatically.  The generic method will work for ADLS, Blob, and other storage types.  It keeps you from having to worry about the different underlying commands.
