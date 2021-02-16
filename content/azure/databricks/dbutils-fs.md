---
title: dbutils.fs
---

## Overview

"dbutils.fs" is the DataBricks utility File System package.  It allows you to interact with file systems of various types, including the local DBFS file system, remote ADLS storage accounts, and even other types of storage.

The most important command to remember with dbutils.fs is:

```
dbutils.fs.help()
```

This prints out a nice list of commands with basic help info. As indicated in the output below, you can even get more detailed information on specific commands with "dbutils.fs.help("methodName").

```
dbutils.fs provides utilities for working with FileSystems. Most methods in this package can take either a DBFS path (e.g., "/foo" or "dbfs:/foo"), or another FileSystem URI. For more info about a method, use dbutils.fs.help("methodName"). In notebooks, you can also use the %fs shorthand to access DBFS. The %fs shorthand maps straightforwardly onto dbutils calls. For example, "%fs head --maxBytes=10000 /file/path" translates into "dbutils.fs.head("/file/path", maxBytes = 10000)".

fsutils

cp(from: String, to: String, recurse: boolean = false): boolean -> Copies a file or directory, possibly across FileSystems
head(file: String, maxBytes: int = 65536): String -> Returns up to the first 'maxBytes' bytes of the given file as a String encoded in UTF-8
ls(dir: String): Seq -> Lists the contents of a directory
mkdirs(dir: String): boolean -> Creates the given directory if it does not exist, also creating any necessary parent directories
mv(from: String, to: String, recurse: boolean = false): boolean -> Moves a file or directory, possibly across FileSystems
put(file: String, contents: String, overwrite: boolean = false): boolean -> Writes the given String out to a file, encoded in UTF-8
rm(dir: String, recurse: boolean = false): boolean -> Removes a file or directory

mount

mount(source: String, mountPoint: String, encryptionType: String = "", owner: String = null, extraConfigs: Map = Map.empty[String, String]): boolean -> Mounts the given source directory into DBFS at the given mount point
mounts: Seq -> Displays information about what is mounted within DBFS
refreshMounts: boolean -> Forces all machines in this cluster to refresh their mount cache, ensuring they receive the most recent information
unmount(mountPoint: String): boolean -> Deletes a DBFS mount point
```

## Listing all Files in a Directory

dbutils.fs can be used to list files in ADLS storage.  This can be done with the code below:

```
def list_raw_data_files_recursive(path):
  """Recursively list all raw data files in the given directory and child directories."""
  result = []

  print("Examining path: {}".format(path))

  children = dbutils.fs.ls(path)
  for child in children:
    if child.name.endswith("/"):  # better test for directories (avoid problems with zero byte files)
      if child.name != ".meta/":
        result.extend(list_raw_data_files_recursive(child.path))
    else:
      result.append(child.path)

  return result
```

There are some limitations around what you can do with dbutils.fs.  The only information returned by the "ls" command is:

| Attribute | Type       | Description                         |
|-----------|------------|-------------------------------------|
| path      | string     | The path of the file or directory.  |
| name      | string     | The name of the file or directory.  |
| isDir()   | boolean    | True if the path is a directory.    |
| size      | long/int64 | The length of the file in bytes or zero if the path is a directory. |

One noticeable omission is the "last_modified" date which can be useful in some cases.  In order to get access to these types of expanded properties, you will need to use a different library that provides functionality for the specific type of storage that you are using.

## Listing all Files with ADLS Libraries

If you do need to interact with ADLS storage in an expanded way, the code below shows how to do this.

```
from azure.identity import ClientSecretCredential
from azure.storage.filedatalake import DataLakeServiceClient
import datetime

SERVICE_CREDENTIALS = ClientSecretCredential(
  tenant_id     = dbutils.secrets.get("shared","TENANT_ID"),
  client_id     = dbutils.secrets.get("shared","CLIENT_ID"),
  client_secret = dbutils.secrets.get("shared","SECRET")
)

def list_raw_files(storage_account, container, base_path):
  """Returns a list of all data files in a particular ADLS directory.
  We skip over the ".meta" folder.  Results are returned as a list of dicts.
  Each dict contains the entries: name, content_length, and last_modified.
  We ended up using the azure-storage-file-datalake Python library to do
  this query rather than dbutils.fs because we wanted to get the last_modified
  date.  Your cluster will need to have the following libraries installed:

  * azure-storage-file-datalake==12.1.2
  * azure-identity==1.4.0
  """

  service_client = DataLakeServiceClient(
    account_url="https://{}.dfs.core.windows.net".format(storage_account),
    credential=SERVICE_CREDENTIALS)

  file_system_client = service_client.get_file_system_client(file_system=container)

  all_files = []

  paths = file_system_client.get_paths(base_path, recursive=True)
  for path in paths:
    #print(path.name + " " + path.last_modified)
    if not path.is_directory and path.name.find("/.meta/") < 0:
      # path.last_modified is in the format: "Thu, 03 Sep 2020 16:10:33 GMT" (even though it should be a datetime)
      date_txt = datetime.datetime.strptime(path.last_modified, "%a, %d %b %Y %H:%M:%S %Z").isoformat() # parse

      file_info = {
        "name": path.name,
        "content_length": path.content_length,
        "last_modified": date_txt
      }
      all_files.append(file_info)

  return all_files

all_files = list_raw_files("path/to/something")  
print(len(all_files))
```

As noted in the comments, this will require the "azure-storage-file-datalake==12.1.2" Python library which is not installed in DataBricks by default.  But once you add this to your cluster you will be able to use the full functionalit fo this library.  As mentioned in the documentation, the "get_paths()" function returns the following information for files:

* __name__ (str) – the full path for a file or directory.
* __owner__ (str) – The owner of the file or directory.
* __group__ (str) – he owning group of the file or directory.
* __permissions__ (str) – Sets POSIX access permissions for the file owner, the file owning group, and others. Each class may be granted read, write, or execute permission. The sticky bit is also supported. Both symbolic (rwxrw-rw-) and 4-digit octal notation (e.g. 0766) are supported.
* __last_modified__ (datetime) – A datetime object representing the last time the directory/file was modified.
* __is_directory__ (bool) – is the path a directory or not.
* __etag__ (str) – The ETag contains a value that you can use to perform operations conditionally.
* __content_length__ – the size of file if the path is a file.

It also is able to walk the entire file system (or descendants of a particular directory) with one API call, making it more efficient than the earlier example with "dbutils.fs" which sent a separate call for each directory's contents.
