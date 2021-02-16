---
title: DataBricks Project Structure
---

## Overview

A co-worker proposed the following project directory structure for use in DataBricks for the Inventory Domain Solution project.  He has used this layout successfully in the past.

![Screenshot](databricks/assets/project-layout.png)

The top-level "Inventory Domain Solution" folder was created as an easy way to manage all notebooks related to this project.  We provide real-only access on this folder to everyone but then only allow project members to contribute new code.  We could also put this under "Shared", but it is slightly different in that the code is not intended to be shared with everyone in the workspace.

The individual folders are then described below.

### Create Tables

Location for all statements used to create tables in any layer, including curated

Each table created should be placed in it’s own Notebook named after the table name.

For instance, a table named inventory_domain.dim_store should have a notebook with the same name place in this folder

Creation of databases (schemas) can be placed in this folder as well

### Create Views

Location to store all SQL used to create views

Each view should get it’s own notebook with a name matching the name of the view that is created

### Data Transformations

Location to store all the code used to generate the transformations to load curated tables

Each curated table should have an associated notebook inside this folder

For instance, the loading of inventory_domain.dim_store should have a notebook named “Load inventory_domain.dim_store”

### Libraries

Any library that is needed and referenced in the code should be placed in this folder.

If we create our own libraries, then a new folder can be created.

### Referenced Notebooks

Any notebook that should be referenced by another notebook for reusable code should be stored in this folder

### Other

Other potential folders that can be created if/as needed:

* Functions: Any custom functions that are registered should be stored in this folder
* Libraries/Custom: Store code here for creation of any custom libraries developed by the team
