---
title: GCR (Google Container Registry)
---

The Google Container Registry (GCR) is a place to store docker images in the cloud.  Storing images here provides easy integration with other Google services and makes it easy to run these images on compute resources.

## Pushing an Image to GCR (Manual)

If you have manually built an image on your laptop you can push this to GCR by tagging it and running the "docker push" command.  This is as simple as:

```
gcloud auth configure-docker

IMAGE=gcr.io/[gcp_project_id]/[image_name]:[version]

docker tag [image_name] $IMAGE
docker push $IMAGE
```

For more info see [this page](https://cloud.google.com/container-registry/docs/quickstart).

## Running an Image on GCE (Manual)

Once your image is in GCR you can run it on Google Compute Engine (GCE) pretty easily.  Create a GCE instance using the latest stable release of the Container-Optimized OS.  Then login to the instance with:

```
gcloud beta compute ssh --internal-ip [instance_name]
```

NOTE: This assumes gcloud is configured with your project ID and zone information so you don't need to specify them.

Once logged in, you will need to authenticate with GCR:

```
docker-credential-gcr configure-docker
```

You can then run the container with something like:

```
docker run -it gcr.io/project/image:1.0-SNAPSHOT /bin/bash
```

In many cases it will be useful to supply environmental variables via the "--env-file" parameter.  You can create a file that looks like this:

```
VAR1=value1
VAR2=value2
```

And then reference it when you launch the container with:

```
docker run -d --env-file my.env gcr.io/project/image:1.0-SNAPSHOT
```

In this last command we also used the "-d" flag to run the container in detached mode.  This will it in the background.  It will also let you logout of the GCE instance and keep the container running.

This process is a quick way to get docker containers running in the cloud.  However, there are better ways using automated build pipelines and Kubernetes.
