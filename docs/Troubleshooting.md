
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

