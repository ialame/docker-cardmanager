#!/bin/bash

echo "🔧 Correction du Health Check MariaDB"
echo "====================================="

# 1. Vérifier les logs actuels
echo "📋 Vérification des logs MariaDB..."
echo "Logs des 20 dernières lignes :"
docker-compose logs --tail=20 cardmanager-mariadb 2>/dev/null || echo "Conteneur non accessible"

# 2. Diagnostic du problème de santé
echo ""
echo "🩺 Diagnostic du health check..."
if docker ps | grep -q cardmanager-mariadb; then
    echo "Conteneur MariaDB en cours d'exécution"
    echo "Statut de santé :"
    docker inspect cardmanager-mariadb --format='{{.State.Health.Status}}'
    echo ""
    echo "Logs du health check :"
    docker inspect cardmanager-mariadb --format='{{range .State.Health.Log}}{{.Output}}{{end}}'
else
    echo "❌ Conteneur MariaDB non trouvé en cours d'exécution"
fi

# 3. Arrêt propre
echo ""
echo "🛑 Arrêt des services..."
docker-compose down

# 4. Correction du docker-compose.yml avec un health check compatible
echo "📝 Correction du docker-compose.yml..."

# Backup
[ -f "docker-compose.yml" ] && cp docker-compose.yml docker-compose.yml.backup.$(date +%s)

# Nouveau docker-compose.yml avec health check corrigé
cat > docker-compose.yml << 'COMPOSE_EOF'
services:
  # 🗄️ Base de données MariaDB personnalisée
  mariadb:
    image: cardmanager-mariadb:latest
    container_name: cardmanager-mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD:-foufafou}
      MYSQL_DATABASE: ${DB_NAME:-dev}
      MYSQL_USER: ${DB_USER:-ia}
      MYSQL_PASSWORD: ${DB_PASSWORD:-foufafou}
    ports:
      - "${MARIADB_PORT:-3307}:3306"
    volumes:
      - ./volumes/db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mariadb-admin", "ping", "-h", "localhost", "-u", "root", "-pfoufafou"]
      interval: 30s
      timeout: 10s
      start_period: 60s  # Plus de temps pour l'initialisation
      retries: 5
    networks:
      - cardmanager-network

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
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8081/actuator/health"]
      interval: 30s
      timeout: 10s
      start_period: 120s
      retries: 3
    networks:
      - cardmanager-network

  # 🖼️ Service GestionCarte (Application principale)
  gestioncarte:
    build:
      context: .
      dockerfile: docker/gestioncarte/Dockerfile
      args:
        MASON_REPO_URL: ${MASON_REPO_URL}
        GESTIONCARTE_REPO_URL: ${GESTIONCARTE_REPO_URL}
        MASON_BRANCH: ${MASON_BRANCH}
        GESTIONCARTE_BRANCH: ${GESTIONCARTE_BRANCH}
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
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      start_period: 180s
      retries: 3
    networks:
      - cardmanager-network

  # 🌐 Nginx (Reverse Proxy)
  nginx:
    image: nginx:alpine
    container_name: cardmanager-nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./config/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./volumes/images:/var/www/images:ro
    depends_on:
      gestioncarte:
        condition: service_healthy
      painter:
        condition: service_healthy
    networks:
      - cardmanager-network

volumes:
  db_data:
  images:

networks:
  cardmanager-network:
    driver: bridge
COMPOSE_EOF

# 5. Vérification du fichier .env
echo "🔍 Vérification/création du fichier .env..."
if [ ! -f ".env" ]; then
    cat > .env << 'ENV_EOF'
# Base de données
DB_NAME=dev
DB_USER=ia
DB_PASSWORD=foufafou
DB_ROOT_PASSWORD=foufafou
MARIADB_PORT=3307

# Services
PAINTER_PORT=8081
GESTIONCARTE_PORT=8080

# Repositories GitHub
MASON_REPO_URL=https://github.com/ialame/mason
PAINTER_REPO_URL=https://github.com/ialame/painter
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511

# Token Git (optionnel pour repos publics)
GIT_TOKEN=
ENV_EOF
    echo "✅ Fichier .env créé"
else
    echo "✅ Fichier .env existant"
fi

# 6. Test de l'image en mode standalone
echo ""
echo "🧪 Test rapide de l'image MariaDB..."
docker run --rm -d \
    --name test-mariadb-health \
    -e MYSQL_ROOT_PASSWORD=foufafou \
    -e MYSQL_DATABASE=dev \
    -e MYSQL_USER=ia \
    -e MYSQL_PASSWORD=foufafou \
    -p 3308:3306 \
    cardmanager-mariadb:latest

echo "⏳ Attente du démarrage (45 secondes)..."
sleep 45

# Test de santé manuel
echo "🩺 Test de santé manuel..."
if docker exec test-mariadb-health mariadb-admin ping -h localhost -u root -pfoufafou; then
    echo "✅ Health check fonctionne !"

    # Test de connexion utilisateur
    if docker exec test-mariadb-health mariadb -u ia -pfoufafou -e "USE dev; SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema='dev';"; then
        echo "✅ Base de données et utilisateur fonctionnels !"
    else
        echo "⚠️  Problème avec l'utilisateur ou la base"
    fi
else
    echo "❌ Health check échoue"
    echo "Logs du conteneur de test :"
    docker logs test-mariadb-health --tail=20
fi

# Nettoyage du test
docker stop test-mariadb-health

echo ""
echo "🚀 Configuration corrigée ! Vous pouvez maintenant lancer :"
echo "   docker-compose up -d"
echo ""
echo "📊 Pour surveiller le démarrage :"
echo "   docker-compose logs -f mariadb"