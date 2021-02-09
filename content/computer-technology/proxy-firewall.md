---
title: Proxy Firewalls
---

## Overview

For many years, I worked at a company whose network forced all internet traffic through the corporate proxy.  This was quite a pain in the ass, and led to many tools not working.  Everything would work wonderfully if you were on your laptop at home on your own network, but as soon as you plugged into the corporate network, everything seemed to be 10 times harder.  If you've ever experienced this yourself, you've probably felt like this guy:

![I'm going to find you and switch off the proxy server](assets/switch-off-the-proxy-server.jpg)

source: [Behind the Corporate Proxy](https://dev.to/shriharshmishra/behind-the-corporate-proxy-2jd8)

Here are some quick notes for how to setup various tools to work with the corporate proxy (and how to turn them off when you're at home).

## Linux

If you're on a Linux system (usually connecting by SSH) you'll want these commands:

```
export http_proxy=http://user:password@proxy.domain.com:port/
export https_proxy=http://user:password@proxy.domain.com:port/
```

## Windows CMD

If you're on the Windows command line the following is supposed to work:

```
set HTTP_PROXY=http://user:password@proxy.domain.com:port
```

However, in practice this hasn't been helpful.  Usually I'm struggling because some other tool (like NPM or NG CLI) isn't picking up the proxy settings.  A lot of tools don't even look for these environmental variables on Windows.  So if you're having problems with NPM or the NG CLI see the next section.

## Git

Details on configuring git to use a proxy can be found [here](https://gist.github.com/evantoli/f8c23a37eb3558ab8765).  The command I used successfully is:

```
git config --global http.proxy http://user:password@proxy.domain.com:port
```

This is needed if you want git to work with external repositories like GitHub.  You can unset this value by running:

```
git config --global --unset http.proxy
```

## NPM & NG CLI

This is the most annoying one.  You get all excited to start a new project only to find that you can't download any dependencies to get started.  In this case the settings are in NPM:

```
npm config set proxy http://user:password@proxy.domain.com:port
npm config set https-proxy http://user:password@proxy.domain.com:port
```

This was actually the whole reason I created this page.  I got stuck (again) trying to create a new project.  After an hour of Googling, it works! But now i have to go to a meeting... (sad)

If you want to unset these values use:

```
npm config rm proxy
npm config rm https-proxy
```

## Eclipse

When programming in Eclipse you want to edit Network Configuration settings to look like this:

![Eclipse settings screenshot](assets/proxy-eclipse-screenshot.png)

Now... this is the most annoying setting of the group.  When configured this way everything will work in the office.  But if you try to install packages at home using this setup, it won't find the proxy.  It will either: 1) timeout, 2) download a bunch of garbage that could corrupt your maven directory (that's fun to recover from).  __To make this work at home you will want to change the "Active Provider" setting at the top from "Manual" (which specifies the proxy) to "Direct"__.  This tells Eclipse it can connect directly to the internet without going through a proxy.  (Man... it only took me 6 years to figure that one out!)

## R

If you're working in R you'll need this magic line of code from Jim Holtman:

```
# this will let you through the firewall
Sys.setenv(http_proxy = "http://proxy.domain.com:port/", http_proxy_user = "ask")
```

This should open a window to prompt for your user name and password whenever a request is made to the network.

Unfortunately, this only works in basic R.  It does not seem to work in R Studio.  I'm told that the block of code below will work in both environments.  (I haven't tested this though, and some people still say they can't get outside the network even after running this.)

```
Sys.setenv(http_proxy = "http://proxy.domain.com:port/", http_proxy_user = "ask")

if (version$major <= 3 && version$minor < 3) {
  utils::setInternet2(FALSE)
} else if (version$major >= 3 && version$minor >= 3) {
  options(download.file.method= "internal")
} else {
  warning("unknown version number: ", version$major, ".", version$minor)
}
```

## Python

If you're trying to install packages using pip you'll want to use:

```
pip install --proxy=https://user:password@proxy.domain.com:3128 <package>
```

If you're using Anaconda then you have to set them as environmental variables:

```
set HTTP_PROXY=http://user:password@proxy.domain.com:3128
set HTTPS_PROXY=http://user:password@proxy.domain.com:3128
conda install <package>
```

If you are instead trying to set proxy information from within a Python program, you can use:

```
import os
os.environ["https_proxy"] = "http://user:password@proxy.domain.com:port/"
os.environ["http_proxy"] = os.environ["https_proxy"]
```

## Docker (on Windows)

If you're using Docker on Windows you'll want to set proxy information in the docker settings.  The usual format (http://user:password@domain:port/) should be entered in the boxes below:

![Docker Settings Screenshot](assets/proxy-docker-screenshot.png)
