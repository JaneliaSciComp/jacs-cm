# MouseLight Deployment

This document describes the canonical two-server Janelia Workstation deployment for supporting neuron tracing for the [MouseLight project](https://www.janelia.org/project-team/mouselight) at the Janelia Research Campus and other research institutions. This deployment uses Docker Swarm to orchestrate prebuilt containers available on Docker Hub. 

Please note that this deployment does not currently have the capability of preprocessing raw data. Instead, it's assumed that imagery will be generated and preprocessed at Janelia and shipped to the remote site for viewing and tracing. These data preprocessing tools will be added in the future.


## Hardware

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


## Clone the jacs-cm repo

Clone this repo into /opt/deploy/jacs-cm on both of the systems being deployed. If the systems have access to a common NFS path, it is easier to clone onto NFS, and then create symbolic links to it on both systems. Otherwise the clones will need to be kept in sync manually. The naive approach just clones the repo twice:

```
cd /opt
sudo mkdir deploy
sudo chown $USER deploy
cd deploy
git clone https://github.com/JaneliaSciComp/jacs-cm.git
cd jacs-cm
```


## Configuration

Next, create an identical .env.config file in both jacs-cm directories. This file defines the environment (usernames, passwords, etc.) You can copy the template to get started:
```
cp .env.template .env.config
vi .env.config
```

At minimum, you must customize the following:
1. Set `DEPLOYMENT` to **mouselight**.
2. Setup `REDUNDANT_STORAGE` and `NON_REDUNDANT_STORAGE` to the mounts you used during the operating system installation. Alternatively, you can make symbolic links so that the default paths point to your mounted disks.
3. Set `HOST1` and `HOST2` to the two servers. Use fully-qualified hostnames here -- they should match the SSL certificate you intend to use.
4. Fill in all the unset passwords with >8 character passwords. You should only use alphanumeric characters, special characters are not currently supported.
5. Set a 32-byte secret key for JWT authentication.
6. Set the `WORKSTATION_TAG` to the tag of the Workstation codebase you want to build and deploy, e.g. **8.0**.
7. Set `WORKSTATION_BUILD_VERSION` to a branded version number, e.g. **${WORKSTATION_TAG}-JRC** for deploying version 8.0 at Janelia Research Campus.

Remember that after customizing the .env.config, it must be synchronized to both servers, unless you have placed jacs-cm on an NFS mount.


## Filesystem Initialization

Now you can initialize the filesystem on both systems. Ensure that your `DATA_DIR` (default: /data), `DB_DIR` (default: /opt/db), `CONFIG_DIR` (default: /opt/config), and `BACKUPS_DIR` (default: /opt/backups) directories exist and be written to by your UNAME:GNAME user (by default, docker-nobody), and then initialize them. For example:

```
. .env.config
sudo mkdir -p $CONFIG_DIR $DATA_DIR $DB_DIR $BACKUPS_DIR
sudo chown docker-nobody:docker-nobody $CONFIG_DIR $DATA_DIR $DB_DIR $BACKUPS_DIR
./manage.sh init-filesystem
```

Once this procedure has successfully completed on both of the hosts, you can manually edit the files found in `CONFIG_DIR`. You can use these configuration files to customize much of the JACS environment, but the only customization that is strongly recommended is to replace the self-signed certificates in `CONFIG_DIR/certs/*` with your own certificates signed by a Certificate Authority.


### MongoDB Key Synchronization

The MongoDB key files on both systems need to be identical. Currently this must be done manually, e.g.:

On **HOST1**:
```
sudo cp $DB_DIR/mongo/jacs/replica1/mongodb-keyfile /tmp
sudo chown $USER /tmp/mongodb-keyfile
scp /tmp/mongodb-keyfile HOST2:/tmp
```

On **HOST2**:
```
echo $DB_DIR/mongo/jacs/replica{1,2,3}/mongodb-keyfile | sudo xargs -n 1 cp /tmp/mongodb-keyfile
```


## Swarm Setup

On **HOST1**, bring up swarm as a manager node, and give it a label:
```
docker swarm init
```

On **HOST2**, copy and paste the output of the previous command to join the swarm as a worker.

```
docker swarm join --token ...
```

All further commands should be executed on **HOST1**, i.e. the master node. One final step is to label the nodes:
```
docker node update --label-add name=node1 $(docker node ls -f "role=manager" --format "{{.ID}}")
docker node update --label-add name=node2 $(docker node ls -f "role=worker" --format "{{.ID}}")
```

You may have to use sudo to run the commands like below:
```
sudo docker node update --label-add name=node1 $(sudo docker node ls -f "role=manager" --format "{{.ID}}")
sudo docker node update --label-add name=node2 $(sudo docker node ls -f "role=worker" --format "{{.ID}}")
```

You can run this command to ensure that both nodes are up and in Ready status:
```
docker node ls
```


## Database Initialization

Next, start up the databases:
```
./manage.sh swarm prod --dbonly
```
At this point you should connect to Portainer at http://HOST1:9000 and create an admin user. Portainer setup has a timeout, so if you can't reach the container try running the up command again to refresh it.

Now you are ready to initalize the databases:

```
./manage.sh init-databases
```
It's normal to see the "Unable to reach primary for set rsJacs" error repeated until the Mongo replica set converges on healthiness. After a few seconds, you should see a message "Databases have been initialized" and the process will exit successfully.

You can validate the databases as follows:
* Connect to http://YOUR_HOST:15672 and log in with your `RABBITMQ_USER`/`RABBITMQ_PASSWORD`
* Verify that you can connect to the Mongo instance using `./manage.sh mongo` and the MySQL instance using `./manage.sh mysql`


## Build Client Distribution

Only on **HOST1**, build the site-specific Workstation client and the distribution website container:
```
./manage.sh build workstation-site
```

This container is specific to your deployment site, and contains the **HOST1** hostname in its configuration. Therefore, it cannot be distributed in a Docker registry. Besides the Workstation client, this container also deploys a website for accessing the installers, and other information. The website is made available at https://HOST1. Also make sure that the value assigned to WORKSTATION_TAG in the .env file is a tag that exists in the workstation github repo.


## Start All Containers

Now you can bring up all of the remaining application containers:
```
./manage.sh swarm prod
```

If you see an error like this, just retry the command again:
```
failed to create service jacs-cm_portainer: Error response from daemon: network jacs-cm_jacs-net not found
```

Next, you should make sure that all replicas are operational. You can do this by running:
```
docker service ls
```
If any container failed to start up, it will show up with "0/N" replicas, and it will need to be investigated before moving further. You can view the corresponding error by specifying the service name to `service ps`. For example, if jade-agent2 fails to start, you would type:
```
docker service ps --no-trunc jacs-cm-test_mongo1
```

Once a service starts, you can tail its logs using the `logs` command:
```
docker service logs -f jacs-cm-test_mongo1
```

All of this information is also available in the Portainer web GUI.

## Verify that the system is working

You can verify the Authentication Service is working as follows:

```
./manage.sh login
```

You should be able to log in with the default admin account (root/root). This will return a JWT that can be used on subsequent requests. For example, use it to verify the JACS services:

```
export TOKEN=<enter token here>
curl -k --request GET --url https://HOST1/SCSW/JACS2AsyncServices/v2/services/metadata --header "Content-Type: application/json" --header "Authorization: Bearer $TOKEN"
```

## Service Management

If at any point you want to remove all the services from the Swarm and do a clean restart of everything, you can use this command:
```
./manage.sh rmswarm prod
```

To pull and redeploy the latest image for a single service, e.g. workstation-site:
```
docker service update --force jacs-cm_workstation-site
```

## Backups

You should create two crontab entries on **HOST2** for backing up Mongo and MySQL, e.g.

```
0 4 * * * /opt/deploy/jacs-cm/manage.sh backup mongo
0 5 * * * /opt/deploy/jacs-cm/manage.sh backup mysql
```

The reason that these should run on **HOST2** is because the MySQL database and a Mongo secondary both run there.


## Client Machine Setup

If you are using the default self-signed certificate, you will need to take some extra steps to [install it on the client](SelfSignedCerts.md).

Navigate to https://HOST1 in a web browser on your client machine, and download the Workstation client for Windows. Follow the installer wizard, using the default options, then launch the Workstation.

If you are using LDAP/AD integration, you should be able to log in with your normal user/password. If you are using the Workstation's internal user management, you must first login as user root (password: root), and then select **Window** → **Core** → **Administrative GUI** from the menus. Click "View Users", then "New User" and create your first user. Add the user to all of the relevant groups, including MouseLight.

## Data Import

The data for MouseLight comes as a directory containing TIFF images organized into octrees. You should place each sample in $DATA_DIR/jacsstorage/samples on one of the servers. If you place the sample on the first server, in `$DATA_DIR/jacsstorage/samples/<sampleDirectoryName>`, then in the Workstation you will refer to the same as `/jade1/<sampleDirectoryName>`.

In the Workstation, select **File** → **New** → **Tiled Microscope Sample**, and then set "Sample Name" to `<sampleDirectoryName>` and "Path to Render Folder" as `/jade1/<sampleDirectoryName>`.

Open the Data Explorer (**Window** → **Core** → **Data Explorer**) and navigate to Home, then "3D RawTile Microscope Samples", and your sample name. Right-click the sample and choose "Open in Large Volume Viewer". The 2D imagery should load into the middle panel. You should be able to right-click anywhere on the image and select "Navigate to This Location in Horta (channel 1)", to load the 3D imagery.

This concludes the MouseLight Workstation installation. Further information on using the tools can be found in the [Janelia Workstation User Manual](https://github.com/JaneliaSciComp/workstation/blob/master/docs/UserManual.md).




