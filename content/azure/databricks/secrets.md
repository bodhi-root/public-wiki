---
title: Secrets in DataBricks
---

## Overview

In order to avoid putting credentials into your DataBricks notebook, best practice is to store them as "secrets" in DataBricks.  Secrets are set at the DataBricks service level.  They are not attached to any specific cluster.  They are grouped into "scopes" and stored as simple key/value pairs.  Secrets can be accessed from DataBricks notebooks, but they will not be printed out or visible to anyone.

Secrets can be set in two ways:

* Using the REST API
* Using the DataBricks CLI

In order to avoid installing additional software and having to fight though the proxy, I just used the REST API.  It's easy enough to invoke this from "curl".

Once defined, secrets can be accessed in DataBricks notebooks with:

```
dbutils.secrets.get(scope="scope-name", key="key-name")
```

They can also be referenced in your Spark config settings for your cluster as shown in the code below:

```
fs.azure.account.auth.type.myadlsstorage.dfs.core.windows.net SharedKey
fs.azure.account.key.myadlsstorage.dfs.core.windows.net {{secrets/scope-name/key-name}}
```

## Using the REST API

### Configuration

In order to use the REST API you will need to create a personal access token.  These can be generated in the DataBricks web UI under "user settings".  This token will serve as your password to access the API, and it can be set to expire or easily revoked.  The following are sample commands to list scopes, create a new scope, list secrets, and create a new secret.  In order to save time and make the commands re-usable we set a few environmental variables:

```
API_BASE=https://centralus.azuredatabricks.net/api/2.0
DATABRICKS_SERVICE=1234567890
DATABRICKS_TOKEN=mytoken
```

If you are behind a corporate proxy you will want to set "http_proxy" and "https_proxy" environmental variables before running these commands.

### List Scopes

This is a simple GET request:

```
curl \
  -X GET \
  -H "Authorization: Bearer $DATABRICKS_TOKEN" \
  "$API_BASE/secrets/scopes/list?o=$DATABRICKS_SERVICE"
```

### Create New Scope

For this you will need to use a POST request and pass in a JSON request body.  This specifies the name of the new scope.  According to the docs "initial_manage_principal" should always be set to "users".

```
curl --header "Content-Type: application/json" \
  -X POST \
  -H "Authorization: Bearer $DATABRICKS_TOKEN" \
  --data '{"scope": "scope-name", "initial_manage_principal": "users"}' \
  $API_BASE/secrets/scopes/create?o=$DATABRICKS_SERVICE
```

### List Secrets

This one is also a GET request, but this time also with a request body:

```
curl --header "Content-Type: application/json" \
  -X GET \
  -H "Authorization: Bearer $DATABRICKS_TOKEN" \
  --data '{"scope": "scope-name"}' \
  $API_BASE/secrets/list?o=$DATABRICKS_SERVICE
```

### Add New Secret

```
curl --header "Content-Type: application/json" \
  -X POST \
  -H "Authorization: Bearer $DATABRICKS_TOKEN" \
  --data '{"scope": "scope-name", "key": "key-name", "string_value": "value"}' \
  $API_BASE/secrets/put?o=$DATABRICKS_SERVICE
```

## Using KeyVault

DataBricks allows you to setup a DataBricks secret scope that is actually an alias for an Azure KeyVault.  This could be a good option for many use cases.  Once you set this up, you will be able to manage your secrets using KeyVault and then access them in DataBricks.  A good tutorial on this is available here:

https://medium.com/@cprosenjit/azure-databricks-with-azure-key-vaults-c00df6548222

This tutorial tells you how to navigate to a hidden URL path "#secrets/createScope" and input the values you need to connect to key vault.

I actually wasn't successful when I tried this.  I received an error saying: "Internal error happened while granting read/list permission to Databricks service principal to KeyVault: https://mykeyvault.vault.azure.net/".  I believe this was due to limited permissions I have in this subscription.  I can't see key vault values and I can't manage identities or roles either.
