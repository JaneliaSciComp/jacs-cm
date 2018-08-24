# JACS Configuration Management

Docker containers, configuration files for JACS services, and administrative scripts for maintaining the JACS infrastructure with the DevOps concept of [Infrastructure as Code (IaC)](https://en.wikipedia.org/wiki/Infrastructure_as_Code).

Each subdirectory contains a versioned, containerized service which can be built into a Docker container using manage.sh.

For information on how to create a new service, read about [Contributing](CONTRIBUTING.md).

## Configuration

Before using the `manage.sh` script, make sure that the variables at the top reflect your current reality. In particular, it's preconfigured to use the SCSW Docker Registry, which may or may not be what you want.

## Build
To build one or more service:
```
./manage.sh build [service1] [service2] [service3] ...
```
This creates a Docker container in your local repository.

## Push
To push one or more built containers to the remote repository:
```
./manage.sh deploy [service1] [service2] [service3] ...
```

## Shell
To open a shell into a built container:
```
./manage.sh shell [service]
```

## Run
To run a container in and tail its logs:
```
./manage run [service]
```

## Compose
To bring an environment up or down:
```
./manage up [env] [arg]
```
For example, to bring up dev in a detatched state:
```
./manage up dev -d
```

## Fancy Stuff
The script allows you to combine multiple commands with the `+` sign, and it ignores any paths without VERSION files, so you can use awesome shortcuts like this:
```
./manage build+push *
```

## Environments
Each environment is defined in a compose file with the name `docker-compose.<env>.yml`. This file is automatically loaded on top of the default `docker-compose.yml` when you use the manage.sh script to bring a given environment up or down. You should make a `docker-compose.local.yml` if you're testing locally. This file will be automatically ignored by Git.

## Versioning
Container versioning with a file called `VERSION` in each subdirectory. When making changes to a service, make sure to increment the
variable in the `VERSION` file before building or deploying that container.

