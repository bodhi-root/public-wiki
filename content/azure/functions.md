---
title: Azure Functions
---

## Overview

Azure Functions are ways to run code on-demand in a "serverless" way.  This means that your code does not take up any compute resources when it is not executed.  Instead, your code will be triggered in response to some event and only run then.  Different types of triggers can be setup, including:

* HTTP endpoint invocation
* Messages received in Azure Queues

The actual code that runs can be developed in several different languages (including C#, Java, JavaScript, PowerShell, and Python).  Python looks to be a popular option for many companies.

## Setting Up Your Development Environment

When using Python, you cannot edit functions in the Azure Portal. (Not that you'd want to anyway.  This is a horrible idea!).  Instead, you will need to develop locally and push your functions to Azure, or - better yet - setup a CI/CD pipeline that will trigger off code commits and deploy automatically.  (We'll get to this later...)

So, you need to setup a local development environment.  Unfortunately, this can be a huge pain in the butt.  According to their quickstart tutorial you need to do the following:

* Install Python [3.6.8](https://www.python.org/downloads/). This version of Python is verified with Functions. 3.7 and later versions are not yet supported.
* Install [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local#v2) version 2.7.1575 or a later version.
* Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) version 2.x or a later version.

Then you have setup a Python virtual environment to make sure you have the right version of Python and the applicable dependencies for your environment.  I spent an hour or so trying to get this setup, and it was a pain.

Thankfully, there's a better option that produces a development environment that is not only isolated from the rest of your machine but also easy to reproduce on any other developer's machine.  The approach involves setting up your development environment in Docker and then connecting to this environment in VSCode.  The approach is described here:

* https://www.freecodecamp.org/news/put-your-dev-env-in-github/

When your project is open in VSCode you can click the "Remote-Containers" extension icon and then "Add Development Container Configuration Files."  You can then use a pre-defined configuration for "Azure Functions & Python 3."  This creates a folder named ".devcontainer" with two files:

* [devcontainer.json](assets/functions/devcontainer.json)
* [Dockerfile](assets/functions/Dockerfile)

Each of these is pretty well-documented with regard to what it does.  You then can open your project in this environment and will have everything you need already installed.

### Manual Docker Setup

While this solution does work from within a corporate proxy, it has failed on me when connecting to that company's network using VPN.  It will work if you jump off VPN, but then you might not be able to connect to all of the Azure resources you need.

> UPDATE: I think the best solution is to manually build your docker image and run the container yourself.  This gives you complete control over the docker build and run steps and lets you inject all the proxy information you need to get these working right.  You don't even need the VSCode remote tools to do this.  The trick is to find the commands that VSCode is running for you:

```
docker build ^
  -f c:\path\to\project\.devcontainer\Dockerfile ^
  -t vsc-project-d1111e128c410535aa106a9520526596 ^
  c:\path\to\project\.devcontainer

docker run ^
  -a STDOUT -a STDERR ^
  -p 127.0.0.1:7071:7071 ^
  --mount type=bind,source=c:\path\to\project,target=/workspaces/project,consistency=consistent -l vsch.quality=stable ^
  -l vsch.remote.devPort=0 ^
  -l vsch.local.folder=c:\path\to\project ^
  -v /var/run/docker.sock:/var/run/docker.sock ^
  --entrypoint /bin/sh ^
  vsc-project-d1111e128c410535aa106a9520526596 ^
  -c echo Container started ;  while sleep 1; do :; done
```

Then you can write your own build script:

___build.bat___

```
set http_proxy=http://user:pass@proxy.domain.com:1234

docker build ^
  --build-arg http_proxy=%http_proxy% ^
  --build-arg https_proxy=%http_proxy% ^
  -t myproject-dev:1.0 .
```

and your own run script:

___run.bat___

```
docker run --rm -it ^
  -p 127.0.0.1:7071:7071 ^
  --env-file devcontainer.env ^
  --entrypoint /bin/bash ^
  --mount "type=bind,source=c:\path\to\myproject,target=/workspaces/myproject,consistency=consistent" ^
  myproject-dev:1.0
```

This run script references the "devcontainer.env" file containing environmental variables to set at runtime.  If you're running this behind a corporate proxy, you will want to have the following:

___devcontainer.env___

```
http_proxy=http://user:pass@proxy.company.com:1234
https_proxy=http://user:pass@proxy.company.com:1234
no_proxy=localhost,127.0.0.1,.company.com
```

> NOTE: If you don't set "no_proxy" you will run into errors when you run "func host start" since it will try to communicate through the proxy and fail.

The docker run script starts the container and runs "/bin/bash", connecting to your terminal.  This will leave a window open that will allow you to explore the running container and to run commands such as "func host start".  You can edit your project files locally in your favorite IDE and these will automatically be updated in the container as well.  Also, any changes you make to your project files in the container will be reflected on your local machine.

Whew...  Now let's actually get coding!

___Actually... one last caveat: the setup above failed on VPN.  The docker run command would not let me mount my local drive, instead complaining that a firewall was blocking connectivity from my machine to my own machine.  This only seems to happen on VPN for some reason.  Since I can't edit the firewall rules, the only thing to get this working from home was to hop off the VPN.  But working from home off of VPN makes everything easier anyway.___

## Getting Started

The first thing you will do once you are in your development environment is initialize your Azure function folder.  To do this just run the following from inside the function folder:

```
func init
```

It will prompt you for the language you are using.  Select "python".  This will create some files and folders needed by your function.

You can then create a new function with:

```
func new
```

This will prompt you for the trigger type for your function as well as for your function's name.

Once you have done your coding you can run your function with:

```
func start
```

When you are ready to deploy your code you can do this manually with:

```
az login -t <tenantid>
func azure functionapp publish <functionapp>
```

Or you can setup a CI/CD pipeline to automatically build and deploy your function each time new code is checked into git.  For details on this see:

* [Azure DevOps Pipelines](devops-pipelines)

## Monitoring Functions (and Logging)

You can view app execution in the portal by going to the function and clicking "Monitor" beneath it. Anything you log with "logging.info()" will appear in the in the right side-panel when you click on the function.  This is very helpful for debugging.

The one caveat with all this: there is a lag and function invocations can take as much as 5 minutes to show up on this screen.  This was driving me nuts.  I was constantly clicking refresh and eventually a warning came up telling me about the lag.  Then I noticed that yes, my function was running immediately as expected and updating the database immediately.  It just wasn't letting me see that in the portal until several minutes after the function had finished.  This is a huge pain.  The monitor is nice.  The lag just sucks.

These same messages are also logged to App Insights, but I haven't found this to be as useful.  App Insights has the same 5-minute lag.  I am usually trying to debug a specific function and it's easier to go straight to that function in the portal and view all executions.

## Triggers

### Blob Storage

You can setup your function to be triggered when a new file is created in blob storage.  There are actually two ways to do this:

1. Using the built-in "blobTrigger" in Azure Functions
2. Using an "eventGridTrigger" and subscribing to the EventGrid attached to your Azure Storage account

The second method is used by ADF and seems to be the preferred method.  I didn't learn this until after trying the first method though and running into some interesting behaviors.

#### Blob Storage (with blobTrigger) - Not Recommended

The first weird thing the "blobTrigger" did was create a backlog of every file I had added to storage and started triggering my app with this large backlog of files.  It turns out that behind the scenes it was creating a queue (in the storage account linked to our Azure Function - not the storage account you are monitoring) and started writing events to the queue for all files.

Then it began processing these one-at-a-time.  According to help forums on the internet people also complain that this method does not trigger their function immediately.  They say it actually scans the container periodically, looking for new files, and will trigger whenever this scan runs.  Based upon how many files are in your container, this scan make take several minutes to run.  For all of these reasons, I decided to use the Event triggers instead.

#### Blob Storage (with eventGridTrigger) - Recommended

The following page provides instructions for how to do connect an Azure Function to the EventGrid of a storage account:

https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-grid-trigger?tabs=python
There do seem to be some errors in the Microsoft documentation.  For those reasons I've included additional notes below.

First, you'll notice that your "functions.json" file that specifies the function trigger doesn't actually say what event grid it connects to:

___functions.json___

```
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "type": "eventGridTrigger",
      "name": "event",
      "direction": "in"
    }
  ]
}
```

You will need to create an EventGrid subscription for your function and connect to it.  This is where the documentation seems to be a little out of date.  Before getting there, let's take a quick peek at our function code:

___File: ```_init_.py```___

```
import json
import logging
import azure.functions as func

def main(event: func.EventGridEvent):
    result = json.dumps({
        'id': event.id,
        'data': event.get_json(),
        'topic': event.topic,
        'subject': event.subject,
        'event_type': event.event_type
    })
    logging.info('Python EventGrid trigger processed an event: %s', result)

    data = event.get_json()
    url = data["url"]
    logging.info('blob url: %s', url)

    protocol, remainder = url.split('://', 1)
    host, path = remainder.split('/', 1)

    logging.info('Checking database for path: %s', path)
    ...
```

This is the largely the default code that is created for you with the addition of a few lines that break down the blob URL and separate out the path (i.e. "container/path/to/file.txt").  The actual EventGrid messag that is sent to your function looks like this:

___File: test.json___

```
{
  "topic": "/subscriptions/60b60000-6cbd-4c1b-94b3-2440bd6bbe00/resourceGroups/mygroup/providers/Microsoft.Storage/storageAccounts/mystorage",
  "subject": "/blobServices/default/containers/raw/blobs/alooma.txt",
  "eventType": "Microsoft.Storage.BlobCreated",
  "eventTime": "2020-02-24T17:02:19.6069787Z",
  "id": "e3ef727f-701e-0120-6264-ebbf2d064bc6",
  "data": {
    "api": "PutBlob",
    "requestId": "e3ef727f-701e-0120-6264-ebbf2d000000",
    "eTag": "0x8D7B97BDD5E2D80",
    "contentType": "text/plain",
    "contentLength": 0,
    "blobType": "BlockBlob",
    "url": "https://mystorage.blob.core.windows.net/raw/path/to/file.csv.gz",
    "sequencer": "000000000000000000000000000025450000000000006533",
    "storageDiagnostics": {
      "batchId": "84a135c6-73aa-4cbc-8b2d-7695ced63328"
    }
  },
  "dataVersion": "",
  "metadataVersion": "1"
}
```

You can write this to a "test.json" file and invoke your function locally with:

___File: test.sh___

```
curl -X POST \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "aeg-event-type: Notification" \
  -d @test.json http://localhost:7071/runtime/webhooks/eventgrid?functionName=OnNewFile
```

As noted in the docs, the "data" payload changes based on the type of message being sent through EventGrid.  The file above is an example of what you will see from a Storage Account when a new file is created.  The "url" property is the one that gives you the address of the new file that was created, and this is what the Python code above parses in order to strip off the protocol and host name to just get the file path.  "contentLength" also does not seem to be a reliable property.  In the case above it was passed in as zero even though the file had content.  It was interesting to see that our Azure Function still triggered although the ADF pipelines we setup with the same trigger did not (because they were filtering out zero-length files).

The trickiest problem I had was connecting the function to the Azure Storage EventGrid.  The documentation references CLI commands that don't work.  And even when I updated them to use the correct syntax, they still didn't seem to work correctly.  There was also a link in the portal next to my Azure Function called "Add Event Grid subscription".  While it is active in the screenshot below, this did not originally work for me.  The link was grayed out and I couldn't use it.  If it works, this is probably the easiest way to connect your function to an EventGrid subscription.

![Screenshot](assets/functions_add_eventgrid.png)

Another way to do this is to navigate to your storage account in the portal and click "Events".  Here you can view all subscriptions to this EventGrid and create new ones. When specifying the endpoint details, there is an option for "Azure Function", but for some reason my function never showed up as an option here.  Instead, specify the endpoint as a "Web Hook" and provide the URL:

```
https://{functionappname}.azurewebsites.net/runtime/webhooks/eventgrid?functionName={functionname}&code={systemkey}
```

Ignore all the stuff in the docs about having to use a REST API to get the "systemkey".  You can get the key from the portal by going to "Function app settings".  This will show you all of the keys.  The one called "default" worked for me.  (Although there is one there now called "eventgrid_extension".  I don't know where that came from or when it appeared.)

## Troubleshooting

### AzureWebJobStorage ("Settings must be of the form 'name=value'")

I spent over an hour trying to diagnose this strange error that prevented my app from running locally:

```
Microsoft.Azure.WebJobs.Host: Error indexing method 'Functions.OnNewFile'. Microsoft.WindowsAzure.Storage: Settings must be of the form "name=value".
```

It turns out this was complaining about the auto-generated "local.settings.json" file which looked like this:

```
local.settings.json
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "AzureWebJobsStorage": "{AzureWebJobsStorage}"
  }
}
```

It turns out the value for "AzureWebJobsStorage" is invalid.  It should be of the form ```"DefaultEndpointsProtocol=https;AccountName=[name];AccountKey=[key]".``` You can actually copy this value from your Azure Function App settings (in the portal) to make sure your local environment looks like your cloud environment.

### Specifying the Time Zone for Your App

I was a little annoyed at a program that was logging the current date and time to a database using Python's "datetime.now()" function.  The time was showing up in UTC.  It turns out that apps run in UTC time by default.  An easy fix is to specify the "WEBSITE_TIME_ZONE" config variable for your app.  The value of this is different depending on whether your app is running on a Windows or Linux machine.  There is good documentation here:

* https://docs.microsoft.com/en-us/azure/app-service/faq-configuration-and-management#how-do-i-set-the-server-time-zone-for-my-web-app

Python runs on Linux, so you will want to use the list of time zones here.  Setting this to "America/New_York" fixed everything.  The app ran in Eastern time zone and "datetime.now()" reflected this, writing a value to the database in Eastern time.
