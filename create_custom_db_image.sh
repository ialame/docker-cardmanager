#!/bin/bash

# 🗄️ Création d'une Image MariaDB Personnalisée à partir de la Base Locale
# Ce script exporte votre base locale et crée une image Docker réutilisable

echo "🗄️ Création d'une Image MariaDB Personnalisée"
echo "=============================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🎯 Objectif : Créer une image Docker avec votre base localhost:3306/dev${NC}"
echo ""

# 1. Créer le dossier pour l'image personnalisée
echo -e "${BLUE}📁 Création de la structure...${NC}"
mkdir -p docker/mariadb-custom
mkdir -p docker/mariadb-custom/initdb

# 2. Export de la base de données locale
echo -e "${BLUE}💾 Export de votre base de données locale...${NC}"
echo -e "${YELLOW}⚠️ Assurez-vous que votre MariaDB local est démarré sur localhost:3306${NC}"

# Tester la connexion
echo -e "${BLUE}🧪 Test de connexion à la base locale...${NC}"
if mysql -h localhost -P 3306 -u ia -pfoufafou -e "USE dev; SHOW TABLES;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connexion réussie à localhost:3306/dev${NC}"
else
    echo -e "${RED}❌ Impossible de se connecter à localhost:3306/dev${NC}"
    echo -e "${YELLOW}💡 Vérifiez que :${NC}"
    echo "   - MariaDB est démarré localement"
    echo "   - Le port 3306 est accessible"
    echo "   - L'utilisateur 'ia' existe avec le mot de passe 'foufafou'"
    echo "   - La base 'dev' existe"
    exit 1
fi

# 3. Dump de la structure et des données
echo -e "${BLUE}📤 Export de la structure et des données...${NC}"
mysqldump -h localhost -P 3306 -u ia -pfoufafou \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --add-drop-database \
    --create-options \
    --disable-keys \
    --extended-insert \
    --quick \
    --lock-tables=false \
    dev > docker/mariadb-custom/initdb/01-structure-and-data.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Export réussi : $(wc -l < docker/mariadb-custom/initdb/01-structure-and-data.sql) lignes${NC}"
else
    echo -e "${RED}❌ Erreur lors de l'export${NC}"
    exit 1
fi

# 4. Créer un script d'initialisation pour créer l'utilisateur
echo -e "${BLUE}👤 Création du script d'initialisation utilisateur...${NC}"
cat > docker/mariadb-custom/initdb/00-create-user.sql << 'EOF'
-- Script d'initialisation pour CardManager DB
-- Création de l'utilisateur et de la base de données

-- S'assurer que la base dev existe
CREATE DATABASE IF NOT EXISTS dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Créer l'utilisateur ia s'il n'existe pas
CREATE USER IF NOT EXISTS 'ia'@'%' IDENTIFIED BY 'foufafou';

-- Donner tous les privilèges sur la base dev
GRANT ALL PRIVILEGES ON dev.* TO 'ia'@'%';

-- Rafraîchir les privilèges
FLUSH PRIVILEGES;

-- Utiliser la base dev par défaut
USE dev;
EOF

# 5. Créer le Dockerfile pour l'image personnalisée
echo -e "${BLUE}🐳 Création du Dockerfile MariaDB personnalisé...${NC}"
cat > docker/mariadb-custom/Dockerfile << 'EOF'
# 🗄️ MariaDB Image Personnalisée pour CardManager
FROM mariadb:11.0

# Informations sur l'image
LABEL maintainer="ibrahim.alame@gmail.com"
LABEL description="MariaDB avec données CardManager pré-chargées"
LABEL version="1.0"

# Variables d'environnement par défaut
ENV MYSQL_ROOT_PASSWORD=root_password
ENV MYSQL_DATABASE=dev
ENV MYSQL_USER=ia
ENV MYSQL_PASSWORD=foufafou

# Copier les scripts d'initialisation
COPY initdb/ /docker-entrypoint-initdb.d/

# Définir les permissions correctes
RUN chmod -R 755 /docker-entrypoint-initdb.d/

# Exposer le port standard
EXPOSE 3306

# Configuration MariaDB optimisée
RUN echo '[mysqld]' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'character-set-server=utf8mb4' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'collation-server=utf8mb4_unicode_ci' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'max_connections=200' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'innodb_buffer_pool_size=256M' >> /etc/mysql/conf.d/cardmanager.cnf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD mysqladmin ping -h localhost -u $MYSQL_USER -p$MYSQL_PASSWORD || exit 1
EOF

# 6. Build de l'image personnalisée
echo -e "${BLUE}🔨 Construction de l'image MariaDB personnalisée...${NC}"
docker build -t cardmanager-mariadb:latest docker/mariadb-custom/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Image cardmanager-mariadb:latest créée avec succès${NC}"
else
    echo -e "${RED}❌ Erreur lors de la construction de l'image${NC}"
    exit 1
fi

# 7. Mise à jour du docker-compose.yml pour utiliser l'image personnalisée
echo -e "${BLUE}📝 Mise à jour du docker-compose.yml...${NC}"
# Sauvegarder l'ancien
cp docker-compose.yml docker-compose.yml.backup

