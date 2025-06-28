#!/bin/bash
set -e

echo "🚀 Build rapide standalone (utilisation des images existantes)..."

# Vérifier que les données ont été exportées
if [ ! -f "init-db/01-schema.sql" ] || [ ! -f "init-db/02-data.sql" ]; then
    echo "❌ Erreur: Fichiers d'export non trouvés"
    echo "💡 Lancez d'abord : ./export-data.sh"
    exit 1
fi

echo "✅ Fichiers d'export trouvés"

# Utiliser les images qui fonctionnent déjà (construites avec docker-compose.local.yml)
echo "🔄 Utilisation des images existantes qui fonctionnent..."

# Créer un docker-compose qui utilise les images déjà construites
cat > docker-compose.standalone-quick.yml << 'EOF'
services:
  # Base de données MariaDB standalone
  mariadb-standalone:
    image: mariadb:11.2
    container_name: cardmanager-mariadb-dev
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: dev
      MYSQL_USER: ia
      MYSQL_PASSWORD: foufafou
    ports:
      - "3307:3306"  # Port 3307 pour éviter les conflits
    volumes:
      - cardmanager_db_data:/var/lib/mysql
      - ./init-db:/docker-entrypoint-initdb.d
    networks:
      - cardmanager-network
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      start_period: 60s
      interval: 10s
      timeout: 5s
      retries: 10
    restart: unless-stopped

  # Service Mason (utilise l'image déjà construite)
  mason:
    image: docker-cardmanager-mason:latest
    container_name: cardmanager-mason
    depends_on:
      mariadb-standalone:
        condition: service_healthy
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://mariadb-standalone:3306/dev
      - SPRING_DATASOURCE_USERNAME=ia
      - SPRING_DATASOURCE_PASSWORD=foufafou
      - SPRING_PROFILES_ACTIVE=docker
    networks:
      - cardmanager-network

  # Service Painter (utilise l'image déjà construite)
  painter:
    image: docker-cardmanager-painter:latest
    container_name: cardmanager-painter
    ports:
      - "8081:8081"
    depends_on:
      mariadb-standalone:
        condition: service_healthy
      mason:
        condition: service_started
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://mariadb-standalone:3306/dev
      - SPRING_DATASOURCE_USERNAME=ia
      - SPRING_DATASOURCE_PASSWORD=foufafou
      - SPRING_PROFILES_ACTIVE=docker
      - PAINTER_IMAGE_STORAGE_PATH=/app/images
    volumes:
      - cardmanager_images:/app/images
    networks:
      - cardmanager-network

  # Service GestionCarte (utilise l'image déjà construite)
  gestioncarte:
    image: docker-cardmanager-gestioncarte:latest
    container_name: cardmanager-gestioncarte
    ports:
      - "8080:8080"
    depends_on:
      mariadb-standalone:
        condition: service_healthy
      painter:
        condition: service_started
      mason:
        condition: service_started
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://mariadb-standalone:3306/dev
      - SPRING_DATASOURCE_USERNAME=ia
      - SPRING_DATASOURCE_PASSWORD=foufafou
      - SPRING_PROFILES_ACTIVE=docker
      - PAINTER_SERVICE_URL=http://painter:8081
      - SPRING_LIQUIBASE_ENABLED=false
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
    networks:
      - cardmanager-network

volumes:
  cardmanager_db_data:
    name: cardmanager_db_data
  cardmanager_images:
    name: cardmanager_images

networks:
  cardmanager-network:
    name: cardmanager-network
    driver: bridge
EOF

# Arrêter les autres environnements
echo "🛑 Arrêt des autres environnements..."
docker-compose -f docker-compose.local.yml down 2>/dev/null || true

