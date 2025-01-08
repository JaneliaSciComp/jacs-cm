# JACS Configuration Management

[![DOI](https://zenodo.org/badge/143904222.svg)](https://doi.org/10.5281/zenodo.14610143)

Part of the [Janelia Workstation](https://github.com/JaneliaSciComp/workstation) software ecosystem.

This repository allows for the creation and deployment of Docker containers which run the JACS infrastructure. It is designed around the DevOps concept of [Infrastructure as Code (IaC)](https://en.wikipedia.org/wiki/Infrastructure_as_Code).

Each subdirectory in the `containers` directory contains a versioned, containerized service which can be built into a Docker container using `manage.sh`. These containers have official versioned builds which are [published on Docker Hub](https://hub.docker.com/u/janeliascicomp), so you can skip the build step.

Each subdirectory in the `deployments` directory contains the configuration for a deployment orchestrated by e.g. Docker Compose or Docker Swarm.


## Deployment Walkthroughs

Different types of deployments are possible which provide various combinations of services with multiple swarm topologies. Currently, only the MouseLight tools are supported outside of Janelia. 

### Full JACS and Workstation

* [Single node development deployment](docs/ComposeDeployment.md) - single node deployment suitable for local development
* [Distributed production deployment](docs/FullDeployment.md) - requires at least 3 nodes


### MouseLight Tools and Services

* [Canonical MouseLight deployment](docs/MouseLightDeployment.md)


## Development

[Learn more](docs/BasicUsage.md) about using this repository for development.


## License

Modified [Janelia Open Source License](LICENSE.md), requiring citation for use in publications.