# Créer la nouvelle configuration
cat > docker-compose.yml << 'EOF'
services:
  # 🗄️ Base de données MariaDB Personnalisée
  mariadb:
    image: cardmanager-mariadb:latest
    container_name: cardmanager-mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD:-root_password}
      MYSQL_DATABASE: ${DB_NAME:-dev}
      MYSQL_USER: ${DB_USER:-ia}
      MYSQL_PASSWORD: ${DB_PASSWORD:-foufafou}
    ports:
      - "${MARIADB_PORT:-3307}:3306"
    volumes:
      - ./volumes/db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "${DB_USER:-ia}", "-p${DB_PASSWORD:-foufafou}"]
      timeout: 10s
      retries: 10
      interval: 10s
      start_period: 60s

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
      SPRING_DATASOURCE_URL: jdbc:mariadb://mariadb:3306/${DB_NAME:-dev}
      SPRING_DATASOURCE_USERNAME: ${DB_USER:-ia}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD:-foufafou}
      PAINTER_IMAGES_PATH: /app/images
    depends_on:
      mariadb:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-s", "http://localhost:8081/"]
      timeout: 5s
      retries: 3
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
      SPRING_DATASOURCE_URL: jdbc:mariadb://mariadb:3306/${DB_NAME:-dev}
      SPRING_DATASOURCE_USERNAME: ${DB_USER:-ia}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD:-foufafou}
      PAINTER_SERVICE_URL: http://painter:8081
    depends_on:
      mariadb:
        condition: service_healthy
      painter:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-s", "http://localhost:8080/"]
      timeout: 5s
      retries: 3
      interval: 30s
      start_period: 120s

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
EOF

echo -e "${GREEN}✅ docker-compose.yml mis à jour${NC}"

# 8. Mise à jour du .env pour utiliser la nouvelle image
echo -e "${BLUE}📝 Mise à jour du .env...${NC}"
cat > .env << 'EOF'
# 🌐 Configuration SSH Bitbucket
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git

# 🌿 Branches
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511

# 🔑 Clé SSH (sera mise à jour automatiquement)
SSH_PRIVATE_KEY=

# 🗄️ Configuration Base de Données Personnalisée
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

# 9. Script de démarrage final
echo -e "${BLUE}🚀 Création du script de démarrage final...${NC}"
cat > start-with-custom-db.sh << 'EOF'
#!/bin/bash

echo "🚀 Démarrage de CardManager avec Base Personnalisée"
echo "=================================================="

# Vérifier que l'image existe
if ! docker images | grep -q "cardmanager-mariadb"; then
    echo "❌ Image cardmanager-mariadb non trouvée !"
    echo "💡 Lancez d'abord : ./create_custom_db_image.sh"
    exit 1
fi

# Ajouter la clé SSH
if [ -z "$SSH_PRIVATE_KEY" ]; then
    echo "🔑 Configuration de la clé SSH..."
    SSH_KEY_FILE=""
    for key_file in ~/.ssh/bitbucket_ed25519 ~/.ssh/id_ed25519 ~/.ssh/id_rsa; do
        if [ -f "$key_file" ]; then
            SSH_KEY_FILE="$key_file"
            break
        fi
    done

    if [ ! -z "$SSH_KEY_FILE" ]; then
        export SSH_PRIVATE_KEY=$(cat "$SSH_KEY_FILE" | base64 -w 0 2>/dev/null || cat "$SSH_KEY_FILE" | base64)
        sed -i "s/SSH_PRIVATE_KEY=.*/SSH_PRIVATE_KEY=$SSH_PRIVATE_KEY/" .env
        echo "✅ Clé SSH configurée"
    fi
fi

# Nettoyer l'environnement précédent
echo "🧹 Nettoyage..."
docker-compose down --volumes 2>/dev/null

# Démarrer avec la base personnalisée
echo "🚀 Démarrage complet avec base personnalisée..."
docker-compose up -d

echo ""
echo "✅ CardManager démarré avec votre base de données !"
echo ""
echo "🔗 Services disponibles :"
echo "   📱 GestionCarte : http://localhost:8080"
echo "   🎨 Painter : http://localhost:8081"
echo "   🖼️ Images : http://localhost:8082"
echo "   🗄️ MariaDB : localhost:3307"
echo ""
echo "🔍 Suivi des logs :"
echo "   docker-compose logs -f"
EOF

chmod +x start-with-custom-db.sh

# Résumé final
echo ""
echo -e "${GREEN}🎉 IMAGE MARIADB PERSONNALISÉE CRÉÉE !${NC}"
echo -e "${BLUE}════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 Ce qui a été fait :${NC}"
echo "   ✅ Export de votre base localhost:3306/dev"
echo "   ✅ Image Docker cardmanager-mariadb:latest créée"
echo "   ✅ docker-compose.yml mis à jour"
echo "   ✅ Configuration automatisée"
echo ""
echo -e "${YELLOW}🚀 Pour démarrer votre système :${NC}"
echo "   ./start-with-custom-db.sh"
echo ""
echo -e "${YELLOW}📊 Informations sur l'image :${NC}"
echo "   - Nom : cardmanager-mariadb:latest"
echo "   - Données : Votre base locale dev"
echo "   - Utilisateur : ia / foufafou"
echo ""
echo -e "${GREEN}Votre CardManager va maintenant utiliser VOS données ! 🎯${NC}"