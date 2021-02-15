---
title: Azure Containers (Docker)
---

## Azure Container Registries

Azure allows you to host your own docker repositories using Azure Container Registries.  Once created, these let you push images to them, giving them unique names and tagging them as new versions are published.  Microsoft has a list of [best practices for ACR](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-best-practices).  Some of the more important ones are:

1. Put the repo geographically close to the region where you intend to run these containers (minimizes cost and maximizes speed)
2. Since the repo is likely to be shared, build it in a shared resource group (example: "rg-mycompany-common")
3. Use repository namespaces to isolate images from different lines of businesses

This last one is a bit mis-leading.  While you can publish images to "mybusinessline/myimage" there is no security to make sure that only a certain group of people have publishing rights for this namespace.  (I found a GitHub ticket placed with Microsoft that confirmed this is the case.)

Some tasks in ACR require you to define an admin login.  This creates a static user name and password that can access your registry.  Enabling this allows you to run containers from the Azure Portal (using ACI and specifying a few parameters).  It also makes it easier to use ACI from the Azure CLI (see example later on).  Alternatives including using service principles or storing a user name and password in an Azure Key Vault.

## Automated Build Pipelines

Azure DevOps pipelines let you easily build and publish docker images when code is committed to your repository.  The pipeline file below triggers of commits to "master" and does just that:

___azure-pipelines.yml___

```
# Builds a docker image and pushes it to the registry
trigger:
- master

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: Docker@2
  inputs:
    containerRegistry: dsp-acr
    repository: 'dsp-r'
    command: 'buildAndPush'
    Dockerfile: '**/Dockerfile'
```

The image will be pushed and named "dsp-r".  It will be automatically tagged with the build number so you know exactly what build created the image.

## Azure Container Instances (ACI)

Azure Container Instances (ACI) let you run containers in a very simple way.  In fact, these are used from the Azure Portal itself when you click on an image and select "run".  (NOTE: This option will be grayed out unless you have enabled an admin account on your registry.)

### Running from the CLI

There is also a way to do this from the command line using code such as that below:

```
# delete container group (if exists)
az container delete --yes \
  --resource-group rg-mycompany-aci \
  --name aci-test-1

# create new container group:
az container create \
  --resource-group rg-mycompany-aci \
  --name aci-test-1 \
  --image mycompany.azurecr.io/samples/docker-r:1 \
  --registry-login-server mycompany.azurecr.io \
  --registry-username mycompany \
  --registry-password <password> \
  --command-line "Rscript src/print_file.R ohlc/KR.csv" \
  --environment-variables \
    STORAGE_URL=https://mycompany.blob.core.windows.net \
    STORAGE_CONTAINER=stockdata \
  --secure-environment-variables \
    STORAGE_KEY=<key> \
  --restart-policy never

# view logs
az container logs \
  --resource-group rg-mycompany-aci \
  --name aci-test-1
```

The "az container create" command can be a little verbose.  The example above specifies the image to run and provides login information for the registry (using the admin account).  It also passes in environmental variables and secures one of these so that it won't be printed out to the user in the logs.  The container runs inside an ACI container group.  This can run multiple images, but in this case we are only running one.  You can navigate to the container group in the Azure portal and view the status and logs of the containers.  However, this can be a bit tricky if the containers are set to run one and never restart.  You pretty much have to be watching the log as it runs or else the log file will be lost when the container is terminated.

The following resources were helpful in building the above commands:

* https://docs.microsoft.com/en-us/azure/container-instances/container-instances-quickstart
* https://docs.microsoft.com/en-us/cli/azure/container?view=azure-cli-latest#az-container-create

There is also a good site describing how to use Key Vault for your docker credentials if you want to avoid using the admin login:

https://docs.microsoft.com/en-us/azure/container-instances/container-instances-using-azure-container-registry

## Running from Python

TODO:

Microsoft has some good sample code here: https://github.com/Azure-Samples/aci-docs-sample-python/blob/master/src/aci_docs_sample.py

## Azure Kubernetes Service (AKS)

Azure Kubernetes Service (AKS) is another way to run docker containers in Azure.  This is often referred to as a more production-grade way to run your containers, but I have not used it personally.

## Azure Batch

Azure Batch is used to run large, parallel jobs across a cluster of computers.  This also supports running docker images.
