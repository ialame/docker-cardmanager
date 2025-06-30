#!/bin/bash

# 🎨 Build CardManager avec Dépendances Corrigées

echo "🎨 Build CardManager avec Dépendances Corrigées"
echo "==============================================="

# Vérifications
if [ ! -f ".env" ]; then
    echo "❌ Fichier .env manquant !"
    exit 1
fi

# Détecter la clé SSH
SSH_KEY_FILE=""
for key_file in ~/.ssh/bitbucket_ed25519 ~/.ssh/id_ed25519 ~/.ssh/id_rsa; do
    if [ -f "$key_file" ]; then
        SSH_KEY_FILE="$key_file"
        break
    fi
done

if [ -z "$SSH_KEY_FILE" ]; then
    echo "❌ Aucune clé SSH trouvée !"
    exit 1
fi

echo "🔑 Clé SSH : $SSH_KEY_FILE"

# Encoder la clé SSH
export SSH_PRIVATE_KEY=$(cat "$SSH_KEY_FILE" | base64 -w 0 2>/dev/null || cat "$SSH_KEY_FILE" | base64)
echo "✅ Clé SSH encodée"

# Test SSH
echo "🧪 Test SSH..."
if ! ssh -T git@bitbucket.org -o ConnectTimeout=5 -o BatchMode=yes 2>&1 | grep -q "logged in as"; then
    echo "❌ SSH ne fonctionne pas"
    exit 1
fi
echo "✅ SSH OK"

# Source de la configuration
source .env
echo "📋 Configuration :"
echo "   Mason: $MASON_REPO_URL"
echo "   Painter: $PAINTER_REPO_URL"

# Nettoyer uniquement les images cassées
echo "🧹 Nettoyage sélectif..."
docker image prune -f
docker container prune -f

# Build avec logs détaillés
echo "🔨 Build avec dependencyManagement complet..."
if docker-compose build --no-cache --progress=plain; then
    echo ""
    echo "🎉 BUILD RÉUSSI !"
    echo ""
    echo "🚀 Démarrage des services..."
    docker-compose up -d

    echo ""
    echo "✅ Services démarrés !"
    echo "   📱 GestionCarte : http://localhost:${GESTIONCARTE_PORT:-8080}"
    echo "   🎨 Painter : http://localhost:${PAINTER_PORT:-8081}"
    echo "   🗄️ MariaDB : localhost:${MARIADB_PORT:-3307}"

    echo ""
    echo "🔍 Status des services :"
    docker-compose ps

else
    echo ""
    echo "❌ BUILD ÉCHOUÉ !"
    echo ""
    echo "🔍 Diagnostics :"
    echo "1. Vérifiez les logs détaillés ci-dessus"
    echo "2. Les versions Mason sont maintenant dans dependencyManagement"
    echo "3. Retry automatique activé"
    echo "4. Relancez le script si problème temporaire"
    exit 1
fi
