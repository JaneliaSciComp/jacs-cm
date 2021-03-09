# Basic Usage

This page describes basic usage of this repository and conventions which should be followed when building, versioning, and deploying services.

## Initial Setup

You will need Docker and Docker Compose. Installing [Docker on Oracle Linux 8](InstallingDockerOL8.md) is standardized to make it easier to deploy JACS on these systems. For other architectures, please refer to the Docker documentation.

Next, create a .env.config file which defines the environment (usernames, passwords, etc.) You can copy the template to get started:
```
cp .env.template .env.config
vi .env.config
```

Finally, build the `builder` image which is necessary for building other services:
```
./manage.sh build builder
```

## Building Containers

You don't have to build your own containers. You can skip this step in order to use the official images which are [published on Docker Hub](https://hub.docker.com/u/janeliascicomp). However, if you want to customize the images, or build them from source, this repository offers the same build method that's used to create the official images. 

In order to build images locally, you will probably want to customize the image namespace in your .env.config file. You can use this to push to your own local Docker repository, e.g. to use the internal Janelia repository:
```
NAMESPACE=registry.int.janelia.org/jacs
```

To build a container:
```
./manage.sh build [containerDir]
```
You can specify the full path, or relative path, or even just the directory name. 

If successful, this step creates Docker container images in your local repository.

Each service under the `containers` directory has a VERSION file which defines the container version, and an optional APP_TAG file while defines the SCM tag to checkout and build. If the APP_TAG does not exist, the master branch is assumed.


## Push to Docker Repository

To push one or more built containers to the remote repository (defined by your `NAMESPACE` variable):
```
./manage.sh push [containerDir1] [containerDir2] [containerDir3] ...
```

By default, the namespace contains no server, meaning that Docker Hub is used. This requires a successful `docker login` before the push, and you need to have write priviledges to the relevant repositories.


## Multiple Commands

The manage.sh script allows you to combine multiple commands with the `+` sign, and it ignores any paths without VERSION files, so you can use shortcuts to do many things in one command, such as build and push all the containers:
```
./manage.sh build+push containers/*
```


## Shell

To open a shell into a built container:
```
./manage.sh shell [containerDir]
```


## Run

To run a single container by itself, and tail its logs:
```
./manage.sh run [containerDir]
```

## Other Notes

To load data into the lightsheet database:
```
sdocker run -v /dump/dir:/dump -it --network=jacs-cm_jacs-net mongo:3.6 /usr/bin/mongorestore --uri "mongodb://lightsheet:password@mongo1:27017,mongo2:27017,mongo3:27017/lightsheet?replicaSet=rsJacs&authSource=admin" -d lightsheet /dump
```

For running elastic search make sure that the vm.max_map_count is set to at least 262144:
```
sysctl -w vm.max_map_count=262144
```

