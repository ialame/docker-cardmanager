#!/bin/bash

# 🧪 Testeur d'authentification Git

echo "🧪 Test d'authentification Git"
echo "=============================="

if [ ! -f ".env" ]; then
    echo "❌ Fichier .env non trouvé"
    echo "💡 Lancez d'abord: ./configure-auth.sh"
    exit 1
fi

source .env

echo "📋 Configuration détectée :"
echo "   Mason: $MASON_REPO_URL"
echo ""

if [[ "$MASON_REPO_URL" == git@* ]]; then
    echo "🔍 Test SSH..."
    
    if ssh -T git@bitbucket.org -o ConnectTimeout=5 2>&1 | grep -q "logged in as"; then
        echo "✅ SSH fonctionne"
        
        if git ls-remote --heads "$MASON_REPO_URL" >/dev/null 2>&1; then
            echo "✅ Accès au repository OK"
        else
            echo "❌ Accès au repository échoué"
        fi
    else
        echo "❌ SSH ne fonctionne pas"
    fi
    
elif [[ "$MASON_REPO_URL" == https://* ]]; then
    echo "🔍 Test HTTPS..."
    
    if git ls-remote --heads "$MASON_REPO_URL" >/dev/null 2>&1; then
        echo "✅ HTTPS avec token fonctionne"
    else
        echo "❌ HTTPS avec token échoué"
    fi
    
else
    echo "❌ Format d'URL non reconnu"
fi
