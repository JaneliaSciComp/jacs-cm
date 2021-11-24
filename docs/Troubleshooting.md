
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

