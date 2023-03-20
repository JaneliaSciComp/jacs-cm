bucketName=$1
mkdir -p /data/s3/${bucketName}
s3fs ${bucketName} /data/s3/${bucketName} -o allow_other,multireq_max=500,uid=$(id -u jacs),gid=$(id -g jacs)
