
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

