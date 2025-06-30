#!/bin/bash

# 🖼️ Build GestionCarte seulement (Painter déjà fonctionnel)

echo "🖼️ Build GestionCarte seulement"
echo "==============================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Vérifications
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Fichier .env manquant !${NC}"
    exit 1
fi

# Source de la configuration
source .env

# Vérifier SSH_PRIVATE_KEY
if [ -z "$SSH_PRIVATE_KEY" ]; then
    echo -e "${RED}❌ SSH_PRIVATE_KEY non définie !${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuration prête${NC}"
echo -e "${BLUE}📋 SSH: ${#SSH_PRIVATE_KEY} caractères${NC}"

# Build uniquement GestionCarte
echo -e "${BLUE}🔨 Build GestionCarte avec dependencyManagement...${NC}"

if docker-compose build --no-cache gestioncarte; then
    echo ""
    echo -e "${GREEN}🎉 BUILD GESTIONCARTE RÉUSSI !${NC}"
    echo ""
    echo -e "${BLUE}🚀 Démarrage complet...${NC}"
    docker-compose up -d

    echo ""
    echo -e "${GREEN}✅ Services démarrés !${NC}"
    echo "   📱 GestionCarte : http://localhost:${GESTIONCARTE_PORT:-8080}"
    echo "   🎨 Painter : http://localhost:${PAINTER_PORT:-8081}"
    echo "   🖼️ Images statiques : http://localhost:${NGINX_PORT:-8082}"

    echo ""
    echo -e "${BLUE}🔍 Status :${NC}"
    docker-compose ps

else
    echo ""
    echo -e "${RED}❌ BUILD GESTIONCARTE ÉCHOUÉ !${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Le Dockerfile GestionCarte a maintenant le même dependencyManagement que Painter${NC}"
    exit 1
fi
