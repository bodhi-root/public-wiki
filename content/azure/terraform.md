---
title: Terraform (for Azure)
---

## Overview

Terraform is a tool for specifying "Infrastructure as Code" (IAC).  It works with multiple cloud providers, and even lets you manage deployments across multiple clouds at the same time.  This page will document some things I learn about Terraform as I try to use it for the first time.

> TIP: Production Example & Better Notes
>
> This page documents some of the very basic fundamentals about Terraform (such as manually running "terraform apply" commands).  This is never how we do things in production.  A production Terraform environment would use automated build pipelines (in Azure DevOps) to plan and then apply Terraform changes.  But it's still good to understand the basics of how this tool works.

## Getting Started

First, there are instructions for using Terraform with Azure here:

* https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure

This says that Terraform is automatically available in the Azure Shell.  This is probably the easiest way to get started.  Your first terraform script is going to look something like this:

___test.tf___

```
provider "azurerm" {
  version = "=1.36.1"
  subscription_id = "1234568-1234-1234-1234-1234567890af"
}
```

In order to get the version of Terraform's Azure provider use:

```
terraform --version
```

In order to get the subscription ID for the subscription you want to work with, use:

```
az account list
```

Once you have saved the terraform file to something like "test.tf", you can run:

```
terraform init
```

This will create some files in your current directory that Terraform will use.  If you want to try actually creating something in your subscription, try the following to create a resource group:

```
provider "azurerm" {
  version = "=1.36.1"
  subscription_id = "1234568-1234-1234-1234-1234567890af"
}

resource "azurerm_resource_group" "rg-dash-common" {
  name     = "dash-common"
  location = "centralus"
  tags = {
    application-name: "My App"
    owner: "my.email@company.com"
  }
}
```

You can preview the changes this will make to your environment by running:

```
terraform plan
```

You can then apply them with:

```
terraform apply
```

That annoying error you get about not having specified a "-out" parameter and not being able to guarantee that what you see in "terraform plan" is what you'll actually get can be remedied by doing:

```
terraform plan -o tfplan
terraform apply tfplan
```

This is described here: https://learn.hashicorp.com/terraform/development/running-terraform-in-automation.  Using terraform this way will save a plan to a file named "tfplan" and then execute that same plan when you run "apply".

## Importing Resources

I thought that Terraform had the ability to import your current environment, but this seems to be a bit more limited than I imagined.  As described here, Terraform doesn't yet generate code for your imported state.  Instead, it just updates the terraform state behind-the-scenes.  In order to import the state, you must first create a placeholder in your terraform script files.  If you are importing a resource group, you will first need to define an empty block like:

```
resource "azurerm_resource_group" "common" {

}
```

Then you can run:

```
terraform import azurerm_resource_group.common /subscriptions/1234568-1234-1234-1234-1234567890af/resourceGroups/common
```

You have to get the resource ID from Azure.  (I think I found this on the "Properties" pane.)  If you were to run "terraform plan" it will show you what will change and can help you populate your terraform config file.  However, it doesn't populate it for you automatically.  I decided I didn't want to import this resource.  I removed it from my Terraform state with:

```
terraform state rm /subscriptions/1234568-1234-1234-1234-1234567890af/resourceGroups/common
```

> NOTE: You wouldn't want to just delete it from your Terraform files and then run them because this would delete the resource you just imported!
