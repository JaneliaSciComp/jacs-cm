# Docker Swarm Deployment

This document assumes that you have downloaded and configured the installer according to one of the [deployment guides](../README.md). 

The following steps are common to all Docker Swarm deployments of the Workstation.


## Initialize Filesystems

The first step is to initialize the filesystems on all your Swarm systems. On each server, ensure that your `REDUNDANT_STORAGE` (default: /opt/jacs), `NON_REDUNDANT_STORAGE` (default: /data) directories exist and can be written to by your UNAME:GNAME user (default: docker-nobody). Then, run the Swarm-based initialization procedure from **HOST1**:
```
./manage.sh init-filesystems
```

You can manually edit the files found in `CONFIG_DIR` to further customize the installation. 


### SSL Certificates

At this point, **it is strongly recommended is to replace the self-signed certificates** in `$CONFIG_DIR/certs/*` on each server with your own certificates signed by a Certificate Authority:
```
. .env
sudo cp /path/to/your/certs/cert.{crt,key} $CONFIG_DIR/certs/
sudo chown docker-nobody:docker-nobody $CONFIG_DIR/certs/*
```

If you continue with the self-signed certificates, you will need to [set up the trust chain](SelfSignedCerts.md) for them later.


### External Authentication

The JACS system has its own self-contained authentication system, and can manage users and passwords internally.

If you'd prefer that users authenticate against your existing LDAP or ActiveDirectory server, edit `$CONFIG_DIR/jacs-sync/jacs.properties` and add these properties:
```
LDAP.URL=
LDAP.SearchBase=
LDAP.SearchFilter=
LDAP.BindDN=
LDAP.BindCredentials=
```

The URL should point to your authentication server. The SearchBase is part of a distinguished name to search, something like "ou=People,dc=yourorg,dc=org". The SearchFilter is the attribute to search on, something like "(cn={{username}})". BindDN and BindCredentials defines the distinguished name and password for a service user that can access user information like full names and emails.


## Start All Containers

Next, start up all of the service containers. The parameter to the start command specifies the environment to use. The **dev** environment uses containers tagged as *latest* and updates them automatically when they change. The **prod** deployment uses a frozen set of production versions. When in doubt, use the **prod** deployment:
```
./manage.sh start
```

It may take a minute for the containers to spin up. You can monitor the progress with this command:
```
./manage.sh status
```

At this stage, some of the services may not start because they depend on the databases. The next step will take care of that.


## Initialize Databases

Now you are ready to initalize the databases:
```
./manage.sh init-databases
```

It's normal to see the "Unable to reach primary for set rsJacs" error repeated until the Mongo replica set converges on healthiness. After a few seconds, you should see a message "Databases have been initialized" and the process will exit successfully.

You can validate the databases as follows:
* Verify that you can connect to the Mongo instance using `./manage.sh mongo`, and run `show tables`
* Connect to the RabbitMQ server at http://**HOST1**:15672 and log in with your `RABBITMQ_USER`/`RABBITMQ_PASSWORD`


## Restart Services

Bounce the stack so that everything reconnects to the databases:
```
./manage.sh stop
./manage.sh start
```

Now you shoult wait for all the services to start. You can continue to monitor the progress with this command:

```
./manage.sh status
```

If any container failed to start up, it will show up with "0/N" replicas, and it will need to be investigated before moving further. You can view the corresponding error by specifying the swarm service name, as reported by the status command. For example, if jacs_jade-agent2 fails to start, you would type:
```
./manage.sh status jacs_jade-agent2
```


## Verify Functionality

You can verify the Authentication Service is working as follows:

```
./manage.sh login
```

You should be able to log in with the default admin account (root/root), or any LDAP/AD account if you've configured external authentication. This will return a JWT that can be used on subsequent requests.

If you run into any problems, these [troubleshooting tips](Troubleshooting.md) may help.


## Manage Services

As long as your Docker daemon is configured to restart on boot, all of the Swarm services will also restart automatically when the server is rebooted.

If you want to remove all the services from the Swarm and do a clean restart of everything, you can use this command:
```
./manage.sh stop
```

To pull and redeploy the latest image for a single service, e.g. workstation-site:
```
./manage.sh restart jacs_workstation-site
```

## Configure Crontabs

The following crontab entries should be configured in order to perform periodic maintenance automatically. It's easiest to install the crontabs on the docker-nobody account:

```
sudo crontab -u docker-nobody -e
```

Database maintenance refreshes indexes and updates entities permissions:
```
0 2 * * * /opt/deploy/jacs-cm/manage.sh dbMaintenance group:admin -refreshIndexes -refreshPermissions
```

SOLR index refresh (if using SOLR):
```
0 3 * * * /opt/deploy/jacs-cm/manage.sh rebuildSolrIndex
```


Database backups (if using containerized databases):
```
0 4 * * * /opt/deploy/jacs-cm/manage.sh backup mongo
```


## Install The Workstation Client

Now that the services are all running, you can navigate to https://HOST1 in a web browser on your client machine, and download the Workstation client. Follow the installer wizard, using the default options, then launch the Workstation.

If you are using the default self-signed certificate, you will need to take some extra steps to [install it on the client](SelfSignedCerts.md).

If you are using LDAP/AD integration, you should be able to log in with your normal user/password. If you are using the Workstation's internal user management, you must first login as user root (password: root), and then select **Window** → **Core** → **Administrative GUI** from the menus. Click "View Users", then "New User" and create your first user. Add the user to all of the relevant groups, including MouseLight.


## Optional: Adding NFS Storage

If you have data on NFS, and those NFS drives can be mounted on the MouseLight hosts, that data can be made available to the Workstation.

First, create a file at deployments/mouselight/docker-swarm.prod.yml which looks like this:
```
version: '3.7'
services:
  jade-agent1:
    volumes:
      - /path/to/your/nfs:/path/to/your/nfs:ro,shared
  jade-agent2:
    volumes:
      - /path/to/your/nfs:/path/to/your/nfs:ro,shared
```

This will expose the path to both JADE agent containers. Now you need to configure the JADE agents to serve this data. On both hosts, edit /opt/jacs/config/jade/config.properties and add the following:

```
StorageVolume.mouseLightNFS.RootDir=/path/to/your/nfs
StorageVolume.mouseLightNFS.VirtualPath=/path/to/your/nfs
StorageVolume.mouseLightNFS.Shared=true
StorageVolume.mouseLightNFS.Tags=mousebrain,light
StorageVolume.mouseLightNFS.VolumePermissions=READ
```

You can use any name you want instead of mouseLightNFS. Then you should add this name to StorageAgent.BootstrappedVolumes:
```
StorageAgent.BootstrappedVolumes=jade1,mouseLightNFS
```

You will need to bounce the service stack to pick up these changes.

