---
title: Google Cloud SDK (gcloud and gsutil)
---

The Google Cloud SDK is a set of command line programs like "gcloud" and "gsutil" that you can run to interact with the Google Cloud.  The SDK is especially useful when your company locks down the GCP web console.  So far I only really use three main programs:

| Program | Description |
|---------|-------------|
| gcloud  | Main program for setting up configuration and deploying resources in the cloud |
| gsutil  | Utility program that I mainly use for copying files to/from the cloud |

## Installing

These tools are installed as part of the Google Cloud SDK.  Install instructions are available here.  When prompted, you will want to install the beta tools as well as the normal installation files.

### Installing Behind Proxy

Of course, nothing can ever be that simple behind a corporate proxy where the install will fail.  In this case you will want to download a self-contained installer from the Google Cloud SDK [versioned archives](https://cloud.google.com/sdk/docs/downloads-versioned-archives).

Actually, I wasn't able to get the self-contained installer to work either. I ended up just opening a mobile hotspot on my phone and using the normal SDK installer over that. (Ain't nobody got time for this!)

I still couldn't get "gcloud init" to work though. Instead, I ended up building a configuration manually so that it looked like:

```
[compute]
region = us-central1
zone = us-central1-a
[core]
account = your.email@company.com
disable_usage_reporting = True
project = your_project
[proxy]
address = proxy.domain.com
port = 80
type = http
username = proxy_user
password = proxy_password
```

I created this as a separate configuration named "proxy" (before setting the above config):

```
gcloud config configurations create proxy
gcloud config configurations activate proxy
```

Then I logged in with:

```
gcloud auth login
```

I verified the installation by listing files in a bucket:

```
gsutil ls gs://mybucket
```

## Managing Configurations

NOTE: Google's reference docs for the "gcloud" utility program are available [here](https://cloud.google.com/sdk/gcloud/reference/config/).

### Setting the Active Configuration

The SDK supports multiple configurations - which comes in handy if you ever do work on GCP using your gmail account rather than your corporate credentials.  You can get a list of different configurations with:

```
gcloud config configurations list
```

You'll probably see something like:

```
NAME     IS_ACTIVE  ACCOUNT                PROJECT             DEFAULT_REGION  DEFAULT_ZONE
default  False      your.email@gmail.com   your-project-name
proxy    True       your.email@company.com  your-project-name   us-central1-c   us-central1
```

This shows that you have two configurations: "default" and "proxy" and that the "proxy" configuration is currently active.  You can activate a configuration with:

```
gcloud config configurations activate <name>
```

If you want to create a new configuration use:

```
gcloud config configurations create <name>
```

### Modifying the Active Configuration

Each configuration has a set of properties.  These can be viewed by running:

```
gcloud config list
```

You might see something like this:

```
[core]
account = your.email@gmail.com
disable_usage_reporting = False
project = your-project-name
```

Properties can be set using "gcloud config set" as shown:

```
gcloud config set account your.email@company.com
```

This is the syntax for modifying a "core" property.  If you are trying to modify a property under "proxy" you will specify its name with ```proxy/<name>```.  The typical proxy configurations is shown below.  Of course, replace "your_euid" and "your_password" with the relevant information.

```
gcloud config set proxy/address proxy.domain.com
gcloud config set proxy/port 8888
gcloud config set proxy/type http
gcloud config set proxy/username <your_euid>
gcloud config set proxy/password <your_password>
```

Google's page on [proxy settings](https://cloud.google.com/sdk/docs/proxy-settings) also notes that you can set the proxy user name and password using environmental variables "CLOUDSDK_PROXY_USERNAME" and "CLOUDSDK_PROXY_PASSWORD" if you want to prevent them from showing up in the config properties or log files.

### Authenticating

You will not be able to interact with the cloud until you authenticate.  The command to do this is:

```
gcloud auth login
```

This will open up a web page in your browser to login to your Google account.  Login using your corporate account and you should get a message indicating that you are now logged in with that user.

You can view a list of authentication accounts with:

```
gcloud auth list
```

This may give output like:

```
  Credentialed Accounts
ACTIVE  ACCOUNT
        my.personal.email@gmail.com
*       my.company.email@company.com
```

The active account should be set to whichever is specified in the active configuration.  To change this use:

```
gcloud config set account your.email@company.com
```

## SSH and SCP to a VM

You can list GCE instances with:

```
gcloud compute instances list
```

### SSH
Since SSH from the cloud console is disabled, the easiest way to connect to a GCE instance in the cloud is to use the following command:

```
gcloud beta compute ssh --internal-ip --zone [zone] --project [project] [instance name]


# Example:
gcloud beta compute ssh --internal-ip --zone us-east1-b --project my-project instance-1
```

Running this command from a Windows console will launch PuTTY and connect you automatically.

### SCP

You can also SCP files to/from these instances using the command:

```
gcloud beta compute scp <src> <dst> --internal-ip

# Example:
gcloud beta compute scp local_file.txt remote-machine:/home/user/remote_file.txt
```

The "src" and "dst" properties are the source and destination.  To specify a file on the remote machine use ```<machine-name>:/<path>```.

You can also use "--recursive" to copy entire directories recursively.

Just like SSH, you can specify project and zone information with ```--project <project> --zone <zone>```.  If not specified, these will default to values from your active configuration.
