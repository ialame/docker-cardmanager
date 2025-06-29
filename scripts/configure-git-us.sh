#!/bin/bash

# 🔧 Automatic Git repository configuration for CardManager

echo "🔧 CardManager Git Repository Configuration"
echo "==========================================="

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  The .env file already exists."
    read -p "Do you want to replace it? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "❌ Configuration cancelled."
        exit 0
    fi
fi

# Copy template
cp .env.template .env

echo ""
echo "📝 Git repository URLs configuration:"
echo ""

# Mason Repository
read -p "🔧 Mason repository URL [https://github.com/ialame/mason]: " mason_url
mason_url=${mason_url:-https://github.com/ialame/mason}
sed -i "s|MASON_REPO_URL=.*|MASON_REPO_URL=$mason_url|" .env

# Painter Repository
read -p "🎨 Painter repository URL [https://github.com/ialame/painter]: " painter_url
painter_url=${painter_url:-https://github.com/ialame/painter}
sed -i "s|PAINTER_REPO_URL=.*|PAINTER_REPO_URL=$painter_url|" .env

# GestionCarte Repository
read -p "💳 GestionCarte repository URL [https://github.com/ialame/gestioncarte]: " gestion_url
gestion_url=${gestion_url:-https://github.com/ialame/gestioncarte}
sed -i "s|GESTIONCARTE_REPO_URL=.*|GESTIONCARTE_REPO_URL=$gestion_url|" .env

echo ""
echo "🌿 Branch configuration (optional):"

# Branches
read -p "🔧 Mason branch [main]: " mason_branch
mason_branch=${mason_branch:-main}
sed -i "s|MASON_BRANCH=.*|MASON_BRANCH=$mason_branch|" .env

read -p "🎨 Painter branch [main]: " painter_branch
painter_branch=${painter_branch:-main}
sed -i "s|PAINTER_BRANCH=.*|PAINTER_BRANCH=$painter_branch|" .env

read -p "💳 GestionCarte branch [main]: " gestion_branch
gestion_branch=${gestion_branch:-main}
sed -i "s|GESTIONCARTE_BRANCH=.*|GESTIONCARTE_BRANCH=$gestion_branch|" .env

echo ""
echo "🔐 Git authentication configuration:"
echo "ℹ️  Leave empty if your repositories are public"
echo "ℹ️  For private repositories, use a personal access token"
echo ""

read -p "🔑 Git token (ghp_xxx or ATBB-xxx) [optional]: " git_token
if [ ! -z "$git_token" ]; then
    sed -i "s|GIT_TOKEN=.*|GIT_TOKEN=$git_token|" .env
fi

echo ""
echo "✅ Configuration completed!"
echo ""
echo "📁 .env file created with:"
echo "   🔧 Mason: $mason_url ($mason_branch)"
echo "   🎨 Painter: $painter_url ($painter_branch)"
echo "   💳 GestionCarte: $gestion_url ($gestion_branch)"
if [ ! -z "$git_token" ]; then
    echo "   🔑 Token: ${git_token:0:10}..."
fi
echo ""
echo "🚀 Ready for deployment!"
echo "   Run: ./build-quick-standalone.sh"
