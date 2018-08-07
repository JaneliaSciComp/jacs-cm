# JACS Configuration Management

Docker containers,configuration files for JACS services, and administrative scripts for maintaining the JACS infrastructure.

Each subdirectory contains a versioned, containerized service which can be built into a Docker container using manage.sh.

For information on how to create a new service, read about [Contributing](CONTRIBUTING.md).

## Configuration

Before using the manage.sh script, make sure that the variables at the top reflect the environment you want to build for. 
At any given time, they should reflect working with the current JACS production infrastruture.

## Build
To build one or more service:
```
./manage.sh build [service1] [service2] [service3] ...
```
This creates a Docker container in your local repository.

## Shell
To open a shell into a built container:
```
./manage.sh shell [service]
```

## Run
To run a container in interactive mode:
```
./manage run [service]
```

## Push
To push one or more built containers to the remote repository:
```
./manage.sh deploy [service1] [service2] [service3] ...
```

## Versioning
Container versioning with a file called VERSION in each subdirectory. When making changes to a service, make sure to increment the
variable in the VERSION file before building or deploying that container.

