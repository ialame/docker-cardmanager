#!/bin/bash

echo "🔄 Reconstruction complète de l'image MariaDB personnalisée"
echo "=========================================================="

# 1. Arrêt et nettoyage complet
echo "🛑 Arrêt et nettoyage..."
docker-compose down --volumes --remove-orphans
docker image rm cardmanager-mariadb:latest 2>/dev/null || true

# 2. Vérification de la base locale
echo "🔍 Test de la base de données locale..."
mysql -h localhost -P 3306 -u ia -pfoufafou -e "USE dev; SELECT COUNT(*) AS tables_count FROM information_schema.tables WHERE table_schema='dev';" 2>/dev/null || {
    echo "❌ Impossible de se connecter à localhost:3306/dev"
    echo "   Vérifiez que votre MariaDB local fonctionne :"
    echo "   - Service démarré : brew services start mariadb"
    echo "   - Port 3306 ouvert"
    echo "   - Utilisateur ia/foufafou configuré"
    exit 1
}

# 3. Recréation de l'image avec verbose
echo "🔨 Recréation de l'image MariaDB personnalisée..."

# Création du répertoire de travail
mkdir -p custom-db-build/initdb

# Export de la base avec plus d'options
echo "📤 Export détaillé de la base..."
mysqldump -h localhost -P 3306 -u ia -pfoufafou \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --add-drop-database \
    --databases dev > custom-db-build/initdb/01-structure-and-data.sql

# Création du script utilisateur
cat > custom-db-build/initdb/02-create-user.sql << 'SQL_EOF'
-- Création de l'utilisateur ia
CREATE USER IF NOT EXISTS 'ia'@'%' IDENTIFIED BY 'foufafou';
GRANT ALL PRIVILEGES ON dev.* TO 'ia'@'%';
GRANT ALL PRIVILEGES ON dev.* TO 'ia'@'localhost';
FLUSH PRIVILEGES;

-- Vérification
SELECT User, Host FROM mysql.user WHERE User = 'ia';
SHOW GRANTS FOR 'ia'@'%';
SQL_EOF

# Dockerfile optimisé
cat > custom-db-build/Dockerfile << 'DOCKER_EOF'
FROM mariadb:11.0

# Copie des scripts d'initialisation
COPY initdb/ /docker-entrypoint-initdb.d/

# Permissions des scripts
RUN chmod -R 755 /docker-entrypoint-initdb.d/

# Configuration MariaDB optimisée
RUN echo '[mysqld]' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'character-set-server=utf8mb4' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'collation-server=utf8mb4_unicode_ci' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'max_connections=200' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'innodb_buffer_pool_size=256M' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'innodb_log_file_size=64M' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'innodb_flush_log_at_trx_commit=2' >> /etc/mysql/conf.d/cardmanager.cnf

# Variables d'environnement par défaut
ENV MYSQL_ROOT_PASSWORD=foufafou
ENV MYSQL_DATABASE=dev
ENV MYSQL_USER=ia
ENV MYSQL_PASSWORD=foufafou

# Health check personnalisé
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD mariadb-admin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD || exit 1

EXPOSE 3306
DOCKER_EOF

# Construction de l'image
echo "🏗️ Construction de l'image..."
cd custom-db-build
docker build -t cardmanager-mariadb:latest . --no-cache

# Retour au répertoire principal
cd ..

# Test de l'image
echo "🧪 Test de l'image..."
docker run --rm -d \
    --name test-mariadb \
    -e MYSQL_ROOT_PASSWORD=foufafou \
    -e MYSQL_DATABASE=dev \
    -e MYSQL_USER=ia \
    -e MYSQL_PASSWORD=foufafou \
    -p 3308:3306 \
    cardmanager-mariadb:latest

# Attendre le démarrage
echo "⏳ Attente du démarrage de test..."
sleep 30

# Test de connexion
echo "🔍 Test de connexion..."
docker exec test-mariadb mariadb -u ia -pfoufafou -e "USE dev; SHOW TABLES LIMIT 5;"

# Nettoyage du test
docker stop test-mariadb

echo "✅ Image cardmanager-mariadb:latest créée et testée avec succès !"
echo ""
echo "🚀 Vous pouvez maintenant relancer :"
echo "   docker-compose up -d"