# Vérifier que les images existent
echo "🔍 Vérification des images existantes..."
if ! docker image ls | grep -q "docker-cardmanager-gestioncarte"; then
    echo "❌ Images non trouvées. Construction nécessaire..."
    echo "💡 Utilisons les images de votre environnement local qui fonctionne"

    # Démarrer seulement MariaDB pour l'instant
    echo "🗄️ Démarrage de MariaDB seul..."
    docker-compose -f docker-compose.standalone-quick.yml up -d mariadb-standalone

    # Attendre MariaDB
    echo "⏳ Attente de l'initialisation de MariaDB avec vos données..."
    timeout=180
    while ! docker-compose -f docker-compose.standalone-quick.yml exec mariadb-standalone mysqladmin ping -h localhost --silent 2>/dev/null; do
        echo "Initialisation des données... ($timeout secondes restantes)"
        sleep 5
        timeout=$((timeout-5))
        if [ $timeout -le 0 ]; then
            echo "❌ Timeout: MariaDB n'a pas démarré dans les temps"
            echo "📋 Logs de MariaDB :"
            docker-compose -f docker-compose.standalone-quick.yml logs mariadb-standalone
            exit 1
        fi
    done

    echo "✅ MariaDB avec vos données est prêt !"
    echo ""
    echo "🌐 Base de données disponible:"
    echo "   • MariaDB: localhost:3307"
    echo "   • Utilisateur: ia / foufafou"
    echo "   • Base: dev"
    echo ""
    echo "🔍 Pour tester la base:"
    echo "   mysql -h localhost -P 3307 -u ia -p dev"
    echo "   docker exec -it cardmanager-mariadb-dev mysql -u ia -p dev"
    echo ""
    echo "💡 Pour ajouter vos services, construisez d'abord les images avec:"
    echo "   docker-compose -f docker-compose.local.yml build"
    echo "   Puis relancez ce script"

    return 0
fi

echo "✅ Images trouvées"

# Démarrer MariaDB en premier
echo "🗄️ Démarrage de MariaDB avec vos données..."
docker-compose -f docker-compose.standalone-quick.yml up -d mariadb-standalone

# Attendre que MariaDB soit prêt et les données importées
echo "⏳ Attente de l'initialisation de MariaDB (import des données en cours)..."
timeout=180  # 3 minutes pour importer 2.27 GB
while ! docker-compose -f docker-compose.standalone-quick.yml exec mariadb-standalone mysqladmin ping -h localhost --silent 2>/dev/null; do
    echo "Import des données en cours... ($timeout secondes restantes)"
    echo "   (2.27 GB de données à importer, cela peut prendre du temps)"
    sleep 10
    timeout=$((timeout-10))
    if [ $timeout -le 0 ]; then
        echo "❌ Timeout: MariaDB n'a pas démarré dans les temps"
        echo "📋 Logs de MariaDB :"
        docker-compose -f docker-compose.standalone-quick.yml logs mariadb-standalone
        exit 1
    fi
done

# Vérifier que les données sont présentes
echo "🔍 Vérification de l'import des données..."
table_count=$(docker-compose -f docker-compose.standalone-quick.yml exec mariadb-standalone mysql -u ia -pfoufafou -D dev -e "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema='dev';" -s -N 2>/dev/null || echo "0")

if [ "$table_count" -gt "0" ]; then
    echo "✅ Données importées avec succès ($table_count tables trouvées)"
else
    echo "⚠️  Import des données en cours..."
fi

# Démarrer tous les services
echo "🚀 Démarrage de tous les services..."
docker-compose -f docker-compose.standalone-quick.yml up -d

# Vérifier le statut
echo "📊 Vérification du statut des services..."
sleep 10
docker-compose -f docker-compose.standalone-quick.yml ps

echo ""
echo "🎉 Environnement standalone avec vos données prêt !"
echo ""
echo "🌐 Services disponibles:"
echo "   • MariaDB (avec vos données): localhost:3307"
echo "   • Painter: http://localhost:8081"
echo "   • GestionCarte: http://localhost:8080"
echo ""
echo "🔍 Connexion à la base :"
echo "   mysql -h localhost -P 3307 -u ia -p dev"
echo "   docker exec -it cardmanager-mariadb-dev mysql -u ia -p dev"
echo ""
echo "📊 Commandes utiles :"
echo "   docker-compose -f docker-compose.standalone-quick.yml logs -f [service]"
echo "   docker-compose -f docker-compose.standalone-quick.yml ps"
echo "   docker-compose -f docker-compose.standalone-quick.yml down"