#!/bin/bash
echo "🧹 Nettoyage du projet - Conservation de la solution finale uniquement"

# Créer un dossier de sauvegarde pour les fichiers supprimés
mkdir -p .backup-$(date +%Y%m%d)

echo "📁 Sauvegarde des fichiers obsolètes..."
# Sauvegarder avant suppression
mv docker-compose.yml .backup-$(date +%Y%m%d)/ 2>/dev/null || true
mv docker-compose.local.yml .backup-$(date +%Y%m%d)/ 2>/dev/null || true
mv docker-compose.test.yml .backup-$(date +%Y%m%d)/ 2>/dev/null || true
mv docker-compose.network.yml .backup-$(date +%Y%m%d)/ 2>/dev/null || true
mv docker-compose.external.yml .backup-$(date +%Y%m%d)/ 2>/dev/null || true
mv docker-compose.standalone.yml .backup-$(date +%Y%m%d)/ 2>/dev/null || true
mv docker-compose.network-custom.yml .backup-$(date +%Y%m%d)/ 2>/dev/null || true
mv docker-compose.standalone-custom.yml .backup-$(date +%Y%m%d)/ 2>/dev/null || true

echo "🗑️ Suppression des scripts obsolètes..."
# Scripts de build obsolètes
rm -f build.sh
rm -f build-simple.sh
rm -f build-ultra-simple.sh
rm -f build-dev.sh
rm -f build-for-local.sh
rm -f build-standalone.sh
rm -f build-standalone-with-data.sh
rm -f build-external.sh
rm -f build-network.sh
rm -f build-test-image.sh

echo "🗑️ Suppression des dossiers de test..."
# Dossiers de test
rm -rf docker/mariadb-test/ 2>/dev/null || true

echo "📝 Renommage du fichier principal..."
# Renommer le docker-compose principal
mv docker-compose.standalone-quick.yml docker-compose.yml

echo "📋 Création de la documentation finale..."
# Créer un README final
cat > README.md << 'EOF'
# CardManager - Environnement Docker Multi-Services

## 🏗️ Architecture

- **MariaDB** : Base de données conteneurisée (amovible)
- **Mason** : Bibliothèque commune
- **Painter** : Service de gestion d'images (port 8081)
- **GestionCarte** : Application principale (port 8080)

## 🚀 Démarrage rapide

### Pour le développement avec vos données :

```bash
# 1. Exporter vos données locales
./export-data.sh

# 2. Construire et démarrer l'environnement
./build-quick-standalone.sh
```

### Accès aux services :
- **Application** : http://localhost:8080
- **Painter** : http://localhost:8081
- **Base de données** : localhost:3307

## 🔧 Gestion

```bash
# Démarrer l'environnement
docker-compose up -d

# Arrêter l'environnement
docker-compose down

# Voir les logs
docker-compose logs -f [service_name]

# Voir le statut
docker-compose ps
```

## 🚀 Déploiement en production

L'utilisateur final n'a qu'à :

1. **Fournir son conteneur MariaDB**
2. **Modifier les variables d'environnement** dans `docker-compose.yml` :
   ```yaml
   environment:
     - SPRING_DATASOURCE_URL=jdbc:mariadb://production-db:3306/production
     - SPRING_DATASOURCE_USERNAME=prod_user
     - SPRING_DATASOURCE_PASSWORD=prod_password
   ```
3. **Connecter au même réseau Docker**

## 📁 Structure du projet

```
├── docker-compose.yml              # Configuration principale
├── export-data.sh                  # Export des données locales
├── build-quick-standalone.sh       # Script de build principal
├── docker/
│   ├── mason/Dockerfile            # Image Mason
│   ├── painter/Dockerfile          # Image Painter
│   └── gestioncarte/Dockerfile     # Image GestionCarte
├── init-db/                        # Données d'initialisation
└── config/                         # Configuration Spring Boot
```

## 🔄 Volumes persistants

- `cardmanager_db_data` : Données de la base
- `cardmanager_images` : Images du service Painter

Les données sont conservées entre les redémarrages.
EOF

echo "✅ Nettoyage terminé !"
echo ""
echo "📋 Structure finale du projet :"
echo "├── docker-compose.yml (fichier principal)"
echo "├── export-data.sh"
echo "├── build-quick-standalone.sh"
echo "├── README.md"
echo "├── docker/"
echo "│   ├── mason/Dockerfile"
echo "│   ├── painter/Dockerfile"
echo "│   └── gestioncarte/Dockerfile"
echo "├── init-db/ (vos données)"
echo "└── config/"
echo ""
echo "🗑️ Fichiers sauvegardés dans : .backup-$(date +%Y%m%d)/"
echo ""
echo "🚀 Pour démarrer votre environnement :"
echo "   docker-compose up -d"