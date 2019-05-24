# JACS Configuration Management

Part of the [Janelia Workstation](https://github.com/JaneliaSciComp/workstation) software ecosystem.

This repository allows for the creation and deployment of Docker containers which run the JACS infrastructure by following the DevOps concept of [Infrastructure as Code (IaC)](https://en.wikipedia.org/wiki/Infrastructure_as_Code).

Each subdirectory in the `containers` directory contains a versioned, containerized service which can be built into a Docker container using manage.sh. These containers have official builds which are [published on Docker Hub](https://hub.docker.com/u/janeliascicomp).

Each subdirectory in the `deployments` directory contains the configuration for a deployment orchestrated by e.g. Docker Compose or Docker Swarm.


## Deployment Walkthroughs

Different types of deployments are possible which provide various combinations of services with multiple swarm topologies. 

### Full JACS and Workstation

1. [Single node development deployment](docs/ComposeDeployment.md) - single node deployment suitable for local development
2. [Distributed production deployment](docs/FullDeployment.md) - requires at least 3 nodes


### MouseLight Tools and Services

1. [Canonical MouseLight deployment](docs/MouseLightDeployment.md)


## Development 

You can learn more about the [basic usage](docs/BasicUsage.md) of this repository for development.


## License 

[Janelia Open Source License](LICENSE.md)

