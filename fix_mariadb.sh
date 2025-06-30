#!/bin/bash

echo "🔧 Correction du problème MariaDB"
echo "================================="

# 1. Arrêt complet
echo "🛑 Arrêt de tous les services..."
docker-compose down

# 2. Nettoyage des conteneurs échoués
echo "🧹 Nettoyage des conteneurs en erreur..."
docker container prune -f

# 3. Vérification de l'image MariaDB personnalisée
echo "🔍 Vérification de l'image cardmanager-mariadb..."
if docker images | grep -q "cardmanager-mariadb"; then
    echo "✅ Image cardmanager-mariadb trouvée"
    docker images | grep cardmanager-mariadb
else
    echo "❌ Image cardmanager-mariadb introuvable"
    echo "🔄 Recréation de l'image..."
    ./create_custom_db_image.sh
fi

# 4. Vérification du fichier .env
echo "🔍 Vérification de la configuration..."
if [ -f ".env" ]; then
    echo "✅ Fichier .env trouvé"
    grep -E "^(DB_|MYSQL_)" .env
else
    echo "❌ Fichier .env manquant"
    echo "📝 Création du fichier .env..."
    cat > .env << 'ENV_EOF'
# Base de données
DB_NAME=dev
DB_USER=ia
DB_PASSWORD=foufafou
DB_ROOT_PASSWORD=foufafou
MARIADB_PORT=3307

# Repositories GitHub
MASON_REPO_URL=https://github.com/ialame/mason
PAINTER_REPO_URL=https://github.com/ialame/painter
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511

# Token Git (optionnel)
GIT_TOKEN=
ENV_EOF
fi

# 5. Correction du docker-compose.yml pour l'image personnalisée
echo "📝 Mise à jour du docker-compose.yml..."
sed -i.backup 's/image: mariadb:11.0/image: cardmanager-mariadb:latest/' docker-compose.yml

# 6. Redémarrage en mode détaché
echo "🚀 Redémarrage des services..."
docker-compose up -d

# 7. Surveillance du démarrage
echo "👁️ Surveillance du démarrage (60 secondes)..."
timeout 60 docker-compose logs -f cardmanager-mariadb &

sleep 30

# 8. Vérification finale
echo ""
echo "🔍 Vérification finale..."
docker-compose ps
echo ""
echo "🏥 Test de santé MariaDB..."
docker-compose exec cardmanager-mariadb mariadb-admin ping -h localhost -u root -pfoufafou || echo "❌ Connexion échouée"