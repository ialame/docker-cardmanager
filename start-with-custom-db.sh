#!/bin/bash

echo "🚀 Démarrage de CardManager avec Base Personnalisée"
echo "=================================================="

# Vérifier que l'image existe
if ! docker images | grep -q "cardmanager-mariadb"; then
    echo "❌ Image cardmanager-mariadb non trouvée !"
    echo "💡 Lancez d'abord : ./create_custom_db_image.sh"
    exit 1
fi

# Ajouter la clé SSH
if [ -z "$SSH_PRIVATE_KEY" ]; then
    echo "🔑 Configuration de la clé SSH..."
    SSH_KEY_FILE=""
    for key_file in ~/.ssh/bitbucket_ed25519 ~/.ssh/id_ed25519 ~/.ssh/id_rsa; do
        if [ -f "$key_file" ]; then
            SSH_KEY_FILE="$key_file"
            break
        fi
    done

    if [ ! -z "$SSH_KEY_FILE" ]; then
        export SSH_PRIVATE_KEY=$(cat "$SSH_KEY_FILE" | base64 -w 0 2>/dev/null || cat "$SSH_KEY_FILE" | base64)
        sed -i "s/SSH_PRIVATE_KEY=.*/SSH_PRIVATE_KEY=$SSH_PRIVATE_KEY/" .env
        echo "✅ Clé SSH configurée"
    fi
fi

# Nettoyer l'environnement précédent
echo "🧹 Nettoyage..."
docker-compose down --volumes 2>/dev/null

# Démarrer avec la base personnalisée
echo "🚀 Démarrage complet avec base personnalisée..."
docker-compose up -d

echo ""
echo "✅ CardManager démarré avec votre base de données !"
echo ""
echo "🔗 Services disponibles :"
echo "   📱 GestionCarte : http://localhost:8080"
echo "   🎨 Painter : http://localhost:8081"
echo "   🖼️ Images : http://localhost:8082"
echo "   🗄️ MariaDB : localhost:3307"
echo ""
echo "🔍 Suivi des logs :"
echo "   docker-compose logs -f"
