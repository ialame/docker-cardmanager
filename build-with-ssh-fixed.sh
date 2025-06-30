#!/bin/bash

# 🔑 Build CardManager avec SSH Bitbucket - Version Corrigée

echo "🔑 Build CardManager avec SSH (Version Corrigée)"
echo "================================================"

# Vérifications préliminaires
if [ ! -f ".env" ]; then
    echo "❌ Fichier .env manquant !"
    echo "💡 Créez un fichier .env avec :"
    cat << 'ENVEOF'
# Configuration SSH Bitbucket
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511
GIT_TOKEN=
DB_NAME=dev
DB_USER=ia
DB_PASSWORD=foufafou
DB_ROOT_PASSWORD=root_password
GESTIONCARTE_PORT=8080
PAINTER_PORT=8081
NGINX_PORT=8082
MARIADB_PORT=3307
ENVEOF
    exit 1
fi

# Détecter et encoder la clé SSH
SSH_KEY_FILE=""
if [ -f ~/.ssh/bitbucket_ed25519 ]; then
    SSH_KEY_FILE=~/.ssh/bitbucket_ed25519
else
    echo "❌ Aucune clé SSH trouvée !"
    echo "💡 Créez une clé SSH :"
    echo "   ssh-keygen -t ed25519 -C 'votre.email@domain.com'"
    echo "   ssh-add ~/.ssh/id_ed25519"
    echo "   # Puis ajoutez la clé publique sur Bitbucket"
    exit 1
fi

echo "🔑 Clé SSH détectée : $SSH_KEY_FILE"

# Encoder la clé SSH
export SSH_PRIVATE_KEY=$(cat "$SSH_KEY_FILE" | base64 -w 0 2>/dev/null || cat "$SSH_KEY_FILE" | base64)

if [ -z "$SSH_PRIVATE_KEY" ]; then
    echo "❌ Erreur lors de l'encodage de la clé SSH"
    exit 1
fi

echo "✅ Clé SSH encodée (${#SSH_PRIVATE_KEY} caractères)"

# Test de connexion SSH
echo "🧪 Test de connexion SSH..."
if ssh -T git@bitbucket.org -o ConnectTimeout=5 -o BatchMode=yes 2>&1 | grep -q "logged in as"; then
    echo "✅ Connexion SSH OK"
else
    echo "❌ Connexion SSH échouée"
    echo "💡 Vérifiez :"
    echo "   1. Que votre clé SSH est ajoutée sur Bitbucket"
    echo "   2. Que ssh-agent est lancé : eval \$(ssh-agent -s) && ssh-add $SSH_KEY_FILE"
    echo "   3. Test manuel : ssh -T git@bitbucket.org"
    exit 1
fi

# Source du fichier .env
source .env

echo ""
echo "📋 Configuration :"
echo "   Mason: $MASON_REPO_URL"
echo "   Painter: $PAINTER_REPO_URL"
echo "   GestionCarte: $GESTIONCARTE_REPO_URL"

# Nettoyer l'environnement
echo ""
echo "🧹 Nettoyage..."
docker-compose down --volumes --remove-orphans 2>/dev/null

# Build avec SSH
echo ""
echo "🔨 Lancement du build avec SSH..."
if docker-compose build --no-cache; then
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

else
    echo ""
    echo "❌ BUILD ÉCHOUÉ !"
    echo ""
    echo "🔍 Diagnostics :"
    echo "1. Vérifiez les logs : docker-compose logs"
    echo "2. Vérifiez SSH : ssh -T git@bitbucket.org"
    echo "3. Vérifiez les branches dans .env"
    echo "4. Vérifiez que openssh-client est installé dans les Dockerfiles"
    exit 1
fi
