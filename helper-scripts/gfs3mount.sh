bucketName=$1
goofys -o allow_other --uid $(id -u jacs) --gid $(id -g jacs) ${bucketName} /data/s3/gfs3/${bucketName}
