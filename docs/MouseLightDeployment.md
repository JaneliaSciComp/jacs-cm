# MouseLight Deployment

This document describes the canonical two-server Janelia Workstation deployment for supporting neuron tracing for the [MouseLight project](https://www.janelia.org/project-team/mouselight) at the Janelia Research Campus and other research institutions. This deployment uses Docker Swarm to orchestrate prebuilt containers available on Docker Hub.

Please note that this deployment does not currently have the capability of preprocessing raw data. Instead, it's assumed that imagery will be generated and preprocessed at Janelia and shipped to the remote site for viewing and tracing. These data preprocessing tools will be added in the future.

## Deployment Diagram

<div style="text-align:center"><img src="images/TwoServerDeployment.png" alt="Two-server Deployment Diagram" /></div>


## Hardware Setup

The JACS backend consists of several services which need to be deployed on server hardware. We have tested the following configuration:

* Two Dell PowerEdge R740XD Servers
    * Each server has 40 cores (e.g. Intel Xeon Gold 6148 2.4G)
    * Each server has 192 GB of memory
    * The hard drives are configured as follows:
        * 2 x 200GB SSD in RAID1 - Operating system (/)
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

## Download the installer

Download the installer and extract it onto the master node, as follows. `VERSION` should be set to the [latest stable version](https://github.com/JaneliaSciComp/jacs-cm/releases) available on the releases page.
```
export VERSION=<version_number_here>
cd /opt
sudo mkdir deploy
sudo chown $USER deploy
cd deploy
curl https://codeload.github.com/JaneliaSciComp/jacs-cm/tar.gz/$VERSION | tar xvz
ln -s jacs-cm-$VERSION jacs-cm
cd jacs-cm
```


## Configure The System

Next, create a `.env.config` file inside the intaller directory. This file defines the environment (usernames, passwords, etc.) You can copy the template to get started:
```
cp .env.template .env.config
vi .env.config
```

At minimum, you must customize the following:
1. Set `DEPLOYMENT` to **mouselight**.
2. Ensure that `REDUNDANT_STORAGE` and `NON_REDUNDANT_STORAGE` point to the disk mounts you used during the operating system installation. Alternatively, you can make symbolic links so that the default paths point to your mounted disks.
3. Set `HOST1` and `HOST2` to the two servers you are deploying on. Use fully-qualified hostnames here -- they should match the SSL certificate you intend to use.
4. Fill in all the unset passwords with >8 character passwords. You should only use alphanumeric characters, special characters are not currently supported.
5. Generate 32-byte secret keys for JWT_SECRET_KEY and MONGODB_SECRET_KEY.
6. If you want to enable automated error reporting from the Workstation client, set `MAIL_SERVER` to an SMTP server and port, e.g. smtp.my.org:25.


## Deploy Services

Now you can follow the [Swarm Deployment instructions](SwarmDeployment.md) to actually deploy the software.


## Mouselight Imagery

The data for MouseLight comes as a directory containing TIFF and KTX images organized into octrees. JACS compute includes a a service that can generate the octree data from a TIFF file. If there is more than 1 channel, the channels are numbered 0 .. n-s and each channel is expected to be in its own file. For example if you have 2 channels you would have two tiff files:

```
/path/to/volume/volume.0.tiff
/path/to/volume/volume.1.tiff
```

The current functionality is pretty basic and it assumes that the TIFF file contains the entire volume. The service also requires docker or singularity installed because the actual services are packaged in two docker containers - the first one that generates a TIFF octree and the second takes the TIFF octree and converts the octant channel images into the correspomding ktx blocks.

Currently pre-built containers for tiff octree tool and ktx tool are only available at Janelia's internal registry, but the containers build files are available at https://github.com/JaneliaSciComp/jacs-tools-docker.git in the 'tiff_octree' and 'ktx_octree' subdirectories, respectively. KTX tool container can also be built from https://github.com/JaneliaSciComp/pyktx.git.

Generating the sample octree requires only a JACS service call which is a simple HTTP REST call that can be done using curl or Postman. This service can also be invoked from the JACS dashboard http://api-gateway-host:8080 by going to the "Services List" after Login and selecting "lvDataImport". The dashboard should also offer a brief description of each argument.

curl invocation to run the service with singularity (this is the JACS default):

```
curl -X POST \
  https://api-gateway-host/SCSW/JACS2AsyncServices/v2/async-services/lvDataImport \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer Your_Token' \
  -d '{
	"args": [
		"-containerProcessor", "singularity",
		"-inputDir", "/path/to/volumeData",
		"-inputFilenamePattern", "test.{channel}.tif",
		"-outputDir", "/path/to/lvv/sampleData",
		"-channels", "0,1",
		"-levels", "4",
		"-voxelSize", "1,1,1",
		"-subtreeLengthForSubjobSplitting", 2,
        "-tiffOctreeContainerImage", "docker://registry.int.janelia.org/jacs-scripts/octree:1.0",
		"-ktxOctreeContainerImage", "docker://registry.int.janelia.org/jacs-scripts/pyktx:1.0"
	],
	"resources": {
	}
}
'
```

curl invocation to run the service with docker:
```
curl -X POST \
  https://api-gateway-host/SCSW/JACS2AsyncServices/v2/lvDataImport \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer Your_Token' \
  -d '{
	"args": [
		"-containerProcessor", "docker",
		"-inputDir", "/path/to/volumeData",
        "-inputFilenamePattern", "default.{channel}.tif",
		"-outputDir", "/path/to/lvv/sampleData",
		"-channels", "0",
		"-levels", "3",
		"-voxelSize", "1,1,1",
		"-subtreeLengthForSubjobSplitting", 3,
		"-tiffOctreeContainerImage", "registry.int.janelia.org/jacs-scripts/octree:1.0",
		"-ktxOctreeContainerImage", "registry.int.janelia.org/jacs-scripts/pyktx:1.0"
	],
	"resources": {
	}
}
'
```

### Arguments description:
* containerProcessor - which container runtime to use docker or singularity
* inputDir - path to original volume data
* inputFileNamePattern - original tiff name. Notice that if you have multiple channels and the channel is anywhere in the name you can use `{channel}` which will be replaced with the actual channel number.
* outputDir - where the octree will be generated - typically this is the sample data directory that will be imported in the workstation
* channels - specifies a list of all available channels, e.g. '0,1' if there are two channels or '0' if there is only 1 channel.
* levels - the number of octree levels. This is left up to the user and the service will not try to figure out the optimum value for the number of octree levels.
* voxelSize - specifies the voxel size in um. 
* tiffOctreeContainerImage - tiff octree container image. Not that the format is slightly different for specifying the image name if docker is used or if singularity is used. Since singularity supports docker images, if singularity runtime is used you need to explictily specify that the image is a docker image.
* ktxOctreeContainerImage - ktx octree container image. See above regarding the format based on container processor type.
* subtreeLengthForSubjobSplitting - this parameter applies only for the ktx processor and it tells the service how to split the job and it has a default value of 5. The conversion process typically starts at a certain node and it performs tiff to ktx conversion for a specified number of levels. If you start a process at the root and convert all levels the job may take a while so if you want you have the option to parallelize it by going only for a limited number of levels from the root and start new jobs from all nodes at the level equal with the subtree depth. For example if you have 8 levels and you set `subtreeLengthForSubjobSplitting` to `3` then KTX conversion will start `1 + 8^3 + 8^6 = 1 + 512 + 262144 = 262657` jobs with the following parameters:
`"" 3, "111" 3, "112" 3, ..., "118" 3, ..., "888" 3, ..., "111111" 3, ..., "888888" 3`
If you leave the default (`subtreeLengthForSubjobSplitting=5`) then the KTX conversion will start only `1 + 8^5 = 32769` jobs (`"11111" 5, ..., "88888" 5`)

Note that the service invocation requires authentication so before you invoke it, you need to obtain an JWS token from the authentication service.

## Import Imagery

You should place each sample in $DATA_DIR/jacsstorage/samples on one of the servers. If you place the sample on the first server, in `$DATA_DIR/jacsstorage/samples/<sampleDirectoryName>`, then in the Workstation you will refer to the sample as `/jade1/<sampleDirectoryName>`. As a side note if you use 'lvDataImport' service to generate the imagery, the service does not use JADE to persist the data. So if you need the data to be on a storage that is only accessible on certain hosts, JACS must run on that host in order to be able to write the data to the corresponding location. If that is not an option you can generate the data to a temporary location then move it to the intended sample directory.

In the Workstation, select **File** → **New** → **Tiled Microscope Sample**, and then set "Sample Name" to `<sampleDirectoryName>` and "Path to Render Folder" as `/jade1/<sampleDirectoryName>`.

Open the Data Explorer (**Window** → **Core** → **Data Explorer**) and navigate to Home, then "3D RawTile Microscope Samples", and your sample name. Right-click the sample and choose "Open in Large Volume Viewer". The 2D imagery should load into the middle panel. You should be able to right-click anywhere on the image and select "Navigate to This Location in Horta (channel 1)", to load the 3D imagery.


## Find More Information

This concludes the MouseLight Workstation installation procedure. Further information on using the tools can be found in the [Janelia Workstation User Manual](https://github.com/JaneliaSciComp/workstation/blob/master/docs/UserManual.md).

