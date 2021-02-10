---
title: Docker
---

## Intro

Docker was pretty intimidating to me at first.  After upgrading to Windows 10, installing Docker Desktop, and playing around with some of the tutorials it has started to make a bit more sense.  First, there is a great cheat sheet available here:

* [Docker Cheat Sheet](https://www.docker.com/sites/default/files/Docker_CheatSheet_08.09.2016_0.pdf)

This includes a useful description of the docker run command and its main parameters:

```
docker run
            --rm   remove container automatically after it exits
             -it   connect the container to terminal
      --name web   name the container
      -p 5000:80   expose port 5000 from the container as port 80 on the local machine
  -v ~/dev:/code   create a host mapped volume inside the container
     alpine:3.4    the image from which the container is instantiated
        /bin/sh    the command to run inside the container
```

I've also seen some tutorials use the "-w" (as in "-w /opt") command.  This specifies the working directory.

## Terminology

I keep confusing docker terminology (especially "container" versus "image" and "repository" versus "registry").  Here are some key terms to keep me straight:

* __Container__ - A running instance of an image
* __Image__ - The basis for a running container.  An image is an "ordered collection of file system changes" and execution parameters for running the image in a container
* __Registry__ - A Registry is a hosted service containing repositories of images which responds to the Registry API.
* __Repository__ - A repository is a set of Docker images. A repository can be shared by pushing it to a registry server. The different images in the repository can be labeled using tags.

For a complete docker glossary, see: https://docs.docker.com/glossary/.

## Namespaces

Large companies might organize the repositories inside their registry into namespaces.  This is a logical grouping that just uses part of the repository path to group repositories.  As an example, a team's repository paths might look like:

```
docker-prod.registry.mycompanycom/myteam/awesome-image:1.2
```

This breaks down into:

```
registry/namespace/repository:tag
```

## Online Articles

Here are some online tutorials to help get started:

| Level | Link/Description |
|-------|------------------|
| Beginner | [Docker: have a Ubuntu development machine within seconds, from Windows or Mac](https://medium.com/@hudsonmendes/docker-have-a-ubuntu-development-machine-within-seconds-from-windows-or-mac-fd2f30a338e4)<br/>Quick intro to running Ubuntu on Windows and mounting a local drive. |
| Beginner	| [2.5 Ways to Update a Container](https://serversforhackers.com/c/updating-containers)<br/>How to make changes to a container (manually and through Dockerfiles, but it doesn't go deep into Dockerfiles) |
| Easy | [Behind the Corporate Proxy](https://dev.to/shriharshmishra/behind-the-corporate-proxy-2jd8)<br/>Information on how to run docker behind a corporate proxy.  (With some good humor thrown in) |
| Easy | [10 Myths About Docker That Stop Developers Cold](https://derickbailey.com/2017/01/30/10-myths-about-docker-that-stop-developers-cold/)<br/>Good article with tips for making docker a great development experience.  Good info on how to mount local folders into your container so you can develop locally in our favorite IDE but run everything in your docker environment. |
| Easy | [Put Your Dev Env in GitHub](https://www.freecodecamp.org/news/put-your-dev-env-in-github/)<br/>Article that suggests doing development in docker and committing your development Dockerfile along with your code.  This is separate from the production Dockerfile that will run your app.  It instead intended to make sure all the developers have the same tools, compilers, and libraries installed for development.  The author recommends using VSCode, but you can do this without VSCode as well. |
| Medium | [Using Docker Behind a Proxy](https://blog.codeship.com/using-docker-behind-a-proxy/)<br/>Another article on using docker behind a proxy.  This one gets into some more advanced usage and assumes a fairly good understanding of docker. |
| Medium | [Why you don't need to run SSHd in your docker containers](https://blog.docker.com/2014/06/why-you-dont-need-to-run-sshd-in-docker/)<br/>Explains why you shouldn't need to SSH into containers to do work there (but also tells you how to do it, just in case) |
| ?	 | Patterns and antipatterns in docker image lifecycle ([YouTube](https://www.youtube.com/watch?v=9OkpHOUp65w), [slides only](https://www.slideshare.net/jbaruch/patterns-and-antipatterns-in-docker-image-lifecycle-as-was-presented-at-scale-15x))<br/>Interesting looking presentation about how to manage docker images in an enterprise so you get consistent, reliable builds with high security. |
| Medium | [How to Create Optimized Docker Images for Production](https://haydenjames.io/how-to-create-optimized-docker-images-for-production/)<br/>Tips on using multi-stage builds to create smaller docker images for productions.  The main advice is to avoid adding all the build tools to your production image.  Instead, create a build step that can be big and bloated with all these tools, build your app, and then just copy your final executable over to a minimal Alpine docker image.  He shows how a 1 GB Ubuntu image can be used for building an app but your deployment can be as small as 11 MB. |

## Useful Commands

### Connect to a Running Container

```
docker container exec -it [container_name] /bin/bash
```

This command assumes that "/bin/bash" is installed on the container.  If present, it will be invoked.  "-it" connects interactively to the terminal.  Otherwise, the command would just exit.

## Using Docker behind a Proxy

If your Dockerfile build scripts need to access the internet, they will need to do so through the proxy.  Usually, it is enough to set the http_proxy and https_proxy environmental variables while building the image.  This can be done as shown:

```
http_proxy=http://user:password@proxy.domain.com:port/
https_proxy=$http_proxy

docker build \
  --build-arg http_proxy=$http_proxy \
  --build-arg https_proxy=$https_proxy \
  -t <tag> \
  .
```

This can be helpful when building docker images on your laptop using public repositories.  However, this isn't really what you're supposed to do.  Instead, most companies will setup internal registries and repositories (such as Artifactory) to serve dependencies in the internet in a safer manner.  These can be setup to proxy public repositories and serve the same content, but in a way that allows the company to see what artifacts are being pulled in from the internet, scan them to make sure they are safe, and sleep a little more soundly at night.

## Automated Builds

The GitLab build script below is one example of how you can automate the compilation and pushing of docker images to a repository:

```
APP_NAME="docker-test"
BUILD_NUMBER=$(git describe --tags)
NAMESPACE="my-team"
DOCKER_REGISTRY="docker-prod.registry.my-company.com"
DOCKER_NAME=$NAMESPACE/$APP_NAME
DOCKER_IMAGE=$DOCKER_REGISTRY/$DOCKER_NAME

docker logout ${DOCKER_REGISTRY}
docker build --build-arg version=${BUILD_NUMBER} --file Dockerfile --tag ${DOCKER_IMAGE} .
docker tag ${DOCKER_IMAGE} ${DOCKER_IMAGE}:latest
docker tag ${DOCKER_IMAGE} ${DOCKER_IMAGE}:${BUILD_NUMBER}
docker images --all
docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY}
docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
docker push ${DOCKER_IMAGE}:latest
```
