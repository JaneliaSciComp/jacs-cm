bucketName=$1
mkdir -p /data/s3/${bucketName}
s3fs ${bucketName} /data/s3/${bucketName} -o allow_other,uid=$(id -u jacs),gid=$(id -g jacs)
