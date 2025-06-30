#!/bin/bash

echo "🔍 Diagnostic du Build Painter"
echo "=============================="

# 1. Vérifier la configuration Git
echo "🔧 Configuration Git actuelle:"
echo "MASON_REPO_URL: ${MASON_REPO_URL:-'Non défini'}"
echo "PAINTER_REPO_URL: ${PAINTER_REPO_URL:-'Non défini'}"
echo "GIT_TOKEN: ${GIT_TOKEN:+***défini***}"

# 2. Test de connectivité aux repos
echo ""
echo "🌐 Test de connectivité aux repositories:"

if [ -n "${MASON_REPO_URL}" ]; then
    echo "📋 Test Mason repository..."
    if git ls-remote --heads "${MASON_REPO_URL}" &>/dev/null; then
        echo "✅ Mason repository accessible"
    else
        echo "❌ Mason repository inaccessible"
        if [ -n "${GIT_TOKEN}" ]; then
            MASON_URL_WITH_TOKEN=$(echo ${MASON_REPO_URL} | sed "s|https://|https://${GIT_TOKEN}@|")
            if git ls-remote --heads "${MASON_URL_WITH_TOKEN}" &>/dev/null; then
                echo "✅ Mason repository accessible avec token"
            else
                echo "❌ Mason repository inaccessible même avec token"
            fi
        fi
    fi
fi

if [ -n "${PAINTER_REPO_URL}" ]; then
    echo "📋 Test Painter repository..."
    if git ls-remote --heads "${PAINTER_REPO_URL}" &>/dev/null; then
        echo "✅ Painter repository accessible"
    else
        echo "❌ Painter repository inaccessible"
        if [ -n "${GIT_TOKEN}" ]; then
            PAINTER_URL_WITH_TOKEN=$(echo ${PAINTER_REPO_URL} | sed "s|https://|https://${GIT_TOKEN}@|")
            if git ls-remote --heads "${PAINTER_URL_WITH_TOKEN}" &>/dev/null; then
                echo "✅ Painter repository accessible avec token"
            else
                echo "❌ Painter repository inaccessible même avec token"
            fi
        fi
    fi
fi

# 3. Vérifier les logs de build précédents
echo ""
echo "📋 Analyse des logs de build précédents:"
if docker-compose logs painter 2>/dev/null | grep -q "Building Painter"; then
    echo "✅ Logs Painter trouvés"
    echo "Dernières lignes du build Painter:"
    docker-compose logs painter | grep -A 10 -B 5 "Building Painter" | tail -15
else
    echo "⚠️ Pas de logs Painter disponibles"
fi

# 4. Test de build simple
echo ""
echo "🧪 Test de build simple de Painter:"
echo "Tentative de clonage local pour diagnostic..."

# Créer un répertoire temporaire
temp_dir=$(mktemp -d)
cd "$temp_dir"

echo "📁 Répertoire temporaire: $temp_dir"

# Test du clonage
if [ -n "${PAINTER_REPO_URL}" ]; then
    echo "🔄 Test de clonage Painter..."
    if [ -n "${GIT_TOKEN}" ]; then
        PAINTER_URL_WITH_TOKEN=$(echo ${PAINTER_REPO_URL} | sed "s|https://|https://${GIT_TOKEN}@|")
        if git clone --depth 1 "${PAINTER_URL_WITH_TOKEN}" painter-test; then
            echo "✅ Clonage Painter réussi avec token"

            echo "📋 Structure du repository Painter:"
            find painter-test -name "pom.xml" | head -5

            echo "📋 Fichiers dans painter-test:"
            ls -la painter-test/ | head -10

            # Chercher les dossiers avec des POMs
            echo "📋 Dossiers avec pom.xml:"
            find painter-test -name "pom.xml" -exec dirname {} \; | sort

        else
            echo "❌ Clonage Painter échoué même avec token"
        fi
    else
        if git clone --depth 1 "${PAINTER_REPO_URL}" painter-test; then
            echo "✅ Clonage Painter réussi sans token"

            echo "📋 Structure du repository:"
            ls -la painter-test/

        else
            echo "❌ Clonage Painter échoué"
        fi
    fi
fi

# Nettoyage
cd - &>/dev/null
rm -rf "$temp_dir"

# 5. Recommandations
echo ""
echo "💡 RECOMMANDATIONS :"
echo "==================="

if ! command -v git &> /dev/null; then
    echo "❌ Git n'est pas installé"
fi

if [ -z "${MASON_REPO_URL}" ] || [ -z "${PAINTER_REPO_URL}" ]; then
    echo "⚠️ Variables d'environnement manquantes"
    echo "   Créez/vérifiez votre fichier .env avec:"
    echo "   MASON_REPO_URL=https://github.com/ialame/mason"
    echo "   PAINTER_REPO_URL=https://github.com/ialame/painter"
    echo "   MASON_BRANCH=main"
    echo "   PAINTER_BRANCH=main"
fi

if [ -z "${GIT_TOKEN}" ]; then
    echo "💡 Si les repos sont privés, ajoutez GIT_TOKEN dans .env"
fi

echo ""
echo "🎯 Actions suivantes recommandées:"
echo "1. Corriger le Dockerfile: ./fix_painter_dockerfile.sh"
echo "2. Relancer le build: docker-compose up --build painter"
echo "3. Surveiller les logs: docker-compose logs -f painter"

echo ""
echo "🔍 Pour debug interactif du build:"
echo "   docker-compose build painter --progress=plain --no-cache"