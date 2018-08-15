#!/bin/sh
if [[ -z $JWT_SECRET ]]; then
    export JWT_SECRET=`cat /app/jwt_secret`
    echo "Using JWT_SECRET from /app/jwt_secret"
else
    echo "Using JWT_SECRET from environment"
fi
echo "Using NGINX_SERVERNAME=$NGINX_SERVERNAME"
/usr/bin/openresty -g "daemon off;"
