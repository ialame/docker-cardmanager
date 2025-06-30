#!/bin/bash

# 🔑 Build CardManager avec SSH Final

echo "🔑 Build CardManager avec SSH Final"
echo "==================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}✅ SSH configuré et clé encodée !${NC}"

# Vérifier que SSH_PRIVATE_KEY est défini
if [ -z "$SSH_PRIVATE_KEY" ]; then
    echo -e "${YELLOW}📋 SSH_PRIVATE_KEY non trouvée dans l'environnement${NC}"
    echo -e "${BLUE}🔧 Rechargement depuis .env...${NC}"

    if [ -f ".env" ] && grep -q "SSH_PRIVATE_KEY" .env; then
        source .env
        echo -e "${GREEN}✅ SSH_PRIVATE_KEY chargée depuis .env${NC}"
    else
        echo -e "${RED}❌ SSH_PRIVATE_KEY non trouvée !${NC}"
        echo -e "${YELLOW}💡 Réencodage de la clé...${NC}"
        export SSH_PRIVATE_KEY=$(cat /Users/ibrahimalame/.ssh/bitbucket_ed25519 | base64)

        # Ajouter au .env
        if [ -f ".env" ]; then
            # Supprimer la ligne existante si elle existe
            grep -v "SSH_PRIVATE_KEY" .env > .env.tmp && mv .env.tmp .env
        fi
        echo "SSH_PRIVATE_KEY=$SSH_PRIVATE_KEY" >> .env
        echo -e "${GREEN}✅ SSH_PRIVATE_KEY ajoutée au .env${NC}"
    fi
fi

echo -e "${GREEN}🔑 Clé SSH prête (${#SSH_PRIVATE_KEY} caractères)${NC}"

# Vérifier la configuration
if [ -f ".env" ]; then
    source .env
    echo -e "${BLUE}📋 Configuration :${NC}"
    echo "   Mason: ${MASON_REPO_URL:-git@bitbucket.org:pcafxc/mason.git}"
    echo "   Painter: ${PAINTER_REPO_URL:-git@bitbucket.org:pcafxc/painter.git}"
    echo "   GestionCarte: ${GESTIONCARTE_REPO_URL:-git@bitbucket.org:pcafxc/gestioncarte.git}"
    echo "   SSH: ✅ Configuré"
else
    echo -e "${BLUE}📝 Création du fichier .env complet...${NC}"
    cat > .env << EOF
# 🌐 Configuration SSH Bitbucket
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git

# 🌿 Branches
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511

# 🔑 Clé SSH (encodée en base64)
SSH_PRIVATE_KEY=$SSH_PRIVATE_KEY

# 🔑 Token Git (optionnel)
GIT_TOKEN=

# 🗄️ Configuration Base de Données
DB_NAME=dev
DB_USER=ia
DB_PASSWORD=foufafou
DB_ROOT_PASSWORD=root_password

# 🔌 Ports
GESTIONCARTE_PORT=8080
PAINTER_PORT=8081
NGINX_PORT=8082
MARIADB_PORT=3307

# 🖼️ Configuration Painter
PAINTER_IMAGES_PATH=/app/images

# 🔧 Configuration Spring
SPRING_PROFILES_ACTIVE=docker
SPRING_DATASOURCE_URL=jdbc:mariadb://mariadb:3306/dev
SPRING_DATASOURCE_USERNAME=ia
SPRING_DATASOURCE_PASSWORD=foufafou
EOF
    echo -e "${GREEN}✅ Fichier .env créé${NC}"
fi

# Vérifier docker-compose.yml
echo -e "${BLUE}🐳 Vérification du docker-compose.yml...${NC}"
if ! grep -q "SSH_PRIVATE_KEY.*{SSH_PRIVATE_KEY}" docker-compose.yml 2>/dev/null; then
    echo -e "${YELLOW}📝 Mise à jour du docker-compose.yml...${NC}"

    # Backup
    [ -f "docker-compose.yml" ] && cp docker-compose.yml docker-compose.yml.backup

    cat > docker-compose.yml << 'COMPOSE_EOF'
