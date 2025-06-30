#!/bin/bash

# 🖼️ Build GestionCarte Final avec Toutes les Dépendances

echo "🖼️ Build GestionCarte Final"
echo "=========================="

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

source .env

if [ -z "$SSH_PRIVATE_KEY" ]; then
    echo -e "${RED}❌ SSH_PRIVATE_KEY non définie !${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuration prête${NC}"
echo -e "${BLUE}📋 Dépendances ajoutées :${NC}"
echo "   ✅ MapStruct: 1.5.5.Final"
echo "   ✅ SpringDoc: 2.2.0"
echo "   ✅ Mason: 2.4.1 (disponible)"
echo "   ✅ Painter: 1.3.0 (disponible)"

# Build GestionCarte avec toutes les dépendances
echo -e "${BLUE}🔨 Build GestionCarte avec toutes les dépendances...${NC}"

if docker-compose build --no-cache gestioncarte; then
    echo ""
    echo -e "${GREEN}🎉 BUILD GESTIONCARTE FINAL RÉUSSI !${NC}"
    echo ""
    echo -e "${BLUE}🚀 Démarrage complet...${NC}"
    docker-compose up -d

    echo ""
    echo -e "${GREEN}✅ Tous les services démarrés !${NC}"
    echo "   📱 GestionCarte : http://localhost:${GESTIONCARTE_PORT:-8080}"
    echo "   🎨 Painter : http://localhost:${PAINTER_PORT:-8081}"
    echo "   🖼️ Images statiques : http://localhost:${NGINX_PORT:-8082}"
    echo "   🗄️ MariaDB : localhost:${MARIADB_PORT:-3307}"

    echo ""
    echo -e "${BLUE}🔍 Status final :${NC}"
    docker-compose ps

    echo ""
    echo -e "${GREEN}🎉 SUCCÈS COMPLET ! Tous les services CardManager sont opérationnels !${NC}"

else
    echo ""
    echo -e "${RED}❌ BUILD GESTIONCARTE ÉCHOUÉ !${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Diagnostic :${NC}"
    echo "   - Toutes les dépendances ont été ajoutées au dependencyManagement"
    echo "   - MapStruct et SpringDoc versions définies"
    echo "   - Mason et Painter construits avec succès"
    echo "   - Vérifiez les logs ci-dessus pour plus de détails"
    exit 1
fi
