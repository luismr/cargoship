# cargoship

[![Docker](https://img.shields.io/badge/Docker-28.1.x-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2.36.x-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Traefik](https://img.shields.io/badge/Traefik-3.4.x-1F2937?style=for-the-badge&logo=traefik&logoColor=white)](https://traefik.io/)
[![Certbot](https://img.shields.io/badge/Certbot-4.1.x-2E8B57?style=for-the-badge&logo=letsencrypt&logoColor=white)](https://certbot.eff.org/)
[![Let's Encrypt](https://img.shields.io/badge/Let's%20Encrypt-SSL-003A70?style=for-the-badge&logo=letsencrypt&logoColor=white)](https://letsencrypt.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

`cargoship` is a template for deploying multiple Docker containers with a Traefik-based load balancer and built-in SSL support. It is designed for easy scaling, secure traffic management, and rapid prototyping.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Features](#features)
3. [Getting Started](#getting-started)
4. [Configuration](#configuration)
    - [Environment Variables (.env file)](#environment-variables-env-file)
    - [Traefik Load Balancer](#traefik-load-balancer)
    - [docker-compose.yml](#docker-composeyml)
    - [Traefik Configuration](#traefik-configuration)
    - [SSL Certificates](#ssl-certificates)
5. [Scaling Services](#scaling-services)
6. [Accessing the Traefik Dashboard](#accessing-the-traefik-dashboard)
7. [References & Further Reading](#references--further-reading)

---

## Project Structure

```
cargoship/
├── .gitignore
├── README.md
├── docker-compose.yml
├── config/
│   ├── traefik/
│   │   ├── traefik.yml
│   │   └── traefik_dynamic.yml
│   └── certs/
```

- **.gitignore**: Ignores files and directories you don't want in version control (e.g., temporary certificate folders).
- **docker-compose.yml**: Main stack definition.
- **config/traefik/**: Traefik static and dynamic configuration files.
- **config/certs/**: Place your SSL certificates here.

---

## Features

- **Traefik Load Balancer** with automatic HTTPS (SSL) support.
- **Dynamic Service Scaling** using Docker Compose.
- **Easy SSL Certificate Management** (manual or with Let's Encrypt).
- **Traefik Dashboard** for monitoring and debugging.

---

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone git@github.com:luismr/cargoship.git
   cd cargoship
   ```

2. **Add your SSL certificates:**
   - Place `fullchain.pem` and `privkey.pem` in `config/certs/`.
   - Or, use Let's Encrypt (see below).

3. **Start the stack:**
   ```bash
   docker-compose up -d
   ```

---

## Configuration

### Environment Variables (.env file)

This template uses environment variables to configure Docker images and behavior. **Docker Compose requires the file to be named exactly `.env`** - it does not support other naming patterns like `.env.local` or `.env.dev`.

Copy the example file and customize it for your environment:

```bash
cp .env-example .env
```

> **Important**: The `.env` file is ignored by Git (added to `.gitignore`) to prevent accidentally committing sensitive configuration data to version control. This ensures your local environment settings don't contaminate other deployment environments.

#### Available Configuration Options:

**Environment Type:**
- `CARGOSHIP_ENV`: Set your environment type (prod, stage, qa, local)

**Docker Image Configuration:**
For Apple Silicon Machines, AWS Graviton, or other ARM64 machines, you may need to set images compatible with your environment:

- `IMAGE_TRAEFIK`: Traefik image (default: `traefik:3.4`)
- `IMAGE_WHOAMI`: Whoami service image (default: `traefik/whoami:latest`)

**Traefik Configuration:**
- `TRAEFIK_CERTS_PATH`: Custom path for SSL certificates (default: `./config/certs`)


#### Example .env file (based on .env-example):
```bash
# your environment type: prod, stage, qa, local ...
CARGOSHIP_ENV=local

# for Apple Silicon Machines, AWS Graviton, or other ARM64 machines
# you have to set images compatible to your environment 
# for example:
# IMAGE_TRAEFIK=traefik:3.4
# IMAGE_WHOAMI=traefik/whoami:v1.10.0

# Traefik configuration
# TRAEFIK_CERTS_PATH=./config/certs
```

### Traefik Load Balancer

Traefik acts as a reverse proxy and load balancer that automatically manages HTTP and HTTPS connections for your services. It provides:

- **Automatic SSL/TLS termination** using your certificates
- **Service discovery** through Docker labels
- **Load balancing** across multiple service instances
- **Real-time configuration** without restarts
- **Dashboard** for monitoring and debugging (available on port 8080)

#### How Traefik Works

1. **Entry Points**: Traefik listens on ports 80 (HTTP) and 443 (HTTPS)
2. **Service Discovery**: Automatically detects services with Traefik labels
3. **Routing**: Routes requests based on hostnames and paths defined in labels
4. **SSL Termination**: Handles HTTPS certificates and forwards decrypted traffic to services
5. **Load Balancing**: Distributes traffic across multiple service instances

#### Docker Integration & Automatic Service Discovery

Traefik integrates directly with Docker through the Docker socket (`/var/run/docker.sock`) to automatically discover and configure services. This integration enables:

**Real-time Service Discovery:**
- Traefik monitors Docker events in real-time
- When a container starts with Traefik labels, it's automatically added to the routing table
- When a container stops, it's automatically removed from routing
- No manual configuration or restarts required

**Automatic Load Balancing:**
- When you scale a service (e.g., `docker-compose up -d --scale whoami=3`), Traefik automatically detects new instances
- Traffic is automatically distributed across all running instances
- Health checks ensure only healthy containers receive traffic

**Label-based Configuration:**
```yaml
# Docker Compose automatically mounts the Docker socket
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro

# Services are discovered through labels
labels:
  - "traefik.enable=true"                                    # Enable service discovery
  - "traefik.http.routers.service-name.rule=Host(`domain.com`)"  # Routing rule
  - "traefik.http.services.service-name.loadbalancer.server.port=8080" # Service port
```

**Benefits of Docker Integration:**
- **Zero-downtime deployments**: New containers are added before old ones are removed
- **Automatic failover**: Unhealthy containers are automatically removed from the load balancer
- **Dynamic scaling**: Scale services up/down without configuration changes
- **Service mesh**: All services can communicate through Traefik's internal network

#### Configuring Services for Traefik

To make a service available through Traefik, add these labels to your service in `docker-compose.yml`:

```yaml
labels:
  - "traefik.enable=true"                                    # Enable Traefik for this service
  - "traefik.http.routers.service-name.rule=Host(`your-domain.com`)"  # Route by hostname
  - "traefik.http.routers.service-name.entrypoints=websecure"         # Use HTTPS entrypoint
  - "traefik.http.routers.service-name.tls=true"                      # Enable TLS/SSL
  - "traefik.http.services.service-name.loadbalancer.server.port=8080" # Service port
```

#### Example Service Configuration

Here's how the `whoami` service is configured in this template:

```yaml
whoami:
  image: traefik/whoami:latest
  labels:
    - "traefik.enable=true"  
    - "traefik.http.routers.whoami.rule=Host(`test.example.com`)"       
    - "traefik.http.routers.whoami.entrypoints=websecure"              
    - "traefik.http.routers.whoami.tls=true"                           
    - "traefik.http.services.whoami.loadbalancer.server.port=80"       
```

This configuration:
- Enables Traefik routing for the service
- Routes requests for `test.example.com` to this service
- Uses HTTPS (port 443) with SSL/TLS encryption
- Forwards traffic to the service's internal port 80

#### Traefik Dashboard

Access the Traefik dashboard at [http://localhost:8080](http://localhost:8080) to:
- Monitor service health and status
- View routing rules and configurations
- Debug connection issues
- See real-time traffic statistics

> **Note**: The dashboard is enabled by default for local development. For production, consider securing it with authentication.

### docker-compose.yml

- **traefik**: The load balancer, exposes ports 80 (HTTP), 443 (HTTPS), and 8080 (dashboard).
- **whoami**: Example service, routed via Traefik.
- **networks**: All services are attached to the `cargoship` bridge network.

### Traefik Configuration

- **config/traefik/traefik.yml**: Static config (entrypoints, providers, logging, dashboard).
- **config/traefik/traefik_dynamic.yml**: Dynamic config (TLS certificates).

### SSL Certificates

- Place your SSL certificates in `config/certs/` as:
  - `fullchain.pem`
  - `privkey.pem`
- Traefik will automatically use these for HTTPS.
- You can customize the certificates path by setting the `TRAEFIK_CERTS_PATH` environment variable:
  ```bash
  export TRAEFIK_CERTS_PATH=/path/to/your/certificates
  docker-compose up -d
  ```

#### Using Let's Encrypt

You can use Let's Encrypt to generate SSL certificates. First, install Certbot following the [official instructions](https://certbot.eff.org/instructions?ws=other&os=pip), then use one of these methods:

**Method 1: Manual DNS Challenge (Recommended for servers without public HTTP access)**

```bash
sudo certbot certonly --manual --preferred-challenges dns \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  --domains example.com \
  --domains www.example.com
```

**Method 2: Standalone (if web server is not running)**

```bash
sudo certbot certonly --standalone \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  --domains example.com \
  --domains www.example.com
```

**Method 3: Webroot (if web server is already running)**

```bash
sudo certbot certonly --webroot \
  --webroot-path /path/to/your/website \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  --domains example.com \
  --domains www.example.com
```

After obtaining the certificates, copy the resulting `fullchain.pem` and `privkey.pem` from `/etc/letsencrypt/live/<domain>/` to your certificates directory:

**Using default path (`config/certs/`):**
```bash
sudo cp /etc/letsencrypt/live/example.com/fullchain.pem config/certs/
sudo cp /etc/letsencrypt/live/example.com/privkey.pem config/certs/
sudo chown $USER:$USER config/certs/*.pem
```

**Using custom path (if you set `TRAEFIK_CERTS_PATH`):**
```bash
export TRAEFIK_CERTS_PATH=/path/to/your/certificates
sudo cp /etc/letsencrypt/live/example.com/fullchain.pem $TRAEFIK_CERTS_PATH/
sudo cp /etc/letsencrypt/live/example.com/privkey.pem $TRAEFIK_CERTS_PATH/
sudo chown $USER:$USER $TRAEFIK_CERTS_PATH/*.pem
```

#### Automated Certificate Renewal

This template includes an automated certificate renewal script that can be scheduled with crontab to ensure your SSL certificates stay up-to-date.

**Using the Renewal Script:**

1. **Customize the script** (`scripts/update-certs.sh`):
   ```bash
   # Update these variables in the script
   DOMAIN="your-domain.com"
   TARGET_DIR="/path/to/your/certificates"
   CARGOSHIP_HOME="/path/to/your/cargoship/directory"
   ```

2. **Make the script executable**:
   ```bash
   chmod +x scripts/update-certs.sh
   ```

3. **Test the script manually**:
   ```bash
   sudo ./scripts/update-certs.sh
   ```

4. **Schedule automatic renewal** with crontab:
   ```bash
   # Edit crontab as root
   sudo crontab -e
   
   # Add this line to run renewal twice daily (recommended by Let's Encrypt)
   0 0,12 * * * /path/to/cargoship/scripts/update-certs.sh >> /var/log/cert-renewal.log 2>&1
   ```

**How the Script Works:**

1. **Certificate Renewal**: Uses `certbot renew --quiet --standalone` to attempt renewal
2. **Smart Copying**: Only copies certificates if they're newer than existing ones
3. **Automatic Restart**: Optionally restarts Traefik to pick up new certificates
4. **Logging**: Provides clear feedback about what actions were taken

**Script Features:**
- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Efficient**: Only copies certificates when needed
- ✅ **Logging**: Clear output for monitoring
- ✅ **Docker Integration**: Can restart Traefik automatically
- ✅ **Error Handling**: Uses `set -euo pipefail` for robust execution

**Monitoring Renewal:**
```bash
# Check renewal logs
tail -f /var/log/cert-renewal.log

# Check certificate expiration
openssl x509 -in config/certs/fullchain.pem -text -noout | grep "Not After"
```

> **Important**: Ensure your domain's DNS points to the server where this script runs, as Let's Encrypt needs to verify domain ownership during renewal.

---

## Scaling Services

You can scale any dynamic service (like `whoami`) with:

```bash
docker-compose up -d --scale whoami=3
```

Or, using the legacy command:

```bash
docker-compose scale whoami=3
```

---

## Accessing the Traefik Dashboard

- Visit: [http://localhost:8080](http://localhost:8080)
- The dashboard is enabled by default for local development.

---

## References & Further Reading

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Let's Encrypt / Certbot](https://certbot.eff.org/)
- [Traefik Dashboard](https://doc.traefik.io/traefik/operations/dashboard/)
- [License](LICENSE.md) - MIT License