bucketName=$1
s3fs ${bucketName} /data/s3/${bucketName} -o allow_other,uid=$(id -u jacs),gid=$(id -g jacs)