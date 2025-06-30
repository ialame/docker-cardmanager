#!/bin/bash

echo "🔧 Correction des URLs Git"
echo "=========================="

# 1. Vérifier le fichier .env actuel
echo "📋 Configuration Git actuelle :"
if [ -f ".env" ]; then
    echo "✅ Fichier .env trouvé"

    echo ""
    echo "URLs actuelles :"
    grep -E "^(MASON_REPO_URL|PAINTER_REPO_URL|GESTIONCARTE_REPO_URL)" .env || echo "Aucune URL trouvée"

    echo ""
    echo "Branches actuelles :"
    grep -E "^(MASON_BRANCH|PAINTER_BRANCH|GESTIONCARTE_BRANCH)" .env || echo "Aucune branche trouvée"
else
    echo "❌ Fichier .env non trouvé"
fi

echo ""
echo "🔍 Problème identifié : URLs SSH au lieu d'URLS HTTPS"
echo "💡 Docker ne peut pas utiliser les clés SSH, nous devons convertir en HTTPS"

# 2. Conversion des URLs SSH vers HTTPS
echo ""
echo "🔄 Conversion des URLs SSH vers HTTPS..."

# Sauvegarder le .env actuel
cp .env .env.backup-$(date +%s)
echo "💾 Sauvegarde créée : .env.backup-*"

# Fonction pour convertir une URL SSH en HTTPS
convert_ssh_to_https() {
    local ssh_url="$1"

    if [[ "$ssh_url" == git@bitbucket.org:* ]]; then
        # Bitbucket SSH vers HTTPS
        repo_path=$(echo "$ssh_url" | sed 's|git@bitbucket.org:||' | sed 's|\.git$||')
        echo "https://bitbucket.org/$repo_path.git"
    elif [[ "$ssh_url" == git@github.com:* ]]; then
        # GitHub SSH vers HTTPS
        repo_path=$(echo "$ssh_url" | sed 's|git@github.com:||' | sed 's|\.git$||')
        echo "https://github.com/$repo_path.git"
    elif [[ "$ssh_url" == git@gitlab.com:* ]]; then
        # GitLab SSH vers HTTPS
        repo_path=$(echo "$ssh_url" | sed 's|git@gitlab.com:||' | sed 's|\.git$||')
        echo "https://gitlab.com/$repo_path.git"
    else
        # Si ce n'est pas SSH, retourner l'URL telle quelle
        echo "$ssh_url"
    fi
}

# Convertir toutes les URLs
if grep -q "^MASON_REPO_URL=" .env; then
    current_mason=$(grep "^MASON_REPO_URL=" .env | cut -d'=' -f2)
    new_mason=$(convert_ssh_to_https "$current_mason")
    sed -i "s|MASON_REPO_URL=.*|MASON_REPO_URL=$new_mason|" .env
    echo "🔧 Mason: $current_mason → $new_mason"
fi

if grep -q "^PAINTER_REPO_URL=" .env; then
    current_painter=$(grep "^PAINTER_REPO_URL=" .env | cut -d'=' -f2)
    new_painter=$(convert_ssh_to_https "$current_painter")
    sed -i "s|PAINTER_REPO_URL=.*|PAINTER_REPO_URL=$new_painter|" .env
    echo "🎨 Painter: $current_painter → $new_painter"
fi

if grep -q "^GESTIONCARTE_REPO_URL=" .env; then
    current_gestion=$(grep "^GESTIONCARTE_REPO_URL=" .env | cut -d'=' -f2)
    new_gestion=$(convert_ssh_to_https "$current_gestion")
    sed -i "s|GESTIONCARTE_REPO_URL=.*|GESTIONCARTE_REPO_URL=$new_gestion|" .env
    echo "💳 GestionCarte: $current_gestion → $new_gestion"
fi

# 3. Configuration de l'authentification pour dépôts privés
echo ""
echo "🔐 Configuration de l'authentification..."

# Vérifier si les URLs sont vers des dépôts privés Bitbucket
if grep -q "bitbucket.org" .env; then
    echo "🔍 Dépôts Bitbucket détectés"
    echo ""
    echo "💡 Pour accéder aux dépôts privés Bitbucket, vous avez besoin d'un App Password :"
    echo "   1. Allez sur https://bitbucket.org/account/settings/app-passwords/"
    echo "   2. Créez un nouveau App Password avec les permissions 'Repositories: Read'"
    echo "   3. Copiez le token généré"
    echo ""

    current_token=$(grep "^GIT_TOKEN=" .env | cut -d'=' -f2)
    if [ -z "$current_token" ]; then
        read -p "🔑 App Password Bitbucket (ATBB-xxx) [optionnel]: " bitbucket_token
        if [ ! -z "$bitbucket_token" ]; then
            sed -i "s|GIT_TOKEN=.*|GIT_TOKEN=$bitbucket_token|" .env
            echo "✅ Token configuré"
        fi
    else
        echo "✅ Token déjà configuré : ${current_token:0:10}..."
    fi
fi

# 4. Test d'accès aux repositories
echo ""
echo "🧪 Test d'accès aux repositories..."

source .env

test_repo_access() {
    local repo_url="$1"
    local repo_name="$2"
    local token="$3"

    if [ -z "$repo_url" ]; then
        echo "⚠️ $repo_name : URL non configurée"
        return
    fi

    # Construire l'URL de test avec token si nécessaire
    test_url="$repo_url"
    if [ ! -z "$token" ] && [[ "$repo_url" == https://* ]] && [[ "$repo_url" != *"@"* ]]; then
        # Injecter le token dans l'URL
        test_url=$(echo "$repo_url" | sed "s|https://|https://${token}@|")
    fi

    echo -n "📋 Test $repo_name... "
    if git ls-remote --heads "$test_url" >/dev/null 2>&1; then
        echo "✅ Accès OK"
    else
        echo "❌ Accès échoué"
        echo "   🔍 Vérifiez l'URL : $repo_url"
        if [ ! -z "$token" ]; then
            echo "   🔑 Token utilisé : ${token:0:10}..."
        else
            echo "   💡 Aucun token configuré (OK si dépôt public)"
        fi
    fi
}

test_repo_access "$MASON_REPO_URL" "Mason" "$GIT_TOKEN"
test_repo_access "$PAINTER_REPO_URL" "Painter" "$GIT_TOKEN"
test_repo_access "$GESTIONCARTE_REPO_URL" "GestionCarte" "$GIT_TOKEN"

# 5. Résumé et prochaines étapes
echo ""
echo "✅ Correction des URLs terminée !"
echo ""
echo "📋 Configuration finale :"
grep -E "^(MASON_REPO_URL|PAINTER_REPO_URL|GESTIONCARTE_REPO_URL)" .env

echo ""
echo "🚀 Prochaines étapes :"
echo "   1. Vérifiez que tous les tests d'accès sont ✅"
echo "   2. Si des tests échouent, configurez un token d'accès"
echo "   3. Relancez le build : docker-compose build painter"
echo ""
echo "💡 En cas de problème :"
echo "   - Dépôts publics : aucun token nécessaire"
echo "   - Dépôts privés GitHub : token commençant par 'ghp_'"
echo "   - Dépôts privés Bitbucket : App Password commençant par 'ATBB-'"