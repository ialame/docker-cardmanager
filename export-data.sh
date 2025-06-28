#!/bin/bash
set -e

echo "📦 Export des données depuis localhost:3306/dev..."

# Créer le répertoire pour les données
mkdir -p init-db

# Variables de connexion
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="dev"
DB_USER="ia"
DB_PASSWORD="foufafou"

echo "🔍 Test de connexion à la base source..."
if ! mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD -e "SELECT 'Connexion réussie!' AS message;" $DB_NAME 2>/dev/null; then
    echo "❌ Erreur: Impossible de se connecter à $DB_HOST:$DB_PORT/$DB_NAME"
    echo "💡 Vérifiez que votre MySQL/MariaDB local fonctionne"
    echo "💡 Commandes pour démarrer MySQL local :"
    echo "   macOS: brew services start mysql"
    echo "   Linux: sudo service mysql start"
    exit 1
fi

echo "✅ Connexion à la base source réussie"

# Export du schéma (structure)
echo "📋 Export de la structure de la base..."
mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD \
    --no-data \
    --routines \
    --triggers \
    --events \
    --single-transaction \
    --quick \
    --lock-tables=false \
    $DB_NAME > init-db/01-schema.sql

echo "✅ Structure exportée vers init-db/01-schema.sql"

# Export des données
echo "📊 Export des données..."
mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD \
    --no-create-info \
    --complete-insert \
    --single-transaction \
    --quick \
    --lock-tables=false \
    --hex-blob \
    $DB_NAME > init-db/02-data.sql

echo "✅ Données exportées vers init-db/02-data.sql"

# Créer un script d'initialisation personnalisé
cat > init-db/00-init.sql << 'EOF'
-- Script d'initialisation pour l'environnement de développement
-- Créé automatiquement depuis localhost:3306/dev

-- Configuration initiale
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

-- Créer la base si elle n'existe pas
CREATE DATABASE IF NOT EXISTS dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE dev;

-- Configuration MariaDB optimisée pour le développement
SET GLOBAL innodb_buffer_pool_size = 268435456;  -- 256MB
SET GLOBAL max_connections = 200;

-- Message de confirmation
SELECT 'Base de données dev initialisée avec succès depuis localhost!' AS message;
EOF

echo "✅ Script d'initialisation créé"

# Vérifier les fichiers créés
echo ""
echo "📋 Fichiers d'export créés :"
ls -la init-db/
echo ""

# Calculer la taille des données
schema_size=$(wc -l < init-db/01-schema.sql)
data_size=$(wc -l < init-db/02-data.sql)

echo "📊 Statistiques :"
echo "   • Structure : $schema_size lignes"
echo "   • Données : $data_size lignes"
echo ""

if [ $data_size -gt 0 ]; then
    echo "✅ Export terminé avec succès !"
    echo "💡 Vous pouvez maintenant lancer : ./build-standalone-with-data.sh"
else
    echo "⚠️  Aucune donnée trouvée. La base est-elle vide ?"
    echo "💡 Vous pouvez quand même continuer avec la structure seule"
fi