#!/bin/bash

# 🔧 Configuration automatique des dépôts Git pour CardManager

echo "🔧 Configuration des dépôts Git CardManager"
echo "==========================================="

# Vérifier si .env existe déjà
if [ -f ".env" ]; then
    echo "⚠️  Le fichier .env existe déjà."
    read -p "Voulez-vous le remplacer ? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "❌ Configuration annulée."
        exit 0
    fi
fi

# Copier le template
cp .env.template .env

echo ""
echo "📝 Configuration des URLs des dépôts Git:"
echo ""

# Mason Repository
read -p "🔧 URL du dépôt Mason [https://github.com/ialame/mason]: " mason_url
mason_url=${mason_url:-https://github.com/ialame/mason}
sed -i "s|MASON_REPO_URL=.*|MASON_REPO_URL=$mason_url|" .env

# Painter Repository
read -p "🎨 URL du dépôt Painter [https://github.com/ialame/painter]: " painter_url
painter_url=${painter_url:-https://github.com/ialame/painter}
sed -i "s|PAINTER_REPO_URL=.*|PAINTER_REPO_URL=$painter_url|" .env

# GestionCarte Repository
read -p "💳 URL du dépôt GestionCarte [https://github.com/ialame/gestioncarte]: " gestion_url
gestion_url=${gestion_url:-https://github.com/ialame/gestioncarte}
sed -i "s|GESTIONCARTE_REPO_URL=.*|GESTIONCARTE_REPO_URL=$gestion_url|" .env

echo ""
echo "🌿 Configuration des branches (optionnel):"

# Branches
read -p "🔧 Branche Mason [main]: " mason_branch
mason_branch=${mason_branch:-main}
sed -i "s|MASON_BRANCH=.*|MASON_BRANCH=$mason_branch|" .env

read -p "🎨 Branche Painter [main]: " painter_branch
painter_branch=${painter_branch:-main}
sed -i "s|PAINTER_BRANCH=.*|PAINTER_BRANCH=$painter_branch|" .env

read -p "💳 Branche GestionCarte [main]: " gestion_branch
gestion_branch=${gestion_branch:-main}
sed -i "s|GESTIONCARTE_BRANCH=.*|GESTIONCARTE_BRANCH=$gestion_branch|" .env

echo ""
echo "🔐 Configuration de l'authentification Git:"
echo "ℹ️  Laissez vide si vos dépôts sont publics"
echo "ℹ️  Pour dépôts privés, utilisez un token d'accès personnel"
echo ""

read -p "🔑 Token Git (ghp_xxx ou ATBB-xxx) [optionnel]: " git_token
if [ ! -z "$git_token" ]; then
    sed -i "s|GIT_TOKEN=.*|GIT_TOKEN=$git_token|" .env
fi

echo ""
echo "✅ Configuration terminée !"
echo ""
echo "📁 Fichier .env créé avec:"
echo "   🔧 Mason: $mason_url ($mason_branch)"
echo "   🎨 Painter: $painter_url ($painter_branch)"
echo "   💳 GestionCarte: $gestion_url ($gestion_branch)"
if [ ! -z "$git_token" ]; then
    echo "   🔑 Token: ${git_token:0:10}..."
fi
echo ""
echo "🚀 Prêt pour le déploiement !"
echo "   Lancez: ./build-quick-standalone.sh"
