# Skill: n8n Update (Docker + PostgreSQL)

Safe update of n8n running in Docker with PostgreSQL backend.

## Prerequisites

- SSH access to the server (key-based auth)
- n8n running via Docker Compose
- PostgreSQL as the database backend
- Docker Compose file at `/opt/n8n/docker-compose.yml`

## Steps

### 1. Gather Information

Before updating, collect current state:

```bash
# OS and resources
ssh root@SERVER "uname -a && df -h / && free -h"

# Current n8n version and container status
ssh root@SERVER "docker ps --filter name=n8n --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"

# Docker Compose config
ssh root@SERVER "cat /opt/n8n/docker-compose.yml"

# PostgreSQL status and DB size
ssh root@SERVER "systemctl status postgresql | head -5 && sudo -u postgres psql -c \"SELECT pg_size_pretty(pg_database_size('n8n_db'));\""
```

### 2. Backup Database

```bash
ssh root@SERVER "mkdir -p /opt/n8n/backups && sudo -u postgres pg_dump n8n_db > /opt/n8n/backups/n8n_db_\$(date +%Y%m%d_%H%M%S).sql"
```

Verify backup was created and check size.

### 3. Backup Docker Volume

```bash
ssh root@SERVER "docker run --rm -v n8n_data:/data -v /opt/n8n/backups:/backup alpine tar czf /backup/n8n_data_\$(date +%Y%m%d_%H%M%S).tar.gz -C /data ."
```

### 4. Pull New Stable Image

```bash
ssh root@SERVER "docker pull n8nio/n8n:stable"
```

### 5. Update docker-compose.yml

Ensure the image tag is set to `stable`:

```bash
ssh root@SERVER "sed -i 's|image: n8nio/n8n:.*|image: n8nio/n8n:stable|' /opt/n8n/docker-compose.yml"
```

### 6. Recreate Container

```bash
ssh root@SERVER "cd /opt/n8n && docker compose down && docker compose up -d"
```

### 7. Verify

Wait 10-15 seconds, then check:

```bash
# Container status
ssh root@SERVER "docker ps --filter name=n8n"

# Logs — check for errors and activated workflows
ssh root@SERVER "docker logs n8n --tail 30"

# HTTP health check
ssh root@SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:5678/"
```

Expected: HTTP 200, all workflows activated, no errors in logs.

### 8. Cleanup

```bash
# Remove old images
ssh root@SERVER "docker image prune -f"

# Remove backups older than 30 days
ssh root@SERVER "find /opt/n8n/backups -name '*.sql' -mtime +30 -delete && find /opt/n8n/backups -name '*.tar.gz' -mtime +30 -delete"
```

## Automated Script

An update script is available at `/opt/n8n/update.sh` on the server. Run:

```bash
ssh root@SERVER "bash /opt/n8n/update.sh"
```

The script performs all steps above automatically with colored output and error handling.

## Rollback

If something goes wrong after update:

```bash
# Restore database
ssh root@SERVER "sudo -u postgres psql -c 'DROP DATABASE n8n_db;' && sudo -u postgres psql -c 'CREATE DATABASE n8n_db OWNER n8n_user;' && sudo -u postgres psql n8n_db < /opt/n8n/backups/n8n_db_TIMESTAMP.sql"

# Restore volume
ssh root@SERVER "docker run --rm -v n8n_data:/data -v /opt/n8n/backups:/backup alpine sh -c 'rm -rf /data/* && tar xzf /backup/n8n_data_TIMESTAMP.tar.gz -C /data'"

# Revert image in docker-compose.yml to previous version
ssh root@SERVER "sed -i 's|image: n8nio/n8n:.*|image: n8nio/n8n:PREVIOUS_VERSION|' /opt/n8n/docker-compose.yml"

# Recreate container
ssh root@SERVER "cd /opt/n8n && docker compose down && docker compose up -d"
```
