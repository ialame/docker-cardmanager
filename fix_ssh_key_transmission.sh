#!/bin/bash

# 🔑 Correction Transmission Clé SSH
# Résout le problème "Permission denied (publickey)" dans Docker

echo "🔑 Correction Transmission Clé SSH"
echo "=================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🎯 Problème identifié : Clé SSH non transmise au conteneur${NC}"
echo -e "${YELLOW}📋 Solution : Transmission explicite de la clé SSH${NC}"
echo ""

# 1. Vérification des clés SSH disponibles
echo -e "${BLUE}🔍 Vérification des clés SSH disponibles...${NC}"

SSH_KEY_FILE=""
SSH_KEY_CANDIDATES=(
    ~/.ssh/bitbucket_ed25519
    ~/.ssh/id_ed25519
    ~/.ssh/id_rsa
    ~/.ssh/bitbucket_rsa
)

for key_file in "${SSH_KEY_CANDIDATES[@]}"; do
    if [ -f "$key_file" ]; then
        echo -e "${GREEN}✅ Trouvé : $key_file${NC}"
        if [ -z "$SSH_KEY_FILE" ]; then
            SSH_KEY_FILE="$key_file"
        fi
    else
        echo -e "${YELLOW}⚠️ Non trouvé : $key_file${NC}"
    fi
done

if [ -z "$SSH_KEY_FILE" ]; then
    echo -e "${RED}❌ Aucune clé SSH trouvée !${NC}"
    echo -e "${YELLOW}💡 Créez une clé SSH :${NC}"
    echo "   ssh-keygen -t ed25519 -C 'votre.email@domain.com'"
    echo "   ssh-add ~/.ssh/id_ed25519"
    echo "   # Puis ajoutez ~/.ssh/id_ed25519.pub sur Bitbucket"
    exit 1
fi

echo -e "${GREEN}🔑 Clé SSH sélectionnée : $SSH_KEY_FILE${NC}"

# 2. Test de connexion SSH
echo -e "${BLUE}🧪 Test de connexion SSH...${NC}"
if ssh -T git@bitbucket.org -o ConnectTimeout=5 -o BatchMode=yes 2>&1 | grep -q "logged in as"; then
    echo -e "${GREEN}✅ SSH fonctionne localement${NC}"
else
    echo -e "${RED}❌ SSH ne fonctionne pas localement${NC}"
    echo -e "${YELLOW}💡 Solutions :${NC}"
    echo "   1. Vérifiez que la clé est ajoutée à ssh-agent :"
    echo "      eval \$(ssh-agent -s)"
    echo "      ssh-add $SSH_KEY_FILE"
    echo "   2. Vérifiez que la clé publique est sur Bitbucket :"
    echo "      cat ${SSH_KEY_FILE}.pub"
    echo "   3. Testez manuellement : ssh -T git@bitbucket.org"
    exit 1
fi

# 3. Encoder la clé SSH pour Docker
echo -e "${BLUE}🔧 Encodage de la clé SSH pour Docker...${NC}"
SSH_PRIVATE_KEY_ENCODED=$(cat "$SSH_KEY_FILE" | base64 -w 0 2>/dev/null || cat "$SSH_KEY_FILE" | base64)

if [ -z "$SSH_PRIVATE_KEY_ENCODED" ]; then
    echo -e "${RED}❌ Erreur lors de l'encodage de la clé SSH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Clé SSH encodée (${#SSH_PRIVATE_KEY_ENCODED} caractères)${NC}"

# 4. Mise à jour du .env avec la clé SSH
echo -e "${BLUE}📝 Mise à jour du fichier .env...${NC}"

# Sauvegarder le .env existant
if [ -f ".env" ]; then
    cp .env .env.backup
    echo -e "${GREEN}💾 .env sauvegardé vers .env.backup${NC}"
fi

# Lire la configuration existante ou créer une nouvelle
if [ -f ".env" ]; then
    source .env
fi

# Créer/Mettre à jour le .env avec la clé SSH
cat > .env << EOF
# 🌐 Configuration SSH Bitbucket
MASON_REPO_URL=${MASON_REPO_URL:-git@bitbucket.org:pcafxc/mason.git}
PAINTER_REPO_URL=${PAINTER_REPO_URL:-git@bitbucket.org:pcafxc/painter.git}
GESTIONCARTE_REPO_URL=${GESTIONCARTE_REPO_URL:-git@bitbucket.org:pcafxc/gestioncarte.git}

# 🌿 Branches
MASON_BRANCH=${MASON_BRANCH:-feature/RETRIEVER-511}
PAINTER_BRANCH=${PAINTER_BRANCH:-feature/card-manager-511}
GESTIONCARTE_BRANCH=${GESTIONCARTE_BRANCH:-feature/card-manager-511}

# 🔑 Clé SSH (encodée en base64)
SSH_PRIVATE_KEY=${SSH_PRIVATE_KEY_ENCODED}

# 🔑 Token Git (optionnel)
GIT_TOKEN=${GIT_TOKEN:-}

# 🗄️ Configuration Base de Données
DB_NAME=${DB_NAME:-dev}
DB_USER=${DB_USER:-ia}
DB_PASSWORD=${DB_PASSWORD:-foufafou}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-root_password}

# 🔌 Ports
GESTIONCARTE_PORT=${GESTIONCARTE_PORT:-8080}
PAINTER_PORT=${PAINTER_PORT:-8081}
NGINX_PORT=${NGINX_PORT:-8082}
MARIADB_PORT=${MARIADB_PORT:-3307}

