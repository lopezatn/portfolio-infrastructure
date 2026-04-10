# Portfolio Server Runbook

## Overview
This instance serves a static website through an nginx server, and a REST API for checking the status of its Docker containers.

## Components
- **portfolio-nginx**: Docker container running the nginx web server, serves the portfolio frontend over HTTPS.
- **health-check-api**: Docker container serving a Flask REST API that checks the status of Docker containers.

## Prerequisites
1. Docker running (`systemctl status docker`)
2. `portfolio-network` Docker network created
3. Frontend files at `/home/ssm-user/portfolio-frontend/dist/`
4. nginx config at `/home/ssm-user/nginx.conf`
5. SSL certificates at `/etc/letsencrypt/`

## Setup

### Create Docker network
```bash
docker network create portfolio-network
```

### Run nginx container
```bash
docker run -d --name portfolio-nginx \
    -v /home/ssm-user/portfolio-frontend/dist:/usr/share/nginx/html \
    -v /home/ssm-user/nginx.conf:/etc/nginx/conf.d/default.conf \
    -v /etc/letsencrypt:/etc/letsencrypt \
    -p 80:80 \
    -p 443:443 \
    --network portfolio-network \
    --restart unless-stopped \
    nginx:alpine
```

### Deploy health-check-api
Deployed automatically via GitHub Actions CI/CD pipeline on push to master branch.
To trigger manually: go to health-check-api repo -> Actions -> "Health check rest-api container updater" -> Run workflow.

## Recovery

### Disk full
1. Check disk usage: `df -h /`
2. Find what's consuming space: `sudo du -sh /* 2>/dev/null | sort -rh | head -10`
3. Clean Docker if running: `docker system prune -a`
4. If Docker is not running, full reset:
```bash
sudo systemctl stop docker
sudo rm -rf /var/lib/docker
sudo systemctl start docker
```
5. Redeploy containers via CI pipeline after reset.

### Docker not starting
1. Check logs:
```bash
sudo journalctl -u docker.service --no-pager | tail -30
```
2. If disk full, follow the Disk full procedure above.

### Containers not running after reboot
1. Check Docker status: `systemctl status docker`
2. List all containers: `docker container ls --all`
3. Start a stopped container: `docker start <container_name>`
4. If containers fail to start, follow the Docker not starting procedure above.

### SSM Session Manager not working
1. Go to AWS Console -> Systems Manager -> Run Command
2. Select `AWS-RunShellScript`
3. Target your instance manually
4. Run diagnostic commands from there

## Testing
```bash
curl "http://lopezberg.dev:5000/container-health?container=portfolio-nginx"
```
Expected response: `The container is running.`
