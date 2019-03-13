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


## Install Scientific Linux 7

In theory, the backend software will run on any OS supporting Docker. However, Scientific Linux is used at Janelia and has been extensively tested with this software. We recommend installing the latest version of Scientific Linux 7.


## Install Docker

To install Docker on SL7, follow [these instructions](InstallingDockerSL7.md).


## Clone the jacs-cm repo

On one of the systems being deployed to, clone this repo into /opt/deploy/jacs-cm:
```
cd /opt
sudo mkdir deploy
sudo chown $USER deploy
cd deploy
git clone https://github.com/JaneliaSciComp/jacs-cm.git
cd jacs-cm
```


## Configuration

Next, create a .env file which defines the environment (usernames, passwords, etc.) You can copy the template to get started:
```
cp .env.template .env
vi .env
```

At minimum, you must customize the following:
1. Set `DEPLOYMENT` to mouselight_compose
2. Fill in all the unset passwords
3. Set a 32 byte secret key for JWT authentication
4. Set API_GATEWAY_EXPOSED_HOST and JADE_AGENT_EXPOSED_HOST to the hostname of the server you are deploying to


### Filesystem initialization

Ensure that your `DATA_DIR` (default: /data/db) and `CONFIG_DIR` (default: /opt/config) directories are empty and writeable by the user defined by UNAME:GNAME (by default, docker-nobody), and then initialize them:

```
sudo mkdir /opt/config
sudo chown docker-nobody:docker-nobody /opt/config /data
./manage.sh init-filesystem
```

You can now manually edit the files found under `CONFIG_DIR`. You can use these configuration files to customize much of the JACS environment, but the following customizations are minimally necessary for MouseLight deployments:

1. `certs/*` - By default, self-signed TLS certificates are generated and placed here. You should overwrite them with the real certificates for your host.


### Database initialization

Next, start up the databases only:
```
./manage.sh up node1 --dbonly -d
```
At this point you should connect to Portainer at https://YOUR_HOST:9000 and create an admin user. Portainer setup has a timeout, so if you can't reach the container try running the up command again to refresh it.

Now you are ready to initalize the databases:

```
./manage.sh init-databases
```
It's normal to see the "Unable to reach primary for set rsJacs" error repeated until the Mongo replica set converges on healthiness. After a few seconds, you should see a message "Databases have been initialized" and the process will exit successfully.

You can validate the databases as follows:
* Connect to http://YOUR_HOST:15672 and log in with your `RABBITMQ_USER`/`RABBITMQ_PASSWORD`
* Verify that you can connect to the Mongo instance using `./manage.sh mongo` and the MySQL instance using `./manage.sh mysql`


## Start application containers

Now that the databases are running, you can bring up all of the remaining application containers like this:

```
./manage.sh up node1 -d
```

You can verify the Authentication Service is working as follows:

```
./manage.sh login
```

You should be able to log in with the default admin account (root/root). This will return a JWT that can be used on subsequent requests. For example, use it to verify the JACS services:

```
export TOKEN=<enter token here>
curl -k --request GET --url https://e06u18.int.janelia.org/SCSW/JACS2AsyncServices/v2/services/metadata --header "Content-Type: application/json" --header "Authorization: Bearer $TOKEN"
```

