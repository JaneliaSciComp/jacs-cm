# Docker Compose Deployment

This document describes a Janelia Workstation deployment intended for setting up a personal development environment. Unlike the canonical distributed deployments which use Docker Swarm, this deployment uses Docker Compose to orchestrate the services on a single server.

Note that this deployment does not build and serve the Workstation client installers, although that could certainly be added in cases where those pieces need to be developed and tested. In most cases, however, it is expected that this server-side deployment be paired with a development client built and run from IntelliJ or NetBeans.


## System Setup

This deployment should work on any system where Docker is supported. Currently, it has only been tested on Scientific Linux 7.

To install Docker and Docker Compose on Scientific Linux 7, follow [these instructions](InstallingDockerSL7.md).


## Clone This Repo

Clone this repo somewhere where you can access the target system you are deploying to.

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
1. Set `DEPLOYMENT` to **jacs**.
2. Configured the `UNAME` and `GNAME` to your liking. Ideally, these should be your username and primary group.
3. Setup `REDUNDANT_STORAGE` and `NON_REDUNDANT_STORAGE` to point to directories accessible by `UNAME`:`GNAME`.
4. Set `HOST1` to the hostname you are deploying on. Use fully-qualified hostnames here -- they should match the TLS certificate you intend to use.
5. Fill in all the unset passwords with >8 character passwords. You should only use alphanumeric characters, special characters are not currently supported.
6. Generate 32-byte secret keys for JWT_SECRET_KEY and MONGODB_SECRET_KEY.


## Initialize Filesystems

Ensure that your `DATA_DIR` (default: /data), `DB_DIR` (default: /opt/db), `CONFIG_DIR` (default: /opt/config), and `BACKUPS_DIR` (default: /opt/backups) directories exist and be written to by your UNAME:GNAME user. For example:

```
. .env.config
sudo mkdir -p $CONFIG_DIR $DATA_DIR $DB_DIR $BACKUPS_DIR
sudo chown $UNAME:$GNAME $CONFIG_DIR $DATA_DIR $DB_DIR $BACKUPS_DIR
```

Once the above setup has successfully completed on both of the hosts, run the Docker-based initialization procedure:
```
./manage.sh init-local-filesystem
```

Now you can manually edit the files found in `CONFIG_DIR`. You can use these configuration files to customize much of the JACS environment.

At this point, **it is strongly recommended is to replace the self-signed certificates** in `CONFIG_DIR/certs/*` on each server with your own certificates signed by a Certificate Authority:
```
sudo cp /path/to/your/certs/cert.{crt,key} $CONFIG_DIR/certs/
sudo chown docker-nobody:docker-nobody $CONFIG_DIR/certs/*
```

## Initialize Databases

This deployment does not include the main databases (Mongo and MySQL), but this step is necessary to initialize SOLR and RabbitMQ.

Bring up the databases only:
```
./manage.sh up dev --dbonly -d
```

Then initialize them:
```
./manage.sh init-databases
```


## Start All Containers

Now you can bring up all of the latest application containers:
```
./manage.sh up dev -d
```


## Stop All Containers

To stop all containers, run this command:
```
./manage.sh down dev
```


## Build and Run Client

Now you can checkout the [Janelia Workstation](https://github.com/JaneliaSciComp/workstation) code base in IntelliJ or NetBeans and run its as per its README.

In order to connect to your dev instance, create a new file at `workstation/modules/Core/src/main/resources/my.properties` with this content (replacing the variables with the values from your .env.config file):
```
mainserver.name=$HOST1
api.gateway=https://{mainserver.name}
domain.msgserver.url={mainserver.name}
domain.msgserver.useraccount=$RABBITMQ_USER
domain.msgserver.password=$RABBITMQ_PASSWORD
```

If you run into any problems, these [troubleshooting tips](Troubleshooting.md) may help.


