# Contributing Services

The purpose of this repository is to serve as a central resource for configuration management for JACS services via containers.

## Creating a New Service

1. To create a new service, simply add a subdirectory with your service name.
2. Add all of your production configuration inside the subdirectory.
3. Create a file in your subdirectory called "Dockerfile" which contains the recipe for building the Docker container for your service.
4. Create a README.md file in your subdirectory with simple instructions for deploying your container, e.g. does it need external disk mounts, or port mappings. Look at other services for examples.

