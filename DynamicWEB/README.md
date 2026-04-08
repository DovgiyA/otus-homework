# LibreSpeed Development Deployment

Self-hosted speed test application deployed via Vagrant + Ansible + Docker Compose + Nginx on VMware Fusion (M1/M2 Mac).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      macOS Host                              │
│  ┌─────────────────┐     ┌──────────────────────────────┐  │
│  │ Docker Desktop  │     │        Vagrantfile           │  │
│  │ (ARM64 native)  │     │  bento/ubuntu-22.04 ARM64    │  │
│  │                 │     │  4CPU / 4GB RAM              │  │
│  │ docker build    │     │  192.168.56.10               │  │
│  │ docker save     │     └──────────┬───────────────────┘  │
│  │ scp image ──────┼─────────────────┘                      │
│  └─────────────────┘                  │                     │
└───────────────────────────────────────│─────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Ubuntu 22.04 VM                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Nginx     │  │   Docker    │  │   Docker Compose    │  │
│  │   :80/:443  │  │   Engine    │  │                     │  │
│  │   proxy ────┼──►             │  │  ┌───────────────┐  │  │
│  │             │  │             │  │  │ librespeed   │  │  │
│  │  - gzip     │  │             │  │  │ :8080        │  │  │
│  │  - SSL      │  │             │  │  │ (PHP/Apache) │  │  │
│  │  - rate     │  │             │  │  └───────────────┘  │  │
│  │    limiting │  │             │  │  ┌───────────────┐  │  │
│  └─────────────┘  │             │  │  │ postgres:15   │  │  │
│                   │             │  │  │ :5432        │  │  │
│                   │             │  │  │ (telemetry)  │  │  │
│                   │             │  │  └───────────────┘  │  │
│                   └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **macOS** with Apple Silicon (M1/M2/M3)
- **VMware Fusion** Pro or Player (ARM64 support)
- **Vagrant** with VMware plugin: `vagrant plugin install vagrant-vmware-desktop`
- **Docker Desktop** (running, for building ARM64 image)
- **Ansible** on host: `pip3 install ansible`

## Quick Start

```bash
# 1. Start VM and provision
vagrant up --provision

# 2. Access speed test
open http://192.168.56.10

# 3. Check telemetry results (after running test)
vagrant ssh -c "docker exec postgres psql -U speed_user -d librespeed -c 'SELECT * FROM speedtest_users;'"
```

## Directory Structure

```
deployment/
└── ansible/
    ├── inventory.ini          # SSH connection config (127.0.0.1:2222)
    ├── playbook.yml           # Main playbook with vars
    └── roles/
        ├── common/
        │   └── tasks/main.yml     # Base packages, timezone
        ├── docker/
        │   └── tasks/main.yml     # Docker Engine + Compose v2
        ├── app-config/
        │   ├── tasks/main.yml     # Build, transfer, deploy
        │   └── templates/
        │       └── docker-compose.yml.j2
        └── nginx/
            ├── tasks/main.yml     # Install, SSL, config
            ├── handlers/main.yml  # Reload handler
            └── templates/
                └── librespeed.conf.j2
```

## Ansible Roles

### common
- Updates apt cache
- Installs base packages (curl, ca-certificates, gnupg, etc.)
- Enables systemd-timesyncd
- Sets timezone to UTC

### docker
- Removes legacy Docker packages
- Adds Docker GPG key and repository (ARM64)
- Installs Docker Engine + Compose v2 plugin
- Adds vagrant user to docker group

### app-config
- Builds Docker image on host (ARM64 native)
- Saves image to tar, transfers via scp to VM
- Loads image on VM
- Deploys docker-compose.yml
- Initializes PostgreSQL telemetry schema
- Starts containers

### nginx
- Installs Nginx
- Generates self-signed SSL certificate
- Configures reverse proxy to librespeed:8080
- Rate limiting: 100r/m download, 50r/m upload
- Gzip compression
- CORS headers

## Configuration

### Environment Variables (docker-compose.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| MODE | standalone | Server mode |
| TELEMETRY | true | Enable result storage |
| WEBPORT | 8080 | Container port |
| TITLE | LibreSpeed Test | Page title |
| PASSWORD | admin123 | Stats page password |
| DB_TYPE | postgresql | Database type |
| DB_HOSTNAME | postgres | Database host |
| DB_NAME | librespeed | Database name |
| DB_USERNAME | speed_user | Database user |
| DB_PASSWORD | secure_password_here | Database password |

### Playbook Variables

Edit `deployment/ansible/playbook.yml`:

```yaml
vars:
  app_dir: /opt/librespeed      # App directory on VM
  db_password: "YOUR_PASSWORD"  # Change this!
  db_user: "speed_user"
  db_name: "librespeed"
  app_port: 8080
  server_ip: "192.168.56.10"
  project_root: /Users/a1/otus-homework/DynamicWEB  # Local path
```

## Endpoints

| Endpoint | Description |
|----------|-------------|
| `/` | Speed test UI |
| `/backend/garbage.php` | Download test |
| `/backend/empty.php` | Upload + Ping test |
| `/backend/getIP.php` | IP detection |
| `/results/` | Telemetry stats (password protected) |
| `/results/stats.php` | Statistics page |

## Operations

### SSH to VM
```bash
vagrant ssh
```

### View container logs
```bash
vagrant ssh -c "docker logs librespeed -f"
```

### Restart containers
```bash
vagrant ssh -c "cd /opt/librespeed && docker compose restart"
```

### Rebuild image (after code changes)
```bash
# On host
docker build -t librespeed:latest .
docker save -o /tmp/librespeed.tar librespeed:latest

# Transfer to VM
scp -F <(vagrant ssh-config) /tmp/librespeed.tar default:/tmp/

# On VM
vagrant ssh -c "docker load -i /tmp/librespeed.tar && cd /opt/librespeed && docker compose up -d"
```

### Check database
```bash
vagrant ssh -c "docker exec postgres psql -U speed_user -d librespeed -c '\\dt'"
```

### View Nginx status
```bash
vagrant ssh -c "sudo systemctl status nginx"
```

## Troubleshooting

### exec format error
**Cause:** Image built for wrong architecture
**Fix:** Ensure Docker Desktop is running on ARM64 Mac, rebuild image locally

### Container unhealthy
**Check logs:**
```bash
vagrant ssh -c "docker logs librespeed"
```

### Database connection failed
**Verify PostgreSQL is running:**
```bash
vagrant ssh -c "docker exec postgres pg_isready -U speed_user"
```

### Nginx 502 Bad Gateway
**Check if librespeed container is running:**
```bash
vagrant ssh -c "docker ps"
```

### SSH connection refused
**Restart VM:**
```bash
vagrant reload
```

## Clean Up

```bash
# Stop and remove VM
vagrant halt
vagrant destroy

# Remove docker image from host
docker rmi librespeed:latest
```

## Security Notes

- Default database password should be changed in production
- Self-signed SSL certificates are for development only
- For production, use Let's Encrypt with Certbot
- Stats page (`/results/`) is password protected

## References

- [LibreSpeed Documentation](https://github.com/librespeed/speedtest)
- [Docker Image Docs](../doc_docker.md)
- [Development Guide](../DEVELOPMENT.md)
