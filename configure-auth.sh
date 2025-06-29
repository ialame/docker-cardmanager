#!/bin/bash

# 🔧 Configurateur automatique d'authentification Git

echo "🔧 Configurateur d'authentification Git"
echo "======================================="

echo ""
echo "🤔 Quel type d'authentification voulez-vous utiliser ?"
echo ""
echo "1️⃣ SSH (recommandé pour développement)"
echo "2️⃣ HTTPS avec token (pour CI/CD)"
echo "3️⃣ Détecter automatiquement"
echo ""

read -p "Votre choix (1-3): " auth_choice

case $auth_choice in
    1)
        echo ""
        echo "🔑 Configuration SSH sélectionnée"
        
        # Vérifier les clés SSH
        if [ -f ~/.ssh/id_ed25519 ] || [ -f ~/.ssh/id_rsa ]; then
            echo "✅ Clé SSH trouvée"
            
            # Créer .env SSH
            cat > .env << 'SSHEOF'
# Configuration SSH pour Bitbucket
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main
GIT_TOKEN=
DB_NAME=dev
DB_USER=ia
DB_PASSWORD=foufafou
DB_ROOT_PASSWORD=root_password
GESTIONCARTE_PORT=8080
PAINTER_PORT=8081
NGINX_PORT=8082
MARIADB_PORT=3307
SSHEOF
            
            echo "✅ Fichier .env créé pour SSH"
            echo ""
            echo "🔑 Votre clé publique (à ajouter sur Bitbucket) :"
            cat ~/.ssh/bitbucket_ed25519.pub 2>/dev/null || cat ~/.ssh/bitbucket_ed25519.pub 2>/dev/null
            echo ""
            echo "📋 Ajoutez cette clé sur :"
            echo "   https://bitbucket.org/account/settings/ssh-keys/"
            echo ""
            echo "🚀 Pour builder : ./build-with-ssh.sh"
            
        else
            echo "❌ Aucune clé SSH trouvée"
            echo "💡 Créez une clé SSH :"
            echo "   ssh-keygen -t ed25519 -C 'votre-email@example.com'"
        fi
        ;;
        
    2)
        echo ""
        echo "🔑 Configuration HTTPS avec token"
        
        read -p "🔑 Votre token Bitbucket (ATBB-xxx): " bitbucket_token
        
        if [ ! -z "$bitbucket_token" ]; then
            cat > .env << HTTPSEOF
# Configuration HTTPS avec token pour Bitbucket
MASON_REPO_URL=https://x-token-auth:${bitbucket_token}@bitbucket.org/pcafxc/mason.git
PAINTER_REPO_URL=https://x-token-auth:${bitbucket_token}@bitbucket.org/pcafxc/painter.git
GESTIONCARTE_REPO_URL=https://x-token-auth:${bitbucket_token}@bitbucket.org/pcafxc/gestioncarte.git
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main
GIT_TOKEN=
DB_NAME=dev
DB_USER=ia
DB_PASSWORD=foufafou
DB_ROOT_PASSWORD=root_password
GESTIONCARTE_PORT=8080
PAINTER_PORT=8081
NGINX_PORT=8082
MARIADB_PORT=3307
HTTPSEOF
            
            echo "✅ Fichier .env créé pour HTTPS"
            echo "🚀 Pour builder : ./build-with-https.sh"
        else
            echo "❌ Token requis pour HTTPS"
        fi
        ;;
        
    3)
        echo ""
        echo "🔍 Détection automatique..."
        
        # Test SSH
        if ssh -T git@bitbucket.org -o ConnectTimeout=3 -o BatchMode=yes 2>&1 | grep -q "logged in as"; then
            echo "✅ SSH fonctionne, configuration SSH"
            $0 1  # Récursion avec choix SSH
        else
            echo "⚠️ SSH ne fonctionne pas, configuration HTTPS recommandée"
            $0 2  # Récursion avec choix HTTPS
        fi
        ;;
        
    *)
        echo "❌ Choix invalide"
        exit 1
        ;;
esac
