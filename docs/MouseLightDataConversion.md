# Mouselight Data Conversion

In principle, any 3d volumetric data can be imported into the MouseLight Workstation. 
We provide some basic tools for converting TIFF format images into the expected format on disk.

The imagery for MouseLight Workstation is a directory containing TIFF and KTX images organized into octrees. JACS compute includes a a service that can generate the octree data from a TIFF file. If there is more than 1 channel, the channels are numbered 0 .. n-s and each channel is expected to be in its own file. For example if you have 2 channels you would have two tiff files:

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

Note that the service invocation requires authentication so before you invoke it, you need to obtain an JWS token from the authentication service - see [Verify Functionality part from SwarmDeployment.md document](SwarmDeployment.md).
