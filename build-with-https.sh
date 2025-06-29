#!/bin/bash

# 🔑 Build CardManager avec authentification HTTPS (tokens)

echo "🔑 Build CardManager avec HTTPS"
echo "==============================="

# Vérifier le fichier .env
if [ ! -f ".env" ]; then
    echo "❌ Fichier .env non trouvé !"
    echo "💡 Créez un fichier .env avec des URLs HTTPS :"
    cat << 'ENVEOF'
MASON_REPO_URL=https://x-token-auth:VOTRE_TOKEN@bitbucket.org/pcafxc/mason.git
PAINTER_REPO_URL=https://x-token-auth:VOTRE_TOKEN@bitbucket.org/pcafxc/painter.git
GESTIONCARTE_REPO_URL=https://x-token-auth:VOTRE_TOKEN@bitbucket.org/pcafxc/gestioncarte.git
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main
GIT_TOKEN=
ENVEOF
    exit 1
fi

# Charger les variables
source .env

echo "📋 Configuration détectée :"
echo "   Mason: ${MASON_REPO_URL:0:50}..."
echo "   Painter: ${PAINTER_REPO_URL:0:50}..."
echo "   GestionCarte: ${GESTIONCARTE_REPO_URL:0:50}..."
echo ""

# Vérifier les URLs HTTPS
if [[ "$MASON_REPO_URL" != https://* ]]; then
    echo "⚠️ MASON_REPO_URL n'est pas une URL HTTPS"
    echo "   Actuel: $MASON_REPO_URL"
    echo "   Attendu: https://x-token-auth:TOKEN@bitbucket.org/workspace/repo.git"
fi

# Test du token si présent
if [[ "$MASON_REPO_URL" == *"x-token-auth:"* ]]; then
    echo "🧪 Test de l'authentification token..."
    token=$(echo "$MASON_REPO_URL" | sed 's/.*x-token-auth:\([^@]*\)@.*/\1/')
    
    if git ls-remote --heads "$MASON_REPO_URL" >/dev/null 2>&1; then
        echo "✅ Token fonctionne"
    else
        echo "❌ Token ne fonctionne pas"
        echo "💡 Vérifiez votre token sur :"
        echo "   https://bitbucket.org/account/settings/app-passwords/"
        exit 1
    fi
fi

echo ""
echo "🔨 Lancement du build avec HTTPS..."

# Nettoyer l'environnement existant
docker-compose down --volumes --remove-orphans 2>/dev/null

# Build avec HTTPS
if docker-compose build --no-cache; then
    echo ""
    echo "🎉 BUILD RÉUSSI avec HTTPS !"
    echo ""
    echo "🚀 Démarrage des services..."
    docker-compose up -d
    
    echo ""
    echo "📱 Services accessibles :"
    echo "   🖼️ Application : http://localhost:8080"
    echo "   🎨 Painter : http://localhost:8081"
    echo "   🌐 Images : http://localhost:8082"
else
    echo ""
    echo "❌ BUILD ÉCHOUÉ"
    echo ""
    echo "🔍 Diagnostics possibles :"
    echo "1. Vérifiez le token Bitbucket"
    echo "2. Vérifiez les URLs dans .env"
    echo "3. Vérifiez les permissions du token"
    echo "4. Consultez les logs : docker-compose logs"
    exit 1
fi
