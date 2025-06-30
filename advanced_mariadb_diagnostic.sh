#!/bin/bash

echo "🔬 Diagnostic Avancé du Problème MariaDB"
echo "========================================"

# 1. Vérification de l'image
echo "🖼️ Vérification de l'image cardmanager-mariadb..."
if docker images | grep -q "cardmanager-mariadb"; then
    echo "✅ Image trouvée :"
    docker images | grep cardmanager-mariadb

    # Inspection des layers
    echo ""
    echo "📋 Historique de l'image :"
    docker history cardmanager-mariadb:latest --format "table {{.CreatedBy}}\t{{.Size}}"
else
    echo "❌ Image cardmanager-mariadb:latest introuvable"
    exit 1
fi

# 2. Test de l'image en mode debug
echo ""
echo "🐛 Test de l'image en mode debug..."
echo "Lancement d'un conteneur de test avec logs détaillés..."

# Créer un conteneur de test avec logs complets
docker run --rm -d \
    --name mariadb-debug-test \
    -e MYSQL_ROOT_PASSWORD=foufafou \
    -e MYSQL_DATABASE=dev \
    -e MYSQL_USER=ia \
    -e MYSQL_PASSWORD=foufafou \
    -p 3309:3306 \
    cardmanager-mariadb:latest

echo "📋 Logs de démarrage en temps réel (60 secondes)..."
timeout 60 docker logs -f mariadb-debug-test &

# Attendre et tester différentes phases
sleep 20
echo ""
echo "🔍 Test après 20 secondes..."
docker exec mariadb-debug-test ps aux || echo "Processus non accessibles"

sleep 20
echo ""
echo "🔍 Test après 40 secondes..."
if docker exec mariadb-debug-test mariadb-admin ping -h localhost -u root -pfoufafou; then
    echo "✅ MariaDB répond au ping"

    # Test de connexion complète
    if docker exec mariadb-debug-test mariadb -u root -pfoufafou -e "SHOW DATABASES;"; then
        echo "✅ Connexion root fonctionnelle"

        # Test utilisateur ia
        if docker exec mariadb-debug-test mariadb -u ia -pfoufafou -e "USE dev; SHOW TABLES LIMIT 3;"; then
            echo "✅ Utilisateur ia fonctionnel"

            # Compter les tables
            table_count=$(docker exec mariadb-debug-test mariadb -u ia -pfoufafou -e "USE dev; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='dev';" -s -N 2>/dev/null)
            echo "📊 Tables trouvées dans dev: $table_count"
        else
            echo "❌ Problème avec l'utilisateur ia"
        fi
    else
        echo "❌ Connexion root échouée"
    fi
else
    echo "❌ MariaDB ne répond pas au ping"
fi

sleep 20
echo ""
echo "🔍 Test final après 60 secondes..."

# 3. Diagnostic des fichiers de données
echo ""
echo "📁 Vérification des fichiers de données..."
docker exec mariadb-debug-test ls -la /var/lib/mysql/ | head -10

echo ""
echo "📁 Vérification des scripts d'initialisation..."
docker exec mariadb-debug-test ls -la /docker-entrypoint-initdb.d/

# 4. Vérification des logs MariaDB
echo ""
echo "📋 Logs d'erreur MariaDB..."
docker exec mariadb-debug-test cat /var/log/mysql/error.log 2>/dev/null | tail -20 || echo "Pas de logs d'erreur disponibles"

# 5. Test des variables d'environnement
echo ""
echo "🔧 Variables d'environnement du conteneur..."
docker exec mariadb-debug-test env | grep MYSQL

# 6. Test des processus
echo ""
echo "⚙️ Processus en cours..."
docker exec mariadb-debug-test ps aux

# 7. Test de la configuration
echo ""
echo "⚙️ Configuration MariaDB..."
docker exec mariadb-debug-test cat /etc/mysql/conf.d/cardmanager.cnf 2>/dev/null || echo "Fichier de config personnalisé non trouvé"

# 8. Test des ports
echo ""
echo "🔌 Ports en écoute..."
docker exec mariadb-debug-test netstat -tlnp 2>/dev/null || echo "netstat non disponible"

# 9. Inspection du health check intégré
echo ""
echo "🩺 Test du health check intégré..."
docker exec mariadb-debug-test /usr/local/bin/docker-entrypoint.sh mariadb-admin ping -h localhost -u root -pfoufafou 2>/dev/null || echo "Health check intégré échoué"

# Nettoyage
echo ""
echo "🧹 Nettoyage du conteneur de test..."
docker stop mariadb-debug-test

# 10. Recommandations
echo ""
echo "💡 RECOMMANDATIONS :"
echo "==================="

if [ "$table_count" -gt "0" ]; then
    echo "✅ Vos données sont présentes ($table_count tables)"
    echo "🔧 Le problème semble être dans le health check du docker-compose.yml"
    echo "   Lancez le script fix_health_check.sh pour corriger"
else
    echo "❌ Problème avec l'import des données"
    echo "🔧 Relancez la création de l'image : ./rebuild_custom_db.sh"
fi

echo ""
echo "📋 Pour plus d'infos sur les logs en temps réel :"
echo "   docker-compose up mariadb (sans -d pour voir les logs)"
echo ""
echo "🩺 Pour tester manuellement le health check :"
echo "   docker-compose exec mariadb mariadb-admin ping -h localhost -u root -pfoufafou"