# Managing Storage Volumes

The Workstation/JACS system relies on JADE for its storage API.

## Adding a new Storage Volume

**Add bootstrap to the JADE configuration**

On HOST1, edit /opt/jacs/config/jade/config.properties and add a block for your new volume, for example:
```
StorageVolume.s3data.RootDir=/s3data
StorageVolume.s3data.VirtualPath=/s3jade
StorageVolume.s3data.Shared=true
StorageVolume.s3data.Tags=aws,cloud
StorageVolume.s3data.VolumePermissions=READ,WRITE,DELETE
```

The properties configure the volume as follows:
* RootDir: defines the actual path to the data on disk
* VirtualPath: optionally defines a virtual path which is mapped to the actual path
* Shared: true if the volume should be accessible to all volumes
* Tags: tags used by applications to find appropriate volumes
* VolumePermissions: list of operations that JADE can execute (READ,WRITE,DELETE)

Also add your volume to StorageAgent.BootstrappedVolumes, so that it will be created the next time the service is restarted.

**Mount the path into the containers**

Edit the compose/swarm files for your deployment and mount the volume path as a Docker volume. For example, if your `DEPLOYMENT` is jacs, and `STAGE` is dev, you must edit these two files:

`deployments/jacs/docker-compose.dev.yml`
`deployments/jacs/docker-swarm.dev.yml`

You should add your volume for all services `jade-agent<N>` which you want to service that volume.

For example:
```yaml
  jade-agent1:
    volumes:
      - /data/s3data:/s3data:shared
```

Restart the stack after making the changes above and the volume will be created when the JADE worker starts.

## Host-specific Volumes

By default, all JADE agents are configured to serve all volumes in the database. You can use `StorageAgent.ServedVolumes` to control which volumes are served by which hosts.

