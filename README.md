# JACS Configuration Management

Docker containers, configuration files for JACS services, and administrative scripts for maintaining the JACS infrastructure with the DevOps concept of [Infrastructure as Code (IaC)](https://en.wikipedia.org/wiki/Infrastructure_as_Code).

Each subdirectory in the `containers` directory contains a versioned, containerized service which can be built into a Docker container using manage.sh.

Each subdirectory in the `deployments` directory contains the configuration for a deployment orchestrated by e.g. Docker Compose or Docker Swarm.

## Deployments

### MouseLight Tools and Services

To deploy the MouseLight tools, please follow the [step-by-step guide](docs/MouseLightDeployment.md).

## Initial Setup

Create a .env.config file which defines the environment (usernames, passwords, etc.) You can copy the template to get started:
```
cp .env.template .env.config
vi .env.config
```

Next, build the `builder` image which is necessary for building other services:
```
./manage.sh build builder
```

## Build

To build one or more service:
```
./manage.sh build [service1] [service2] [service3] ...
```
This creates a Docker container image in your local repository.

To build multiple containers, you can use shell wildcards. For example, to build the JACS and JADE containers:
```
./manage build ja*
```

Each service built here has a VERSION file which defines the container version, and an optional APP_TAG file while defines the SCM tag to checkout and build. If the APP_TAG does not exist, the master branch is assumed.


## Shell

To open a shell into a built container:
```
./manage.sh shell [service]
```

## Run

To run a single container by itself, and tail its logs:
```
./manage.sh run [service]
```

## Push to Docker Repository

To push one or more built containers to the remote repository:
```
./manage.sh push [service1] [service2] [service3] ...
```

The remote repository to use is defined by the `REGISTRY_SERVER` variable in .env.config. Bu default, this is blank, meaning that images will be loaded into Docker Hub. Of course, this only works if you first run `docker login`, and you have the correct write priviledges to the repositories.


## Multiple Commands

The script allows you to combine multiple commands with the `+` sign, and it ignores any paths without VERSION files, so you can use awesome shortcuts like this:
```
./manage.sh build+push *
```

## Running the Full Service Stack

The full JACS service stack is comprised of 15+ containers, orchestrated by Docker compose.

### Initial Setup

When deploying to a new environment, you need to provision the filesystem and databases before starting the full stack. 
If you haven't built and deployed them yet, you'll need to build all the containers first:
```
./manage.sh build containers/*
```

Ensure that your /data/db and /opt/config directories are empty and writeable by you, and then execute these commands:
```
./manage.sh init-filesystem
./manage.sh up dev --dbonly -d
./manage.sh init-databases
./manage.sh down dev --dbonly
```

You can customize the default configurations in /opt/config now, before bringing up the full stack.

### Bringing up the complete stack

To bring an environment up or down:
```
./manage.sh up [env] [args]
```
For example, to bring up dev in a detatched state:
```
./manage.sh up dev -d
```
To update a single container:
```
./manage.sh up dev -d --no-deps api-gateway
```

## Environments

Each environment is defined in a compose file with the name `docker-compose.<env>.yml`. This file is automatically loaded on top of the default `docker-compose.yml` when you use the manage.sh script to bring a given environment up or down. You should make a `docker-compose.local.yml` if you're testing locally. This file will be automatically ignored by Git.

## Versioning

Container versioning with a file called `VERSION` in each subdirectory. When making changes to a service, make sure to increment the
variable in the `VERSION` file before building or deploying that container.

## Loading Data into MongoDB

To load data into the lightsheet database:
```
sdocker run -v /dump/dir:/dump -it --network=jacs-cm_jacs-net mongo:3.6 /usr/bin/mongorestore --uri "mongodb://lightsheet:password@mongo1:27017,mongo2:27017,mongo3:27017/lightsheet?replicaSet=rsJacs&authSource=admin" -d lightsheet /dump
```

## Notes

For running elastic search make sure that the vm.max_map_count is set to at least 262144:
```
sysctl -w vm.max_map_count=262144
```

## License 

[Janelia Open Source License](https://www.janelia.org/open-science/software-licensing)

