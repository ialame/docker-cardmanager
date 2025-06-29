#!/bin/bash

# 🔑 Build CardManager avec authentification SSH

echo "🔑 Build CardManager avec SSH"
echo "=============================="

# Vérifier que la clé SSH existe
if [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "❌ Aucune clé SSH trouvée !"
    echo "💡 Créez une clé SSH avec :"
    echo "   ssh-keygen -t ed25519 -C 'r.alhajjaj@pcagrade.fr'"
    echo "   ssh-add ~/.ssh/bitbucket_ed25519"
    echo "   # Puis ajoutez-la sur Bitbucket"
    exit 1
fi

# Détecter la clé SSH
SSH_KEY_FILE=""
if [ -f ~/.ssh/bitbucket_ed25519 ]; then
    SSH_KEY_FILE=~/.ssh/bitbucket_ed25519
else
    echo "❌ Clé SSH non trouvée"
    exit 1
fi

echo "🔑 Utilisation de la clé SSH: $SSH_KEY_FILE"

# Encoder la clé SSH en base64
echo "🔧 Encodage de la clé SSH..."
export SSH_PRIVATE_KEY=$(cat "$SSH_KEY_FILE" | base64 -w 0 2>/dev/null || cat "$SSH_KEY_FILE" | base64)

if [ -z "$SSH_PRIVATE_KEY" ]; then
    echo "❌ Erreur lors de l'encodage de la clé SSH"
    exit 1
fi

echo "✅ Clé SSH encodée (${#SSH_PRIVATE_KEY} caractères)"

# Vérifier le fichier .env
if [ ! -f ".env" ]; then
    echo "❌ Fichier .env non trouvé !"
    echo "💡 Créez un fichier .env avec des URLs SSH :"
    cat << 'ENVEOF'
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main
GIT_TOKEN=
ENVEOF
    exit 1
fi

# Vérifier que les URLs sont SSH
echo "🔍 Vérification des URLs..."
source .env

if [[ "$MASON_REPO_URL" != git@* ]]; then
    echo "⚠️ MASON_REPO_URL n'est pas une URL SSH"
    echo "   Actuel: $MASON_REPO_URL"
    echo "   Attendu: git@bitbucket.org:workspace/repo.git"
fi

echo ""
echo "📋 Configuration détectée :"
echo "   Mason: $MASON_REPO_URL"
echo "   Painter: $PAINTER_REPO_URL"
echo "   GestionCarte: $GESTIONCARTE_REPO_URL"
echo ""

# Test SSH avant build
echo "🧪 Test de connexion SSH..."
if ssh -T git@bitbucket.org -o ConnectTimeout=5 -o BatchMode=yes 2>&1 | grep -q "logged in as\|authenticated"; then
    echo "✅ Connexion SSH OK"
else
    echo "❌ Connexion SSH échouée"
    echo "💡 Vérifiez que votre clé SSH est ajoutée sur Bitbucket :"
    echo "   https://bitbucket.org/account/settings/ssh-keys/"
    echo ""
    echo "🔑 Votre clé publique :"
    cat "${SSH_KEY_FILE}.pub" 2>/dev/null || echo "Fichier .pub non trouvé"
    exit 1
fi

echo ""
echo "🔨 Lancement du build avec SSH..."

# Nettoyer l'environnement existant
docker-compose down --volumes --remove-orphans 2>/dev/null

# Build avec la clé SSH
if docker-compose build --no-cache; then
    echo ""
    echo "🎉 BUILD RÉUSSI avec SSH !"
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
    echo "1. Vérifiez la connexion SSH : ssh -T git@bitbucket.org"
    echo "2. Vérifiez les URLs dans .env"
    echo "3. Vérifiez que les branches existent"
    echo "4. Consultez les logs : docker-compose logs"
    exit 1
fi
