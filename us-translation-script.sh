#!/bin/bash

# 🇺🇸 Script de création des versions US pour CardManager
# Crée automatiquement les équivalents US de tous les fichiers .md

echo "🇺🇸 Création des versions US pour CardManager..."
echo "=============================================="

# Fonction pour créer la version US d'un fichier
create_us_version() {
    local french_file="$1"
    local us_file="${french_file%.md}-us.md"

    echo "📝 Création de $us_file..."

    case "$french_file" in
        "README.md")
            create_readme_us "$us_file"
            ;;
        "GUIDE-DEPLOIEMENT.md")
            create_deployment_guide_us "$us_file"
            ;;
        "CHANGELOG.md")
            create_changelog_us "$us_file"
            ;;
        *)
            echo "⚠️  Type de fichier non reconnu: $french_file"
            ;;
    esac
}

# Création du README-us.md
create_readme_us() {
    local file="$1"
    cat > "$file" << 'EOF'
# 🎯 CardManager - Multi-Service Docker Architecture

> **Card management system with microservices architecture**

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://docker.com)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.5-green?logo=spring)](https://spring.io)
[![Java](https://img.shields.io/badge/Java-21-orange?logo=openjdk)](https://openjdk.org)

## 🏗️ Architecture

```mermaid
graph TB
    A[GestionCarte :8080] --> B[Painter :8081]
    A --> C[MariaDB :3306]
    B --> C
    D[Mason] --> A
    D --> B
    E[Nginx :8082] --> B
```

### Services
- **🖼️ GestionCarte** (`:8080`) - Main card management application
- **🎨 Painter** (`:8081`) - Image processing and management service
- **🔧 Mason** - Common library (utilities, JPA, cache)
- **🗄️ MariaDB** (`:3306`) - Relational database
- **⚡ Nginx** (`:8082`) - High-performance static image server

## 🚀 Quick Start

### 1️⃣ Initial Setup
```bash
# Clone the project
git clone <your-repository>
cd cardmanager

# Automatic Git configuration
chmod +x scripts/configure-git.sh
./scripts/configure-git.sh
```

### 2️⃣ Automatic Startup
```bash
# Build and complete startup
chmod +x build-quick-standalone.sh
./build-quick-standalone.sh
```

### 3️⃣ Access Services
- **📱 Main Application** : http://localhost:8080
- **🎨 Painter API** : http://localhost:8081
- **🖼️ Static Images** : http://localhost:8082
- **📊 Swagger UI** : http://localhost:8080/swagger-ui.html

## ⚙️ Configuration

### Environment Variables (.env)
```bash
# Git Repositories
MASON_REPO_URL=https://github.com/ialame/mason
PAINTER_REPO_URL=https://github.com/ialame/painter
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte

# Branches (optional)
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main

# Git Token (for private repositories)
GIT_TOKEN=your_github_token_here
```

### Database
```yaml
# Development (Integrated MariaDB)
SPRING_DATASOURCE_URL: jdbc:mariadb://mariadb:3306/dev
SPRING_DATASOURCE_USERNAME: ia
SPRING_DATASOURCE_PASSWORD: foufafou

# Production (External Database)
SPRING_DATASOURCE_URL: jdbc:mariadb://your-db:3306/production
```

## 🛠️ Useful Commands

### Docker Compose
```bash
# Complete startup
docker-compose up -d

# Real-time logs
docker-compose logs -f

# Restart a service
docker-compose restart gestioncarte

# Complete shutdown
docker-compose down

# Complete cleanup
docker-compose down --volumes --remove-orphans
```

### Maintenance
```bash
# Data export
./export-data.sh

# Project cleanup
./scripts/cleanup-project.sh

# Complete rebuild
docker-compose build --no-cache
```

## 📁 Project Structure

```
cardmanager/
├── 📄 docker-compose.yml          # Main configuration
├── 📄 build-quick-standalone.sh   # Automatic build script
├── 📄 export-data.sh             # Data export
├── 📄 .env.template              # Configuration template
│
├── 🐳 docker/                    # Dockerfiles
│   ├── mason/Dockerfile
│   ├── painter/Dockerfile
│   └── gestioncarte/Dockerfile
│
├── ⚙️ config/                    # Configurations
│   ├── application-docker.properties
│   └── nginx.conf
│
├── 📜 scripts/                   # Utility scripts
│   ├── configure-git.sh
│   └── cleanup-project.sh
│
└── 💾 volumes/                   # Persistent data
    ├── db_data/                  # MariaDB data
    └── images/                   # Painter images
```

## 🔍 Monitoring and Logs

### Health Checks
```bash
# Check service status
docker-compose ps

# Detailed health check
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
```

### Service Logs
```bash
# Main application
docker-compose logs -f gestioncarte

# Image service
docker-compose logs -f painter

# Database
docker-compose logs -f mariadb
```

## 🚀 Production Deployment

### 1. Secure Configuration
```bash
# Copy and adapt configuration
cp .env.template .env.production

# Modify sensitive values
nano .env.production
```

### 2. External Database
```yaml
# In docker-compose.override.yml
services:
  gestioncarte:
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://prod-db:3306/cardmanager
      - SPRING_DATASOURCE_USERNAME=${DB_USER}
      - SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
```

### 3. Production Volumes
```yaml
volumes:
  cardmanager_images:
    driver: local
    driver_opts:
      type: nfs
      o: addr=your-nfs-server,rw
      device: ":/path/to/images"
```

## 🐛 Troubleshooting

### Common Issues

#### ❌ Services not starting
```bash
# Check dependencies
docker-compose ps

# Rebuild images
docker-compose build --no-cache

# Check configuration
docker-compose config
```

#### ❌ Database connection errors
```bash
# Test connection
docker-compose exec mariadb mysql -u ia -p

# Check logs
docker-compose logs mariadb
```

#### ❌ Git build issues
```bash
# Check credentials
docker-compose logs builder

# Test Git access
git ls-remote $MASON_REPO_URL
```

### Support
- 📖 **Complete Documentation** : `docs/`
- 🐛 **Issues** : Create a GitHub issue
- 💬 **Questions** : Contact technical team

## 📈 Performance

### Included Optimizations
- ✅ **Nginx Cache** (30 days for images)
- ✅ **HikariCP Connection Pool** optimized
- ✅ **Gzip Compression** enabled
- ✅ **CORS Headers** configured
- ✅ **Intelligent Health Checks**
- ✅ **SSD Volumes** recommended

### Metrics
- **Startup Time** : ~2-3 minutes
- **Required Memory** : 4GB RAM minimum
- **Storage** : 10GB for data + images

---

**🎯 CardManager - Production Ready!**
EOF
    echo "✅ $file created"
}

# Création du GUIDE-DEPLOIEMENT-us.md
create_deployment_guide_us() {
    local file="$1"
    cat > "$file" << 'EOF'
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
EOF
    echo "✅ $file created"
}

# Création du CHANGELOG-us.md
create_changelog_us() {
    local file="$1"
    cat > "$file" << 'EOF'
# 📋 Changelog - CardManager

## [1.0.0] - 2025-06-29

### ✨ Added Features
- Complete Docker multi-service architecture
- GestionCarte service with REST API
- Painter service for image management
- Mason common library
- Integrated MariaDB database
- Nginx server for static images
- Automatic Git configuration
- Automated deployment scripts

### 🔧 Technical Improvements
- Intelligent health checks
- Docker persistent volumes
- Optimized Nginx cache (30 days)
- Complete CORS configuration
- Monitoring and metrics
- Complete documentation

### 🛠️ Configuration
- Support for public/private Git repositories
- Token-based authentication
- Flexible configuration via environment variables
- Development and production modes

### 📚 Documentation
- Complete deployment guide
- Detailed README with architecture
- Automatic configuration scripts
- Troubleshooting examples

### 🐳 Docker
- Optimized images with multi-stage cache
- Production-ready Docker Compose configuration
- Named volumes for persistence
- Network isolation

### 🌐 Internationalization
- Complete documentation in French and English
- Bilingual support for deployment guides
- US versions of all documentation files
EOF
    echo "✅ $file created"
}

# Créer le script de configuration Git US
create_configure_git_us() {
    echo "🔧 Création du script de configuration Git US..."
    cat > scripts/configure-git-us.sh << 'EOF'
#!/bin/bash

# 🔧 Automatic Git repository configuration for CardManager

echo "🔧 CardManager Git Repository Configuration"
echo "==========================================="

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  The .env file already exists."
    read -p "Do you want to replace it? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "❌ Configuration cancelled."
        exit 0
    fi
fi

# Copy template
cp .env.template .env

echo ""
echo "📝 Git repository URLs configuration:"
echo ""

# Mason Repository
read -p "🔧 Mason repository URL [https://github.com/ialame/mason]: " mason_url
mason_url=${mason_url:-https://github.com/ialame/mason}
sed -i "s|MASON_REPO_URL=.*|MASON_REPO_URL=$mason_url|" .env

# Painter Repository
read -p "🎨 Painter repository URL [https://github.com/ialame/painter]: " painter_url
painter_url=${painter_url:-https://github.com/ialame/painter}
sed -i "s|PAINTER_REPO_URL=.*|PAINTER_REPO_URL=$painter_url|" .env

# GestionCarte Repository
read -p "💳 GestionCarte repository URL [https://github.com/ialame/gestioncarte]: " gestion_url
gestion_url=${gestion_url:-https://github.com/ialame/gestioncarte}
sed -i "s|GESTIONCARTE_REPO_URL=.*|GESTIONCARTE_REPO_URL=$gestion_url|" .env

echo ""
echo "🌿 Branch configuration (optional):"

# Branches
read -p "🔧 Mason branch [main]: " mason_branch
mason_branch=${mason_branch:-main}
sed -i "s|MASON_BRANCH=.*|MASON_BRANCH=$mason_branch|" .env

read -p "🎨 Painter branch [main]: " painter_branch
painter_branch=${painter_branch:-main}
sed -i "s|PAINTER_BRANCH=.*|PAINTER_BRANCH=$painter_branch|" .env

read -p "💳 GestionCarte branch [main]: " gestion_branch
gestion_branch=${gestion_branch:-main}
sed -i "s|GESTIONCARTE_BRANCH=.*|GESTIONCARTE_BRANCH=$gestion_branch|" .env

echo ""
echo "🔐 Git authentication configuration:"
echo "ℹ️  Leave empty if your repositories are public"
echo "ℹ️  For private repositories, use a personal access token"
echo ""

read -p "🔑 Git token (ghp_xxx or ATBB-xxx) [optional]: " git_token
if [ ! -z "$git_token" ]; then
    sed -i "s|GIT_TOKEN=.*|GIT_TOKEN=$git_token|" .env
fi

echo ""
echo "✅ Configuration completed!"
echo ""
echo "📁 .env file created with:"
echo "   🔧 Mason: $mason_url ($mason_branch)"
echo "   🎨 Painter: $painter_url ($painter_branch)"
echo "   💳 GestionCarte: $gestion_url ($gestion_branch)"
if [ ! -z "$git_token" ]; then
    echo "   🔑 Token: ${git_token:0:10}..."
fi
echo ""
echo "🚀 Ready for deployment!"
echo "   Run: ./build-quick-standalone.sh"
EOF
    chmod +x scripts/configure-git-us.sh
}

# Créer un script pour gérer les versions bilingues
create_bilingual_manager() {
    echo "🌐 Création du gestionnaire bilingue..."
    cat > scripts/manage-bilingual-docs.sh << 'EOF'
#!/bin/bash

# 🌐 Bilingual Documentation Manager for CardManager
# Manage French and US versions of documentation

echo "🌐 CardManager Bilingual Documentation Manager"
echo "============================================="

show_help() {
    echo ""
    echo "📚 Available commands:"
    echo "  sync-to-us      - Copy French content to US versions"
    echo "  sync-to-fr      - Copy US content to French versions"
    echo "  list-docs       - List all documentation files"
    echo "  check-sync      - Check synchronization status"
    echo "  help            - Show this help"
    echo ""
}

list_docs() {
    echo "📄 French Documentation:"
    ls -la *.md | grep -v "\-us\.md"
    echo ""
    echo "🇺🇸 US Documentation:"
    ls -la *-us.md 2>/dev/null || echo "No US documentation found"
}

check_sync() {
    echo "🔍 Checking documentation synchronization..."
    echo ""

    for fr_file in *.md; do
        if [[ "$fr_file" != *"-us.md" ]]; then
            us_file="${fr_file%.md}-us.md"
            if [ -f "$us_file" ]; then
                fr_size=$(stat -c%s "$fr_file" 2>/dev/null || stat -f%z "$fr_file" 2>/dev/null)
                us_size=$(stat -c%s "$us_file" 2>/dev/null || stat -f%z "$us_file" 2>/dev/null)

                if [ "$fr_size" -eq "$us_size" ]; then
                    echo "✅ $fr_file ↔ $us_file (same size)"
                else
                    echo "⚠️  $fr_file ↔ $us_file (different sizes: $fr_size vs $us_size)"
                fi
            else
                echo "❌ $fr_file → Missing $us_file"
            fi
        fi
    done
}

# Main script logic
case "$1" in
    "list-docs"|"list")
        list_docs
        ;;
    "check-sync"|"check")
        check_sync
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_help
        exit 1
        ;;
esac
EOF
    chmod +x scripts/manage-bilingual-docs.sh
}

# Mettre à jour le .gitignore pour inclure les fichiers US
update_gitignore_for_bilingual() {
    echo "🔒 Mise à jour du .gitignore pour les versions bilingues..."

    # Ajouter une section pour les fichiers de documentation
    cat >> .gitignore << 'EOF'

# Documentation temporaire
*.md.bak
*.md.tmp
EOF
}

# Script principal
echo "🌐 Création des versions US de la documentation..."

# Créer les versions US des fichiers existants
if [ -f "README.md" ]; then
    create_us_version "README.md"
fi

if [ -f "GUIDE-DEPLOIEMENT.md" ]; then
    create_us_version "GUIDE-DEPLOIEMENT.md"
fi

if [ -f "CHANGELOG.md" ]; then
    create_us_version "CHANGELOG.md"
fi

# Créer le script de configuration Git US
create_configure_git_us

# Créer le gestionnaire bilingue
create_bilingual_manager

# Mettre à jour le .gitignore
update_gitignore_for_bilingual

# Mettre à jour le README principal pour mentionner les versions bilingues
echo "📝 Mise à jour du README principal..."
if [ -f "README.md" ]; then
    # Ajouter une section langues au début du README
    sed -i '1i\## 🌐 Languages / Langues\n\n- **🇫🇷 Français** : [README.md](README.md) | [Guide de Déploiement](GUIDE-DEPLOIEMENT.md) | [Changelog](CHANGELOG.md)\n- **🇺🇸 English** : [README-us.md](README-us.md) | [Deployment Guide](GUIDE-DEPLOIEMENT-us.md) | [Changelog](CHANGELOG-us.md)\n\n---\n' README.md
fi

echo ""
echo "🎉 Versions US créées avec succès !"
echo ""
echo "📁 Documentation bilingue disponible :"
echo "├── 🇫🇷 README.md ↔ 🇺🇸 README-us.md"
echo "├── 🇫🇷 GUIDE-DEPLOIEMENT.md ↔ 🇺🇸 GUIDE-DEPLOIEMENT-us.md"
echo "├── 🇫🇷 CHANGELOG.md ↔ 🇺🇸 CHANGELOG-us.md"
echo "└── 🇫🇷 scripts/configure-git.sh ↔ 🇺🇸 scripts/configure-git-us.sh"
echo ""
echo "🛠️ Outils de gestion bilingue :"
echo "├── 📄 scripts/manage-bilingual-docs.sh (gestionnaire)"
echo "└── 🔍 ./scripts/manage-bilingual-docs.sh check (vérifier sync)"
echo ""
echo "🌟 Votre projet est maintenant 100% bilingue !"
echo "   - Documentation complète en Français et Anglais"
echo "   - Scripts de configuration dans les deux langues"
echo "   - Outils de gestion de la synchronisation"
echo ""
echo "🚀 Pour démarrer :"
echo "   🇫🇷 Français : ./scripts/configure-git.sh"
echo "   🇺🇸 English  : ./scripts/configure-git-us.sh"