# 🖼️ Configuration Painter
PAINTER_IMAGES_PATH=/app/images

# 🔧 Configuration Spring
SPRING_PROFILES_ACTIVE=docker
SPRING_DATASOURCE_URL=jdbc:mariadb://mariadb:3306/${DB_NAME}
SPRING_DATASOURCE_USERNAME=${DB_USER}
SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
EOF

echo -e "${GREEN}✅ Fichier .env mis à jour avec la clé SSH${NC}"

# 5. Vérification de la transmission dans docker-compose.yml
echo -e "${BLUE}🐳 Vérification du docker-compose.yml...${NC}"

# Vérifier que SSH_PRIVATE_KEY est bien dans les args
if grep -q "SSH_PRIVATE_KEY" docker-compose.yml; then
    echo -e "${GREEN}✅ SSH_PRIVATE_KEY trouvé dans docker-compose.yml${NC}"
else
    echo -e "${YELLOW}⚠️ SSH_PRIVATE_KEY manquant dans docker-compose.yml${NC}"
    echo -e "${BLUE}📝 Mise à jour du docker-compose.yml...${NC}"

    # Backup du docker-compose.yml
    cp docker-compose.yml docker-compose.yml.backup

    # Créer un docker-compose.yml corrigé
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

    echo -e "${GREEN}✅ docker-compose.yml mis à jour${NC}"
fi

# 6. Script de build final
echo -e "${BLUE}🚀 Création du script de build final...${NC}"
cat > build-with-ssh-transmission.sh << 'EOF'
#!/bin/bash

# 🔑 Build CardManager avec Transmission SSH

echo "🔑 Build CardManager avec Transmission SSH"
echo "==========================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Vérifications
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Fichier .env manquant !${NC}"
    echo -e "${YELLOW}💡 Lancez d'abord : ./fix_ssh_key_transmission.sh${NC}"
    exit 1
fi

# Source de la configuration
source .env

# Vérifier que SSH_PRIVATE_KEY est défini
if [ -z "$SSH_PRIVATE_KEY" ]; then
    echo -e "${RED}❌ SSH_PRIVATE_KEY non définie dans .env !${NC}"
    echo -e "${YELLOW}💡 Lancez : ./fix_ssh_key_transmission.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Clé SSH trouvée (${#SSH_PRIVATE_KEY} caractères)${NC}"

# Affichage de la configuration
echo -e "${BLUE}📋 Configuration :${NC}"
echo "   Mason: $MASON_REPO_URL"
echo "   Painter: $PAINTER_REPO_URL"
echo "   GestionCarte: $GESTIONCARTE_REPO_URL"
echo "   SSH: Clé encodée prête"

# Test SSH local (optionnel mais informatif)
echo -e "${BLUE}🧪 Test SSH local...${NC}"
if ssh -T git@bitbucket.org -o ConnectTimeout=3 -o BatchMode=yes 2>&1 | grep -q "logged in as"; then
    echo -e "${GREEN}✅ SSH local OK${NC}"
else
    echo -e "${YELLOW}⚠️ SSH local problématique (mais Docker utilisera sa propre clé)${NC}"
fi

# Nettoyer les conteneurs précédents
echo -e "${BLUE}🧹 Nettoyage...${NC}"
docker-compose down --volumes --remove-orphans 2>/dev/null

# Build avec transmission SSH
echo -e "${BLUE}🔨 Build avec transmission SSH...${NC}"
echo -e "${YELLOW}📋 La clé SSH sera transmise via SSH_PRIVATE_KEY${NC}"

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
    echo "2. La clé SSH est transmise : SSH_PRIVATE_KEY=${#SSH_PRIVATE_KEY} caractères"
    echo "3. Vérifiez que la clé publique est sur Bitbucket"
    echo "4. Relancez si problème temporaire"
    exit 1
fi
EOF

chmod +x build-with-ssh-transmission.sh
echo -e "${GREEN}✅ Script de build SSH créé${NC}"

# Résumé
echo ""
echo -e "${GREEN}🎉 CORRECTION SSH TERMINÉE !${NC}"
echo -e "${BLUE}══════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 Ce qui a été corrigé :${NC}"
echo "   ✅ Clé SSH détectée et encodée"
echo "   ✅ SSH_PRIVATE_KEY ajoutée au .env"
echo "   ✅ docker-compose.yml mis à jour"
echo "   ✅ Arguments SSH transmis aux Dockerfiles"
echo "   ✅ Script de build SSH créé"
echo ""
echo -e "${YELLOW}🔑 Clé SSH utilisée :${NC} $SSH_KEY_FILE"
echo -e "${YELLOW}📁 Clé publique :${NC} ${SSH_KEY_FILE}.pub"
echo ""
echo -e "${YELLOW}🚀 Pour continuer :${NC}"
echo "   ./build-with-ssh-transmission.sh"
echo ""
echo -e "${YELLOW}💡 Si le problème persiste :${NC}"
echo "   1. Vérifiez que votre clé publique est sur Bitbucket"
echo "   2. Testez : ssh -T git@bitbucket.org"
echo "   3. Vérifiez les permissions : chmod 600 $SSH_KEY_FILE"
echo ""
echo -e "${GREEN}La clé SSH devrait maintenant être transmise à Docker ! 🎯${NC}"