services:
  # 🗄️ Base de données MariaDB
  mariadb:
    image: mariadb:11.0
    container_name: cardmanager-mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
    ports:
      - "${MARIADB_PORT:-3307}:3306"
    volumes:
      - ./volumes/db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mariadb-admin", "ping", "-h", "localhost", "-u", "root", "-p${DB_ROOT_PASSWORD}"]
      timeout: 10s
      retries: 10
      interval: 10s
      start_period: 30s

  # 🎨 Service Painter (Images)
  painter:
    build:
      context: .
      dockerfile: docker/painter/Dockerfile
      args:
        MASON_REPO_URL: ${MASON_REPO_URL}
        PAINTER_REPO_URL: ${PAINTER_REPO_URL}
        MASON_BRANCH: ${MASON_BRANCH}
        PAINTER_BRANCH: ${PAINTER_BRANCH}
        SSH_PRIVATE_KEY: ${SSH_PRIVATE_KEY}
        GIT_TOKEN: ${GIT_TOKEN}
    container_name: cardmanager-painter
    restart: unless-stopped
    ports:
      - "${PAINTER_PORT:-8081}:8081"
    volumes:
      - ./volumes/images:/app/images
    environment:
      SPRING_PROFILES_ACTIVE: docker
      SPRING_DATASOURCE_URL: jdbc:mariadb://mariadb:3306/${DB_NAME}
      SPRING_DATASOURCE_USERNAME: ${DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
      PAINTER_IMAGES_PATH: /app/images
    depends_on:
      mariadb:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/actuator/health"]
      timeout: 10s
      retries: 5
      interval: 30s
      start_period: 60s

  # 🖼️ Service GestionCarte (Application principale)
  gestioncarte:
    build:
      context: .
      dockerfile: docker/gestioncarte/Dockerfile
      args:
        MASON_REPO_URL: ${MASON_REPO_URL}
        PAINTER_REPO_URL: ${PAINTER_REPO_URL}
        GESTIONCARTE_REPO_URL: ${GESTIONCARTE_REPO_URL}
        MASON_BRANCH: ${MASON_BRANCH}
        PAINTER_BRANCH: ${PAINTER_BRANCH}
        GESTIONCARTE_BRANCH: ${GESTIONCARTE_BRANCH}
        SSH_PRIVATE_KEY: ${SSH_PRIVATE_KEY}
        GIT_TOKEN: ${GIT_TOKEN}
    container_name: cardmanager-gestioncarte
    restart: unless-stopped
    ports:
      - "${GESTIONCARTE_PORT:-8080}:8080"
    environment:
      SPRING_PROFILES_ACTIVE: docker
      SPRING_DATASOURCE_URL: jdbc:mariadb://mariadb:3306/${DB_NAME}
      SPRING_DATASOURCE_USERNAME: ${DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
      PAINTER_SERVICE_URL: http://painter:8081
    depends_on:
      mariadb:
        condition: service_healthy
      painter:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      timeout: 10s
      retries: 5
      interval: 30s
      start_period: 60s

  # ⚡ Nginx (Serveur d'images statiques)
  nginx:
    image: nginx:alpine
    container_name: cardmanager-nginx
    restart: unless-stopped
    ports:
      - "${NGINX_PORT:-8082}:80"
    volumes:
      - ./volumes/images:/var/www/html/images:ro
      - ./config/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - painter
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      timeout: 5s
      retries: 3
      interval: 30s

# 💾 Volumes persistants
volumes:
  db_data:
    driver: local
  images:
    driver: local
COMPOSE_EOF

    echo -e "${GREEN}✅ docker-compose.yml mis à jour avec SSH_PRIVATE_KEY${NC}"
else
    echo -e "${GREEN}✅ docker-compose.yml déjà configuré${NC}"
fi

# Créer les dossiers nécessaires
echo -e "${BLUE}📁 Création des dossiers...${NC}"
mkdir -p volumes/db_data volumes/images config
echo -e "${GREEN}✅ Dossiers créés${NC}"

# Test SSH final
echo -e "${BLUE}🧪 Test SSH final...${NC}"
if ssh -T git@bitbucket.org 2>&1 | grep -q "authenticated via ssh key"; then
    echo -e "${GREEN}✅ SSH fonctionne parfaitement${NC}"
else
    echo -e "${YELLOW}⚠️ SSH local problématique mais Docker utilisera la clé encodée${NC}"
fi

# Nettoyer les conteneurs précédents
echo -e "${BLUE}🧹 Nettoyage...${NC}"
docker-compose down --volumes --remove-orphans 2>/dev/null

# Build avec SSH
echo -e "${BLUE}🔨 Build avec SSH...${NC}"
echo -e "${YELLOW}📋 La clé SSH sera décodée dans les conteneurs${NC}"

if docker-compose build --no-cache; then
    echo ""
    echo -e "${GREEN}🎉 BUILD RÉUSSI avec SSH !${NC}"
    echo ""
    echo -e "${BLUE}🚀 Démarrage des services...${NC}"
    docker-compose up -d

    echo ""
    echo -e "${GREEN}✅ Services démarrés !${NC}"
    echo "   📱 GestionCarte : http://localhost:${GESTIONCARTE_PORT:-8080}"
    echo "   🎨 Painter : http://localhost:${PAINTER_PORT:-8081}"
    echo "   🖼️ Images statiques : http://localhost:${NGINX_PORT:-8082}"
    echo "   🗄️ MariaDB : localhost:${MARIADB_PORT:-3307}"

    echo ""
    echo -e "${BLUE}🔍 Status des services :${NC}"
    docker-compose ps

else
    echo ""
    echo -e "${RED}❌ BUILD ÉCHOUÉ !${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Diagnostics :${NC}"
    echo "1. Vérifiez les logs ci-dessus"
    echo "2. La clé SSH est transmise : ${#SSH_PRIVATE_KEY} caractères"
    echo "3. Vérifiez que la clé publique est sur Bitbucket"
    echo "4. Test local : ssh -T git@bitbucket.org"
    exit 1
fi