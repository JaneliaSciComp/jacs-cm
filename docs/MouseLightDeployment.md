# MouseLight Deployment

This document describes the canonical two-server Janelia Workstation deployment for supporting neuron tracing for the [MouseLight project](https://www.janelia.org/project-team/mouselight) at the Janelia Research Campus and other research institutions. This deployment uses Docker Swarm to orchestrate prebuilt containers available on Docker Hub.

Please note that this deployment does not currently have the capability of preprocessing raw data. Instead, it's assumed that imagery will be generated and preprocessed at Janelia and shipped to the remote site for viewing and tracing. These data preprocessing tools will be added in the future.

## Deployment Diagram

<div style="text-align:center"><img src="images/TwoServerDeployment.png" alt="Two-server Deployment Diagram" /></div>


## Setup Hardware

The JACS backend consists of several services which need to be deployed on server hardware. We have tested the following configuration:

* Two Dell PowerEdge R740XD Servers
    * Each server has 40 cores (e.g. Intel Xeon Gold 6148 2.4G)
    * Each server has 192 GB of memory
    * The hard drives are configured as follows:
        * 2 x 200GB SSD - Operating system (/)
        * 2 x 960GB SSD in RAID1 - Databases, user preferences, etc. (/opt)
        * 12 x 10TB in RAID6 - Image files (/data)

The rest of this guide assumes that you have two server hosts dedicated to deploying this system, which are configured as listed above. They will be referred to as **HOST1** and **HOST2**.

This two-server deployment can support 5-10 concurrent users. We use the following configuration for client machines:

* Dell Precision 5820 Tower
    * Minimum of 8 cores (e.g. Intel Xeon W-2145 3.7GHz)
    * 128 GB of memory
    * Nvidia GTX1080Ti 11GB (reference card, blower fan style)
        * Other similar cards will work fine: GTX1070, GTX1080, RTX2080
    * Windows 10


## Install Scientific Linux 7

The backend software should run on any operating system which supports Docker. However, Scientific Linux is used at Janelia and has been extensively tested with this software. Therefore, we recommend installing the latest version of Scientific Linux 7 or CentOS 7.


## Install Docker

To install Docker and Docker Compose on Scientific Linux 7, follow [these instructions](InstallingDockerSL7.md).


## Setup Docker Swarm

On **HOST1**, bring up swarm as a manager node, and give it a label:
```
docker swarm init
```

On **HOST2**, copy and paste the output of the previous command to join the swarm as a worker.

```
docker swarm join --token ...
```

All further commands should be executed on **HOST1**, i.e. the master node. One final step is to label the nodes. Each node needs the "jacs=true" label, as well as "jacs_name=nodeX".
```
docker node update --label-add jacs_name=node1 $(docker node ls -f "role=manager" --format "{{.ID}}")
docker node update --label-add jacs_name=node2 $(docker node ls -f "role=worker" --format "{{.ID}}")
docker node update --label-add jacs=true $(docker node ls -f "role=manager" --format "{{.ID}}")
docker node update --label-add jacs=true $(docker node ls -f "role=worker" --format "{{.ID}}")
```

Finally, you can run this command to ensure that both nodes are up and in Ready status:
```
docker node ls
```


## Clone This Repo

Clone this repo into `/opt/deploy/jacs-cm` on both of the systems being deployed. If the systems have access to a common NFS path, it is easier to clone onto NFS, and then create symbolic links to it on both systems. Otherwise the clones will need to be kept in sync manually. If you don't mind doing manually synchronization, you can just clone the repo twice:

```
cd /opt
sudo mkdir deploy
sudo chown $USER deploy
cd deploy
git clone https://github.com/JaneliaSciComp/jacs-cm.git
cd jacs-cm
```


## Configure The System

Next, create an identical `.env.config` file in both jacs-cm directories. This file defines the environment (usernames, passwords, etc.) You can copy the template to get started:
```
cp .env.template .env.config
vi .env.config
```

At minimum, you must customize the following:
1. Set `DEPLOYMENT` to **mouselight**.
2. Ensure that `REDUNDANT_STORAGE` and `NON_REDUNDANT_STORAGE` point to the disk mounts you used during the operating system installation. Alternatively, you can make symbolic links so that the default paths point to your mounted disks.
3. Set `HOST1` and `HOST2` to the two servers you are deploying on. Use fully-qualified hostnames here -- they should match the TLS certificate you intend to use.
4. Fill in all the unset passwords with >8 character passwords. You should only use alphanumeric characters, special characters are not currently supported.
5. Generate 32-byte secret keys for JWT_SECRET_KEY and MONGODB_SECRET_KEY.

Remember that after customizing the .env.config, it must be synchronized to both servers, unless you have placed the jacs-cm directory on a shared NFS mount.


## Initialize Filesystems

Now you can initialize the filesystem on both systems. Ensure that your `DATA_DIR` (default: /data), `DB_DIR` (default: /opt/db), `CONFIG_DIR` (default: /opt/config), and `BACKUPS_DIR` (default: /opt/backups) directories exist and be written to by your UNAME:GNAME user (by default, docker-nobody). For example:

```
. .env.config
sudo mkdir -p $CONFIG_DIR $DATA_DIR $DB_DIR $BACKUPS_DIR
sudo chown docker-nobody:docker-nobody $CONFIG_DIR $DATA_DIR $DB_DIR $BACKUPS_DIR
```

Once the above setup has successfully completed on both of the hosts, run the Swarm-based initialization procedure:
```
./manage.sh init-filesystems
```

Now you can manually edit the files found in `CONFIG_DIR`. You can use these configuration files to customize much of the JACS environment.

At this point, **it is strongly recommended is to replace the self-signed certificates** in `CONFIG_DIR/certs/*` on each server with your own certificates signed by a Certificate Authority:
```
sudo cp /path/to/your/certs/cert.{crt,key} $CONFIG_DIR/certs/
sudo chown docker-nobody:docker-nobody $CONFIG_DIR/certs/*
```


## Start All Containers

Next, start up all of the service containers:
```
./manage.sh start prod
```

It may take a minute for everything to spin up. You can monitor the progress with this command:
```
./manage.sh status
```

If any container failed to start up, it will show up with "0/N" replicas, and it will need to be investigated before moving further. You can view the corresponding error by specifying the swarm service name, as reported by the status command. For example, if jade-agent2 fails to start, you would type:
```
./manage.sh status jacs_jade-agent2
```


## Initialize Databases

Now you are ready to initalize the databases:

```
./manage.sh init-databases
```
It's normal to see the "Unable to reach primary for set rsJacs" error repeated until the Mongo replica set converges on healthiness. After a few seconds, you should see a message "Databases have been initialized" and the process will exit successfully.

You can validate the databases as follows:
* Verify that you can connect to the Mongo instance using `./manage.sh mongo` and the MySQL instance using `./manage.sh mysql`
* Connect to http://**HOST1**:15672 and log in with your `RABBITMQ_USER`/`RABBITMQ_PASSWORD`


## Verify Functionality

You can verify the Authentication Service is working as follows:

```
./manage.sh login
```

You should be able to log in with the default admin account (root/root). This will return a JWT that can be used on subsequent requests. 

If you run into any problems, these [troubleshooting tips](Troubleshooting.md) may help.


## Manage Services

As long as your Docker daemon is configured to restart on boot, all of the Swarm services will also restart automatically.

If at any point you want to remove all the services from the Swarm and do a clean restart of everything, you can use this command:
```
./manage.sh stop prod
```

To pull and redeploy the latest image for a single service, e.g. workstation-site:
```
./manage.sh restart jacs-cm_workstation-site
```


## Setup Database Maintenance

Database maintenance refreshes indexes and updates entities permissions. It can be run using:
```
./manage.sh dbMaintenance username [-refreshIndexes] [-refreshPermissions]
```
where username is the name of a subject that must already exist. You should create a crontab entry on **HOST2** for running this script periodically, e.g.
```
0 2 * * * /opt/deploy/jacs-cm/manage.sh dbMaintenance -refreshIndexes -refreshPermissions
```

## Setup Database Backups

You should create two crontab entries on **HOST2** for backing up Mongo and MySQL, e.g.
```
0 4 * * * /opt/deploy/jacs-cm/manage.sh backup mongo
0 5 * * * /opt/deploy/jacs-cm/manage.sh backup mysql
```

The reason that these should run on **HOST2** is because the MySQL database and a Mongo secondary both run there.


## Install The Workstation Client

If you are using the default self-signed certificate, you will need to take some extra steps to [install it on the client](SelfSignedCerts.md).

Navigate to https://HOST1 in a web browser on your client machine, and download the Workstation client for Windows. Follow the installer wizard, using the default options, then launch the Workstation.

If you are using LDAP/AD integration, you should be able to log in with your normal user/password. If you are using the Workstation's internal user management, you must first login as user root (password: root), and then select **Window** → **Core** → **Administrative GUI** from the menus. Click "View Users", then "New User" and create your first user. Add the user to all of the relevant groups, including MouseLight.


## Import Data

The data for MouseLight comes as a directory containing TIFF images organized into octrees. You should place each sample in $DATA_DIR/jacsstorage/samples on one of the servers. If you place the sample on the first server, in `$DATA_DIR/jacsstorage/samples/<sampleDirectoryName>`, then in the Workstation you will refer to the sample as `/jade1/<sampleDirectoryName>`.

In the Workstation, select **File** → **New** → **Tiled Microscope Sample**, and then set "Sample Name" to `<sampleDirectoryName>` and "Path to Render Folder" as `/jade1/<sampleDirectoryName>`.

Open the Data Explorer (**Window** → **Core** → **Data Explorer**) and navigate to Home, then "3D RawTile Microscope Samples", and your sample name. Right-click the sample and choose "Open in Large Volume Viewer". The 2D imagery should load into the middle panel. You should be able to right-click anywhere on the image and select "Navigate to This Location in Horta (channel 1)", to load the 3D imagery.


## Find More Information

This concludes the MouseLight Workstation installation procedure. Further information on using the tools can be found in the [Janelia Workstation User Manual](https://github.com/JaneliaSciComp/workstation/blob/master/docs/UserManual.md).

