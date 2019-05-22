
# Troubleshooting

Useful commands for troubleshooting the Swarm-based deployment:

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

## GUI

If you would like to see the swarm's status in a web-based GUI, we recommend installing [Swarmpit](https://swarmpit.io). It's a single command to deploy, and it works well with the JACS stack.

