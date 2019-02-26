# MouseLight Deployment

This document describes the simplest possible JACS/Workstation deployment for supporting mouse neuron tracing. It uses prebuilt containers available on Janelia's container repository. It's assumed that data will be generated at Janelia and shipped to the remote site for viewing and tracing. 

## Hardware

The JACS backend consists of several services which need to be deployed on server hardware. We have tested the following configuration:

* Two Dell PowerEdge R740XD Servers
    * Each server has 40 cores (Intel Xeon Gold 6148 2.4G)
    * Each server has 192 GB of memory
    * The hard drives are configured as follows:
        * 2 x 200GB SSD - Operating system
        * 2 x 960GB SSD in RAID1 - Databases, user preferences, etc.
        * 12 x 10TB in RAID6 - Image files

## Install Scientific Linux 7

In theory, the backend software will run on any OS supporting Docker. However, Scientific Linux is used at Janelia and has been extensively tested with this software.

## Install Docker

To install Docker on SL7, follow [these instructions](InstallingDockerSL7.md).

## Clone the jacs-cm repo

On one of the systems being deployed to, clone this repo:
```
git clone https://github.com/JaneliaSciComp/jacs-cm.git
cd jacs-cm
```

## Configuration

Next, create a .env file which defines the environment (usernames, passwords, etc.) You can copy the template to get started:
```
cp .env.template .env
vi .env
```

At the very least, you must set all the unset password variables, and enter the hostname for the exposed hosts.

### Filesystem initialization

Ensure that your /data/db and /opt/config directories are empty and writeable by you, and then initialize them:

```
./manage init-filesystem
```

By default, self-signed TLS certificates are generated and placed in $CONFIG_DIR/certs. Overwrite them with your real certificates if possible.

### Database initialization

Next, start up the databases and initialize them:
```
./manage.sh up dev --dbonly -d
./manage.sh init-databases
./manage.sh down dev --dbonly
```

## Start containers

Bring up all of the containers like this:

```
./manage.sh up prod -d
```

