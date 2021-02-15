---
title: Azure Blob Storage
---

## Overview

Azure blob storage is used to store data in an inexpensive way that detaches it from compute resources.  This is one of the biggest innovations in the cloud: separating compute from storage and only paying for compute when needed.  Data can be stored for as little as $0.001 / GB / month, but these prices increase if you want to pay for better redundancy or availability.  Azure also offers files shares that work more like a network drive, but at $0.058 / GB / month these are over 50 time as expensive as blob storage.  If you want cheap storage: blob storage is the way to go.

## Key Concepts

Blobs are stored in containers.  Containers are like buckets in GCP.  Permissions are most commonly managed at the container level, but some types of blob storage (such as ADLS v2) allow you to manage permissions on subfolders in the hierarchy.  Blobs are accessible via URLs that take the form:

* https://{storage_account}.blob.core.windows.net/{container}/{blob_path}

The storage account must be globally unique.  Once you have this you are free to name the containers as you'd like.

## Redundancy

Azure offers the following types of redundancy:

* LRS (Locally-redundant storage) - 3 copies of your data is stored in the same data center
* ZRS (Zone-redundant storage) - data copied to another data center in the same availability zone
* GRS (Geo-redundant storage) - data copied to another data center in a separate zone (and at least 300 miles away).  6 copies of your data (3 in one data center and 3 in the other)
* RA-GRS (Read access Geo-redundant storage) - GRS but with the ability to read from the second copy of your data instead of just using it for Disaster Recovery

The types above are in order of increasing cost.  ZRS is only slightly more than LRS.  GRS is about 3x the cost of LRS and RA-GRS is about 4x the cost.

## Browsing & Transferring Data

### Azure Portal

You can browse your Storage contents directly in the portal if you have the ability to read from this resource and also to list containers and access keys for this resource.  Then you can browse containers, click down into their various folders, and even view and edit files directly in the portal.  Unfortunately, the ability to list access keys is usually restricted - especially if you do not own the storage account.

### Storage Explorer

> NOTE: Storage explorer does not work on my company's network without installing a third-party tool to intercept messages and re-write authentication headers.  An application named Fiddler is recommended for this, but in my experience it is too much of a pain to use.  I end up just using R or Python code.

Storage Explorer is the easiest way to work with blob storage.  It is a stand-alone GUI that can be downloaded here:

https://azure.microsoft.com/en-us/features/storage-explorer/

This lets you attach to multiple Azure accounts, browse files, and transfer to/from cloud storage.  It uses AzCopy behind the scenes for bulk copies, and my experience with this was much better than with AzCopy command line.

### CloudBerry Explorer for Azure

CloudBerry makes a free tool to interact with storage accounts from various cloud providers (including Azure).  Their Azure offering can be downloaded from their website.  You will need to activate the free version of the software.  This may require you to hop off your corporate network. (Unless you can find a way to enter the activation token you received when downloading the software... I couldn't.)  Once in, you will need to go to "Tools > Options" and configure your proxy information.

You will then need to setup a connection to your storage account.  You can use "blob storage" (even if it is ADLS).  You will need a "shared key" to access the storage account this way.  This refers to the high-level access keys for your storage account.  (This is not a "shared access key" or "SAS".)  This is not typically something that the admin teams will want to give you though.

Once configured you can browse files on the remote storage account and upload/download files from/to your computer.  This is enabled even in the free version of the tool.

### AzCopy

AzCopy is a command line tool for transferring large amounts of files to/from the cloud.  I actually had a hard time getting this to work and instead opted to use Storage Explorer.  But if you want to try AzCopy there are instructions here:

* https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10
* https://docs.microsoft.com/bs-latn-ba/azure/storage/common/storage-use-azcopy-configure
* https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-migrate-on-premises-data?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&tabs=windows

You can download a pre-built EXE from the first link.

You will then need to set proxy information and login.  This can be done in a Windows CMD prompt with:

```
set https_proxy=http://user:pass@proxy.company.com:1234

azcopy login --tenant-id=12345678-1234-1234-1234-1234567890af
```

The tenant ID should be set to the location of the storage account you are trying to access.  This command will ask you to navigate to a web page and perform a "device login" procedure.

Once authenticated, you should be able to run commands like:

```
azcopy list https://<storage-account-name>.<blob or dfs>.core.windows.net/<container-name>

azcopy copy "<local-folder-path>" "https://<storage-account-name>.<blob or dfs>.core.windows.net/<container-name>" --recursive=true
```

When I ran this I got an error saying I was not authorized to perform the given operation - even though I am a contributor of the resource group containing the storage account I wanted to use.  I suspect this is related to some issues we saw where rights need to be assigned on the storage account itself and need to explicitly be set to "Storage Blob Data Contributor/Reader/Owner".

I was able to get the list and copy commands working when I used a SAS token.  That's just a bit annoying though since it needs to be appended to all of the Azure URLs.

[This link](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-migrate-on-premises-data?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&tabs=windows) also has a description of an "azcopy sync" command that will look for changes made to your local copy of files and push those changes back to blob storage.  That could be useful.

#### AzCopy on Unix

If you want to install AzCopy on Unix, the Dockerfile below might be instructive.  The Dockerfile has to point at a specific version of AzCopy and use a static web link to download it.  You don't need to do this if you just click the link to download the most recent version from Microsoft.  The interesting part of the script below is where it copies the "azcopy" executable to "/usr/local/bin" and changes permissions on it.  This is a quick an easy way to install it for all users and make it available on the system path.

```
FROM debian:stretch-slim

ENV RELEASE_STAMP=20191212
ENV RELEASE_VERSION=10.3.3

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         ca-certificates \
         curl \
    && rm -rf /var/lib/apt/lists/*

RUN set -ex \
    && curl -L -o azcopy.tar.gz https://azcopyvnext.azureedge.net/release${RELEASE_STAMP}/azcopy_linux_amd64_${RELEASE_VERSION}.tar.gz \
    && tar -xzf azcopy.tar.gz && rm -f azcopy.tar.gz \
    && cp ./azcopy_linux_amd64_*/azcopy /usr/local/bin/. \
    && chmod +x /usr/local/bin/azcopy \
    && rm -rf azcopy_linux_amd64_*
```

## R

This section grew a bit too long.  For details on how to interact with Azure Storage using R, visit the child page below:

* [R Storage API (AzureStor)](blob-storage/r-storage-apis)

## Python

This section also grew a bit long.  For details on how to use the various Python packages for interacting with storage accounts see:

* [Python Storage APIs](blob-storage/r-storage-apis)

## Static Websites

Blob storage can be used to easily host static websites in Azure.  Details on how to do this can be found here:

* https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website-how-to?tabs=azure-portal

Some of the key points:

* Use normal blob storage.  Make sure you do not have ADLS/hierarchical folders enabled.
* You can use the "static websites" link on your storage account in the Azure portal
  * This will give you the URL of your website (which is formed from your storage account name)
  * You can also specify default pages such as "index.html" or an error page
* A container will be created named "$web"
