#!/bin/bash
if [[ $JWT_SECRET ]]; then
    echo "Using JWT_SECRET from environment"
elif [[ -e /app/jwt_secret ]]; then
    export JWT_SECRET=`cat /app/jwt_secret`
    echo "Using JWT_SECRET from /app/jwt_secret"
else
    echo "You must define a JWT secret either as an env variable (JWT_SECRET) or in a mounted file (/app/jwt_secret)"
fi
npm start
