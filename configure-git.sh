#!/bin/bash
set -e

echo "🔧 Configuration Git pour CardManager"
echo "======================================="

# Créer le fichier .env s'il n'existe pas
if [ ! -f .env ]; then
    echo "📝 Création du fichier .env depuis le template..."
    cp .env.template .env
    echo "✅ Fichier .env créé depuis .env.template"
    echo ""
fi

echo "🤔 Quel type de dépôt Git utilisez-vous ?"
echo "1. GitHub public (par défaut)"
echo "2. GitHub privé avec token"
echo "3. Bitbucket privé avec token"
echo "4. Configuration manuelle"
echo ""

read -p "Votre choix (1-4) [1]: " choice
choice=${choice:-1}

case $choice in
    1)
        echo "📝 Configuration pour GitHub public..."
        echo "💡 Gardez les valeurs par défaut dans .env"
        echo ""
        echo "✅ Configuration terminée - dépôts GitHub publics"
        ;;
    2)
        echo "📝 Configuration pour GitHub privé..."
        echo ""
        read -p "URL du dépôt Mason: " mason_url
        read -p "URL du dépôt Painter: " painter_url
        read -p "URL du dépôt GestionCarte: " gestioncarte_url
        read -p "Token GitHub (ghp_xxx): " git_token
        read -p "Branche Mason [main]: " mason_branch
        read -p "Branche Painter [main]: " painter_branch
        read -p "Branche GestionCarte [main]: " gestioncarte_branch

        mason_branch=${mason_branch:-main}
        painter_branch=${painter_branch:-main}
        gestioncarte_branch=${gestioncarte_branch:-main}

        # Mettre à jour le .env
        sed -i.bak "s|MASON_REPO_URL=.*|MASON_REPO_URL=$mason_url|" .env
        sed -i.bak "s|PAINTER_REPO_URL=.*|PAINTER_REPO_URL=$painter_url|" .env
        sed -i.bak "s|GESTIONCARTE_REPO_URL=.*|GESTIONCARTE_REPO_URL=$gestioncarte_url|" .env
        sed -i.bak "s|MASON_BRANCH=.*|MASON_BRANCH=$mason_branch|" .env
        sed -i.bak "s|PAINTER_BRANCH=.*|PAINTER_BRANCH=$painter_branch|" .env
        sed -i.bak "s|GESTIONCARTE_BRANCH=.*|GESTIONCARTE_BRANCH=$gestioncarte_branch|" .env
        sed -i.bak "s|GIT_TOKEN=.*|GIT_TOKEN=$git_token|" .env
        rm -f .env.bak

        echo ""
        echo "✅ Configuration GitHub privé terminée"
        ;;
    3)
        echo "📝 Configuration pour Bitbucket privé..."
        echo ""
        read -p "URL du dépôt Mason: " mason_url
        read -p "URL du dépôt Painter: " painter_url
        read -p "URL du dépôt GestionCarte: " gestioncarte_url
        read -p "Token Bitbucket (ATBB-xxx): " git_token
        read -p "Branche Mason [main]: " mason_branch
        read -p "Branche Painter [main]: " painter_branch
        read -p "Branche GestionCarte [main]: " gestioncarte_branch

        mason_branch=${mason_branch:-main}
        painter_branch=${painter_branch:-main}
        gestioncarte_branch=${gestioncarte_branch:-main}

        # Mettre à jour le .env
        sed -i.bak "s|MASON_REPO_URL=.*|MASON_REPO_URL=$mason_url|" .env
        sed -i.bak "s|PAINTER_REPO_URL=.*|PAINTER_REPO_URL=$painter_url|" .env
        sed -i.bak "s|GESTIONCARTE_REPO_URL=.*|GESTIONCARTE_REPO_URL=$gestioncarte_url|" .env
        sed -i.bak "s|MASON_BRANCH=.*|MASON_BRANCH=$mason_branch|" .env
        sed -i.bak "s|PAINTER_BRANCH=.*|PAINTER_BRANCH=$painter_branch|" .env
        sed -i.bak "s|GESTIONCARTE_BRANCH=.*|GESTIONCARTE_BRANCH=$gestioncarte_branch|" .env
        sed -i.bak "s|GIT_TOKEN=.*|GIT_TOKEN=$git_token|" .env
        rm -f .env.bak

        echo ""
        echo "✅ Configuration Bitbucket privé terminée"
        ;;
    4)
        echo "📝 Configuration manuelle..."
        echo "💡 Éditez le fichier .env avec vos valeurs personnalisées"
        echo "📄 Utilisez .env.template comme référence"
        echo ""
        echo "📋 Format des URLs :"
        echo "   GitHub: https://github.com/username/repo.git"
        echo "   Bitbucket: https://bitbucket.org/username/repo.git"
        ;;
    *)
        echo "❌ Choix invalide"
        exit 1
        ;;
esac

echo ""
echo "📋 Vérifiez votre configuration :"
echo "   cat .env"
echo ""
echo "🚀 Pour construire et démarrer :"
echo "   docker-compose build --no-cache"
echo "   docker-compose up -d"
echo ""
echo "🔍 En cas de problème d'authentification :"
echo "   - GitHub: Vérifiez que votre token commence par 'ghp_'"
echo "   - Bitbucket: Vérifiez que votre token commence par 'ATBB-'"
echo "   - Vérifiez que les URLs des dépôts sont correctes"
echo "   - Consultez TROUBLESHOOTING.md"