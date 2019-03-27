# MouseLight Deployment

This document describes the simplest possible JACS/Workstation deployment for supporting mouse neuron tracing. It uses prebuilt containers available on Janelia's container repository. It's assumed that data will be generated at Janelia and shipped to the remote site for viewing and tracing. 


## Hardware

The JACS backend consists of several services which need to be deployed on server hardware. We have tested the following configuration:

* Two Dell PowerEdge R740XD Servers
    * Each server has 40 cores (Intel Xeon Gold 6148 2.4G)
    * Each server has 192 GB of memory
    * The hard drives are configured as follows:
        * 2 x 200GB SSD - Operating system (/)
        * 2 x 960GB SSD in RAID1 - Databases, user preferences, etc. (/opt)
        * 12 x 10TB in RAID6 - Image files (/data)

The rest of this guide assumes that you have two hosts dedicated to deploying this system. They will be referred to as **HOST1** and **HOST2**.


## Install Scientific Linux 7

In theory, the backend software will run on any OS supporting Docker. However, Scientific Linux is used at Janelia and has been extensively tested with this software. We recommend installing the latest version of Scientific Linux 7.


## Install Docker

To install Docker on SL7, follow [these instructions](InstallingDockerSL7.md).


## Clone the jacs-cm repo

Clone this repo into /opt/deploy/jacs-cm on both of the systems being deployed. If the systems have access to a common NFS path, it is easier to clone it onto NFS, and then create symbolic links to it on both systems. Otherwise they will need to be kept in sync manually. The naive approach clones twice:

```
cd /opt
sudo mkdir deploy
sudo chown $USER deploy
cd deploy
git clone https://github.com/JaneliaSciComp/jacs-cm.git
cd jacs-cm
```


## Configuration

Next, create an indentical .env file in both jacs-cm directories. This file defines the environment (usernames, passwords, etc.) You can copy the template to get started:
```
cp .env.template .env
vi .env
```

At minimum, you must customize the following:
1. Set `DEPLOYMENT` to mouselight.
2. Fill in all the unset passwords with >8 character passwords.
3. Set a 32 byte secret key for JWT authentication.
4. Set `HOSTNAME1` and `HOSTNAME2` to the two servers you want to use (i.e. **HOST1** and **HOST2**).
#4. Set `RABBITMQ_EXPOSED_HOST`, `API_GATEWAY_EXPOSED_HOST` and `JADE_AGENT_EXPOSED_HOST` to the hostname of the first server you are deploying to (e.g. **HOST1**)
#5. Set `JADE_AGENT2_EXPOSED_HOST` to **HOST2**.
6. Set the `WORKSTATION_TAG` to the tag of the Workstation codebase you want to build and deploy.
7. Set `WORKSTATION_DISPLAY_VERSION` to a branded version number, such as "8.0-JRC" for deploying at Janelia Research Campus.


## Build

Build the Workstation:
```
./manage.sh build_all
```


### Filesystem initialization

Now you can initialize the filesystem (on both systems). Ensure that your `DATA_DIR` (default: /data/db) and `CONFIG_DIR` (default: /opt/config) directories are empty and writeable by the user defined by UNAME:GNAME (by default, docker-nobody), and then initialize them:

```
sudo mkdir /opt/config
sudo chown docker-nobody:docker-nobody /opt/config /data
./manage.sh init-filesystem
```

You can now manually edit the files found under `CONFIG_DIR`. You can use these configuration files to customize much of the JACS environment, but the following customizations are minimally necessary for MouseLight deployments:

1. `certs/*` - By default, self-signed TLS certificates are generated and placed here. You should overwrite them with the real certificates for your host.

On HOST2, edit 
```
StorageVolume.jade.VirtualPath=/jade1
StorageVolume.jade.Tags=local,jade2,jade_dev,includesUserFolder
```

### Database initialization

Next, start up the databases on the first node only:
```
./manage.sh swarm prod --dbonly
```
At this point you should connect to Portainer at https://HOST1:9000 and create an admin user. Portainer setup has a timeout, so if you can't reach the container try running the up command again to refresh it.

Now you are ready to initalize the databases:

```
./manage.sh init-databases
```
It's normal to see the "Unable to reach primary for set rsJacs" error repeated until the Mongo replica set converges on healthiness. After a few seconds, you should see a message "Databases have been initialized" and the process will exit successfully.

You can validate the databases as follows:
* Connect to http://YOUR_HOST:15672 and log in with your `RABBITMQ_USER`/`RABBITMQ_PASSWORD`
* Verify that you can connect to the Mongo instance using `./manage.sh mongo` and the MySQL instance using `./manage.sh mysql`


## Start application containers

Now that the databases are running, you can bring up all of the remaining application containers using Docker Swarm.

On node1, bring up swarm as a manager node, and give it a label:
```
docker swarm init
```

On node2, copy and paste the output of the previous command to join the swarm as a worker. 

```
docker swarm join --token ...
```

All further commands should be executed on node1, i.e. the master node. First, label the nodes:
```
docker node update --label-add name=node1 $(docker node ls -f "role=manager" --format "{{.ID}}")
docker node update --label-add name=node2 $(docker node ls -f "role=worker" --format "{{.ID}}")
```

Now you can bring up the full stack running on both machines:
```
./manage.sh swarm prod
```

You can verify the Authentication Service is working as follows:

```
./manage.sh login
```

You should be able to log in with the default admin account (root/root). This will return a JWT that can be used on subsequent requests. For example, use it to verify the JACS services:

```
export TOKEN=<enter token here>
curl -k --request GET --url https://HOST1/SCSW/JACS2AsyncServices/v2/services/metadata --header "Content-Type: application/json" --header "Authorization: Bearer $TOKEN"
```

To remove all the services:
```
./manage.sh rmswarm prod
```

# Backups

You should create two crontab entries on **HOST2** for backing up Mongo and MySQL, e.g.

```
0 4 * * * /opt/deploy/jacs-cm/manage.sh backup mongo
0 5 * * * /opt/deploy/jacs-cm/manage.sh backup mysql
```

The reason that these should run on **HOST2** is because the MySQL database and a Mongo secondary both run there.

