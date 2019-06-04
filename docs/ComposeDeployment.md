# Docker Compose Deployment

This document describes a Janelia Workstation deployment intended for setting up a personal development environment. Unlike the canonical distributed deployments which use Docker Swarm, this deployment uses Docker Compose to orchestrate the services on a single server.

Note that this deployment does not build and serve the Workstation client installers, although that could certainly be added in cases where those pieces need to be developed and tested. In most cases, however, it is expected that this server-side deployment be paired with a development client built and run from IntelliJ or NetBeans.


## System Setup

This deployment should work on any system where Docker is supported. Currently, it has only been tested on Scientific Linux 7.

To install Docker and Docker Compose on Scientific Linux 7, follow [these instructions](InstallingDockerSL7.md).


## Clone This Repo

Begin by cloning this repo:

```
git clone https://github.com/JaneliaSciComp/jacs-cm.git
cd jacs-cm
```


## Configure The System

Next, create a `.env.config` file inside the jacs-cm directory. This file defines the environment (usernames, passwords, etc.) You can copy the template to get started:
```
cp .env.template .env.config
vi .env.config
```

At minimum, you must customize the following:
1. Configured the `UNAME` and `GNAME` to your liking. Ideally, these should be your username and primary group.
2. Setup `REDUNDANT_STORAGE` and `NON_REDUNDANT_STORAGE` to point to directories accessible by `UNAME`:`GNAME`.
3. Set `HOST1` to the hostname you are deploying on. Use a fully-qualified hostname -- it should match the SSL certificate you intend to use.
4. Fill in all the unset passwords with >8 character passwords. You should only use alphanumeric characters, special characters are not currently supported.
5. Generate 32-byte secret keys for JWT_SECRET_KEY and MONGODB_SECRET_KEY.


## Enable Databases (optional)

Currently, Janelia runs MongoDB and MySQL outside of the Swarm, so they are commented out in the deployment. If you'd like to run the databases as part of the swarm, edit the yaml f
iles under ./deployments/jacs/ and uncomment the databases.


## Initialize Filesystems

The first step is to initialize the filesystem. Ensure that your `REDUNDANT_STORAGE` (default: /opt/jacs), `NON_REDUNDANT_STORAGE` (default: /data) directories exist and can be written to by your UNAME:GNAME user (default: docker-nobody). Then, run the initialization procedure:
```
./manage.sh init-local-filesystem
```

Now you can manually edit the files found in `CONFIG_DIR`. You can use these configuration files to customize much of the JACS environment.


### SSL Certificates

At this point, **it is strongly recommended is to replace the self-signed certificates** in `CONFIG_DIR/certs/*` on each server with your own certificates signed by a Certificate Authority:
```
sudo cp /path/to/your/certs/cert.{crt,key} $CONFIG_DIR/certs/
sudo chown docker-nobody:docker-nobody $CONFIG_DIR/certs/*
```
If you use self-signed certificates, you will need to [set up the trust chain](SelfSignedCerts.md) for them later.


### External Authentication

The JACS system has its own self-contained authentication system, and can manage users and passwords internally.

If you'd prefer that users authenticate against your existing LDAP or ActiveDirectory server, edit $CONFIG_DIR/jacs-sync/jacs.properties and add these properties:
```
LDAP.URL=
LDAP.SearchBase=
LDAP.SearchFilter=
LDAP.BindDN=
LDAP.BindCredentials=
```

The URL should point to your authentication server. The SearchBase is part of a distinguished name to search, something like "ou=People,dc=yourorg,dc=org". The SearchFilter is the attribute to search on, something like "(cn={{username}})". BindDN and BindCredentials defines the distinguished name and password for a service user that can access user information like full names and emails.


## Start All Containers

Now you can bring up all of the application containers:
```
./manage.sh compose up standalone -d
```

You can monitor the progress with this command:
```
./manage.sh compose ps
```


## Initialize Databases

Now you are ready to initalize the databases:
```
./manage.sh init-databases
```


## Updating Containers

Containers in this deployment are automatically updated by Watchtower whenever a new one is available with the "latest" tag. To update the deployment, simply build and push a new container to the configured registry.


## Stop All Containers

To stop all containers, run this command:
```
./manage.sh compose down standalone
```


## Build and Run Client

Now you can checkout the [Janelia Workstation](https://github.com/JaneliaSciComp/workstation) code base in IntelliJ or NetBeans and run its as per its README.

The client will ask you for the API Gateway URL, which is just `http://$HOST1`. In order to automatically connect to your standalone gateway instance, you can create a new file at `workstation/modules/Core/src/main/resources/my.properties` with this content (replacing the variables with the values from your .env.config file):
```
api.gateway=https://$HOST1
```

