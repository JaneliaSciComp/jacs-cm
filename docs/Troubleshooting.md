
# Troubleshooting

## Docker

These are some useful commands for troubleshooting Docker:

View logs for Docker daemon
```
sudo journalctl -fu docker
```

Restart the Docker daemon
```
sudo systemctl restart docker
```

Remove all Docker objects, including unused containers/networks/etc.
```
sudo docker system prune -a
```

## Swarm GUI

If you would like to see the Swarm's status in a web-based GUI, we recommend installing [Swarmpit](https://swarmpit.io). It's a single command to deploy, and it works well with the JACS stack.


## Common issues

### config variable not set

If you see a lot of errors or warnings similar to the ones below, first check that the `.env` file was generated correctly - it should have all environment variables from .env.config, present and set. If it is not just remove it and try the commands again. It is possible that you may have run a command like `./manage.sh init-filesystems` before the swarm cluster was available.

```
WARN[0000] The "CONFIG_DIR" variable is not set. Defaulting to a blank string.
WARN[0000] The "DATA_DIR" variable is not set. Defaulting to a blank string.
WARN[0000] The "DB_DIR" variable is not set. Defaulting to a blank string.
WARN[0000] The "BACKUPS_DIR" variable is not set. Defaulting to a blank string.
WARN[0000] The "CERT_SUBJ" variable is not set. Defaulting to a blank string.
WARN[0000] The "DEPLOYMENT" variable is not set. Defaulting to a blank string.
WARN[0000] The "MONGODB_SECRET_KEY" variable is not set. Defaulting to a blank string.
WARN[0000] The "API_GATEWAY_EXPOSED_HOST" variable is not set. Defaulting to a blank string.
WARN[0000] The "RABBITMQ_EXPOSED_HOST" variable is not set. Defaulting to a blank string.
WARN[0000] The "RABBITMQ_USER" variable is not set. Defaulting to a blank string.
WARN[0000] The "RABBITMQ_PASSWORD" variable is not set. Defaulting to a blank string.
WARN[0000] The "MAIL_SERVER" variable is not set. Defaulting to a blank string.
WARN[0000] The "NAMESPACE" variable is not set. Defaulting to a blank string.
WARN[0000] The "REDUNDANT_STORAGE" variable is not set. Defaulting to a blank string.
WARN[0000] The "REDUNDANT_STORAGE" variable is not set. Defaulting to a blank string.
WARN[0000] The "NON_REDUNDANT_STORAGE" variable is not set. Defaulting to a blank string.
WARN[0000] The "NON_REDUNDANT_STORAGE" variable is not set. Defaulting to a blank string.
```

### "network not found"

If you see an intermittent error like this, just retry the command again:
```
failed to create service jacs-cm_jacs-sync: Error response from daemon: network jacs-cm_jacs-net not found
```

### bind errors during init-filesystems

If during `init-filesystems` you see an error that the config folder could not be bound on a particular node of the swarm cluster, make sure you did not forget to create the config and db directories on each node that is part of the swarm. The directories must exist in order for docker to be able to mount the corresponding volumes.
After you created all folders if you already ran `./manage.sh init-filesystems` and it failed before you run it again stop it using
```
./manage.sh stop
```
and then you can try to re-run it

## RESTful services

You can access the RESTful services from the command line. Obtain a JWT token like this:

```
./manage.sh login
```

The default admin account is called "root" with password "root" for deployments with self-contained authentication.

Now you can access any of the RESTful APIs on the gateway, for instance:

```
export TOKEN=<enter token here>
curl -k --request GET --url https://${API_GATEWAY_EXPOSED_HOST}/SCSW/JACS2AsyncServices/v2/services/metadata --header "Content-Type: application/json" --header "Authorization: Bearer $TOKEN"
```

