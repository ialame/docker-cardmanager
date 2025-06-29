# 🚀 Deployment Guide - CardManager

## 📋 Overview

CardManager is a multi-service application consisting of:
- **GestionCarte** : Main web application (port 8080)
- **Painter** : Image management service (port 8081)
- **Mason** : Common library (internal services)
- **MariaDB** : Database (configurable)

## 🎯 Deployment Modes

### 1. **Development Mode** (included database)
For testing/developing with a containerized MariaDB database

### 2. **Production Mode** (external database)
For deployment with your own database

---

## 🛠️ Prerequisites

### Required Environment
- **Docker** >= 20.10
- **Docker Compose** >= 2.0
- **Git** (for cloning repositories)
- **Free Ports** : 8080, 8081, 3307 (development)

### Pre-deployment Checks
```bash
# Check Docker
docker --version
docker-compose --version

# Check free ports
netstat -tuln | grep -E "(8080|8081|3307)"
```

---

## 🔧 Git Configuration

### Option 1: Automatic Configuration (recommended)
```bash
# Launch configuration assistant
chmod +x scripts/configure-git.sh
./scripts/configure-git.sh
```

### Option 2: Manual Configuration
```bash
# Copy template
cp .env.template .env

# Edit with your values
nano .env
```

### Configuration Example
```bash
MASON_REPO_URL=https://github.com/ialame/mason
PAINTER_REPO_URL=https://github.com/ialame/painter
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main
GIT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 🚀 Development Mode Deployment

### Step 1: Configuration
```bash
# Clone project
git clone <PROJECT_URL>
cd cardmanager

# Git configuration
chmod +x scripts/configure-git.sh
./scripts/configure-git.sh
```

### Step 2: Startup
```bash
# Automatic build and startup
chmod +x build-quick-standalone.sh
./build-quick-standalone.sh

# Or manual startup
docker-compose up -d
```

### Step 3: Verification
```bash
# Check services
docker-compose ps

# Test endpoints
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
```

---

## 🏭 Production Mode Deployment

### 1. Production Configuration
```bash
# Create production configuration
cp .env.template .env.production

# Edit sensitive variables
nano .env.production
```

### 2. External Database
```yaml
# Create docker-compose.override.yml
services:
  gestioncarte:
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://prod-db:3306/cardmanager
      - SPRING_DATASOURCE_USERNAME=${PROD_DB_USER}
      - SPRING_DATASOURCE_PASSWORD=${PROD_DB_PASSWORD}

  painter:
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://prod-db:3306/cardmanager
      - SPRING_DATASOURCE_USERNAME=${PROD_DB_USER}
      - SPRING_DATASOURCE_PASSWORD=${PROD_DB_PASSWORD}

  # Remove mariadb service
  mariadb:
    deploy:
      replicas: 0
```

### 3. Production Volumes
```yaml
# Add to docker-compose.override.yml
volumes:
  cardmanager_images:
    driver: local
    driver_opts:
      type: nfs
      o: addr=your-nfs-server,rw
      device: ":/path/to/images"

  cardmanager_db_data:
    external: true
    name: prod_db_data
```

### 4. Production Startup
```bash
# Startup with override
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

# Verify deployment
docker-compose ps
```

---

## 🔍 Maintenance and Monitoring

### Maintenance Commands
```bash
# Real-time logs
docker-compose logs -f

# Restart a service
docker-compose restart gestioncarte

# Update images
docker-compose pull
docker-compose up -d

# Data backup
./export-data.sh
```

### Monitoring
```bash
# System metrics
docker stats

# Health checks
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health

# Volume disk space
docker system df
```

---

## 🐛 Troubleshooting

### Git Issues
```bash
# Check repository access
git ls-remote $MASON_REPO_URL

# Token issue
echo $GIT_TOKEN | cut -c1-10  # Check token beginning
```

### Database Issues
```bash
# Direct connection
docker-compose exec mariadb mysql -u ia -p

# Reset database
docker-compose down --volumes
docker-compose up -d
```

### Performance Issues
```bash
# Check memory
docker stats --no-stream

# Optimize images
docker image prune -f
docker volume prune -f
```

---

## 📞 Support

### Logs to provide in case of issues
```bash
# Collect all logs
docker-compose logs > cardmanager-logs.txt

# Anonymized configuration
docker-compose config > cardmanager-config.yml
```

### System Information
```bash
# Docker version
docker --version
docker-compose --version

# Disk space
df -h
```

**🎯 For any technical questions, please include this information!**
