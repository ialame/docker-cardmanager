#!/bin/bash

# 🔧 Configuration Git améliorée pour CardManager
# Support de tous les formats d'URLs Git

echo "🔧 Configuration Git CardManager - Support Multi-Formats"
echo "======================================================="

# Fonction pour détecter le type d'URL Git
detect_git_provider() {
    local url="$1"

    if [[ "$url" == *"github.com"* ]]; then
        echo "github"
    elif [[ "$url" == *"bitbucket.org"* ]]; then
        echo "bitbucket"
    elif [[ "$url" == *"gitlab.com"* ]] || [[ "$url" == *"gitlab"* ]]; then
        echo "gitlab"
    else
        echo "other"
    fi
}

# Fonction pour valider une URL Git
validate_git_url() {
    local url="$1"
    local repo_name="$2"

    echo "🔍 Validation de l'URL $repo_name..."

    # Formats supportés
    if [[ "$url" =~ ^https://[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+/[a-zA-Z0-9._/-]+\.git$ ]] || \
       [[ "$url" =~ ^https://[a-zA-Z0-9.-]+/[a-zA-Z0-9._/-]+\.git$ ]] || \
       [[ "$url" =~ ^git@[a-zA-Z0-9.-]+:[a-zA-Z0-9._/-]+\.git$ ]] || \
       [[ "$url" =~ ^ssh://git@[a-zA-Z0-9.-]+/[a-zA-Z0-9._/-]+\.git$ ]]; then
        echo "✅ Format d'URL valide"
        return 0
    else
        echo "⚠️  Format d'URL non standard, mais sera testé..."
        return 0
    fi
}

# Fonction pour extraire le username d'une URL
extract_username_from_url() {
    local url="$1"

    if [[ "$url" =~ https://([^@]+)@[^/]+/ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# Fonction pour tester l'accès à un dépôt
test_git_access() {
    local url="$1"
    local token="$2"
    local repo_name="$3"

    echo "🔎 Test d'accès au dépôt $repo_name..."

    # Construire l'URL avec token si nécessaire
    local test_url="$url"
    if [ ! -z "$token" ] && [[ "$url" == https://* ]] && [[ "$url" != *"@"* ]]; then
        # Injecter le token dans l'URL si pas déjà d'auth
        test_url=$(echo "$url" | sed "s|https://|https://${token}@|")
    fi

    # Test de connexion Git
    if git ls-remote "$test_url" >/dev/null 2>&1; then
        echo "✅ Accès confirmé pour $repo_name"
        return 0
    else
        echo "❌ Impossible d'accéder à $repo_name"
        echo "ℹ️  Vérifiez l'URL et les permissions"
        return 1
    fi
}

# Fonction pour afficher les exemples d'URLs
show_url_examples() {
    echo ""
    echo "📝 Formats d'URLs supportés :"
    echo ""
    echo "🔹 GitHub :"
    echo "   • https://github.com/username/repo.git"
    echo "   • https://token@github.com/username/repo.git"
    echo "   • https://username@github.com/username/repo.git"
    echo "   • git@github.com:username/repo.git"
    echo ""
    echo "🔹 Bitbucket :"
    echo "   • https://bitbucket.org/workspace/repo.git"
    echo "   • https://username@bitbucket.org/workspace/repo.git"
    echo "   • https://token@bitbucket.org/workspace/repo.git"
    echo "   • git@bitbucket.org:workspace/repo.git"
    echo ""
    echo "🔹 GitLab :"
    echo "   • https://gitlab.com/group/repo.git"
    echo "   • https://username@gitlab.com/group/repo.git"
    echo "   • git@gitlab.com:group/repo.git"
    echo ""
}

# Fonction principale de configuration
configure_repository() {
    local repo_var="$1"
    local repo_name="$2"
    local default_url="$3"
    local icon="$4"

    echo ""
    echo "$icon Configuration du dépôt $repo_name"
    echo "────────────────────────────────────────"

    while true; do
        read -p "URL du dépôt $repo_name [$default_url]: " repo_url
        repo_url=${repo_url:-$default_url}

        # Valider l'URL
        if validate_git_url "$repo_url" "$repo_name"; then
            # Détecter le provider
            provider=$(detect_git_provider "$repo_url")
            echo "🔍 Provider détecté: $provider"

            # Extraire le username si présent
            username=$(extract_username_from_url "$repo_url")
            if [ ! -z "$username" ]; then
                echo "👤 Username détecté dans l'URL: $username"
            fi

            # Confirmer l'URL
            read -p "Confirmer cette URL ? (Y/n): " confirm
            if [[ $confirm =~ ^[Nn]$ ]]; then
                continue
            fi

            # Sauvegarder l'URL
            sed -i "s|${repo_var}=.*|${repo_var}=$repo_url|" .env
            echo "✅ URL sauvegardée pour $repo_name"
            break
        else
            echo "❌ URL invalide, veuillez réessayer"
            read -p "Voir les exemples d'URLs ? (y/N): " show_examples
            if [[ $show_examples =~ ^[Yy]$ ]]; then
                show_url_examples
            fi
        fi
    done
}

# Script principal
echo ""
echo "ℹ️  Ce script supporte tous les formats d'URLs Git:"
echo "   • URLs avec username intégré (https://user@domain/repo.git)"
echo "   • URLs avec token intégré (https://token@domain/repo.git)"
echo "   • URLs standards (https://domain/repo.git)"
echo "   • URLs SSH (git@domain:repo.git)"
echo ""

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
echo "📝 Configuration des dépôts Git:"

# Configuration Mason
configure_repository "MASON_REPO_URL" "Mason" "https://github.com/ialame/mason.git" "🔧"

# Configuration Painter
configure_repository "PAINTER_REPO_URL" "Painter" "https://github.com/ialame/painter.git" "🎨"

# Configuration GestionCarte
configure_repository "GESTIONCARTE_REPO_URL" "GestionCarte" "https://github.com/ialame/gestioncarte.git" "💳"

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
echo "🔐 Configuration de l'authentification:"
echo ""
echo "ℹ️  Options d'authentification:"
echo "   1️⃣ Username dans l'URL (https://user@domain/repo.git)"
echo "   2️⃣ Token dans l'URL (https://token@domain/repo.git)"
echo "   3️⃣ Token séparé (pour URLs sans auth intégrée)"
echo "   4️⃣ Aucune auth (dépôts publics)"
echo ""

# Détecter si des URLs contiennent déjà de l'auth
mason_url=$(grep "MASON_REPO_URL=" .env | cut -d'=' -f2)
painter_url=$(grep "PAINTER_REPO_URL=" .env | cut -d'=' -f2)
gestion_url=$(grep "GESTIONCARTE_REPO_URL=" .env | cut -d'=' -f2)

auth_in_urls=false
if [[ "$mason_url" == *"@"* ]] || [[ "$painter_url" == *"@"* ]] || [[ "$gestion_url" == *"@"* ]]; then
    auth_in_urls=true
    echo "✅ Authentification détectée dans les URLs"
fi

if [ "$auth_in_urls" = false ]; then
    echo "ℹ️  Aucune authentification détectée dans les URLs"
    read -p "🔑 Token Git supplémentaire (ghp_xxx, ATBB-xxx) [optionnel]: " git_token
    if [ ! -z "$git_token" ]; then
        sed -i "s|GIT_TOKEN=.*|GIT_TOKEN=$git_token|" .env
        echo "🔑 Token configuré"
    fi
fi

echo ""
echo "🧪 Test des accès aux dépôts:"
echo ""

# Récupérer le token configuré
git_token=$(grep "GIT_TOKEN=" .env | cut -d'=' -f2)

# Tester l'accès à chaque dépôt
test_git_access "$mason_url" "$git_token" "Mason"
test_git_access "$painter_url" "$git_token" "Painter"
test_git_access "$gestion_url" "$git_token" "GestionCarte"

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

# Fonction pour mettre à jour le template .env
update_env_template() {
    echo ""
    echo "📝 Mise à jour du template .env..."

    cat > .env.template << 'EOF'
# 🔧 Configuration Git pour CardManager
# Copier ce fichier vers .env et adapter vos valeurs

# URLs des dépôts Git (OBLIGATOIRE)
# Formats supportés:
#   • Standard: https://github.com/user/repo.git
#   • Avec username: https://username@github.com/user/repo.git
#   • Avec token: https://token@github.com/user/repo.git
#   • SSH: git@github.com:user/repo.git

MASON_REPO_URL=https://github.com/ialame/mason.git
PAINTER_REPO_URL=https://github.com/ialame/painter.git
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte.git

# Exemples pour Bitbucket:
# MASON_REPO_URL=https://username@bitbucket.org/workspace/mason.git
# PAINTER_REPO_URL=https://bitbucket.org/workspace/painter.git
# GESTIONCARTE_REPO_URL=https://token@bitbucket.org/workspace/gestioncarte.git

# Branches Git (OPTIONNEL - par défaut: main)
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main

# Token d'authentification Git (OPTIONNEL)
# Nécessaire uniquement si pas d'auth dans les URLs
# GitHub: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Bitbucket: ATBB-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# GitLab: glpat-xxxxxxxxxxxxxxxxxxxx
GIT_TOKEN=

# Configuration base de données (OPTIONNEL - par défaut: développement)
DB_NAME=dev
DB_USER=ia
DB_PASSWORD=foufafou
DB_ROOT_PASSWORD=root_password

# Ports (OPTIONNEL - par défaut: 8080, 8081, 8082, 3307)
GESTIONCARTE_PORT=8080
PAINTER_PORT=8081
NGINX_PORT=8082
MARIADB_PORT=3307
EOF
}

# Mettre à jour le template
update_env_template

echo ""
echo "📚 Exemples d'URLs supportées:"
show_url_examples