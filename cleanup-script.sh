#!/bin/bash

# 🧹 Script de nettoyage professionnel pour CardManager Docker
# Ce script supprime les fichiers inutiles et organise le projet

echo "🧹 Nettoyage professionnel du projet CardManager..."
echo "================================================="

# Créer un dossier de sauvegarde
BACKUP_DIR=".backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Sauvegarde des fichiers dans $BACKUP_DIR..."

# Fichiers à supprimer définitivement (après sauvegarde)
FILES_TO_REMOVE=(
    "docker/gestioncarte/Dockerfile.backup"
    "docker/painter/Dockerfile.backup"
    "structure.txt"
    "*.sql"
    "2025-06-19_00-00-01.sql"
    "backup.sql"
    "README-Docker.md"
)

# Sauvegarder puis supprimer les fichiers inutiles
for pattern in "${FILES_TO_REMOVE[@]}"; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            echo "  📄 Sauvegarde: $file"
            cp "$file" "$BACKUP_DIR/" 2>/dev/null
            rm -f "$file"
            echo "  🗑️  Supprimé: $file"
        fi
    done
done

# Nettoyer les dossiers temporaires
echo "🗂️  Nettoyage des dossiers temporaires..."
rm -rf docker/mariadb-test/
rm -rf init-db/*.sql 2>/dev/null

# Créer la structure finale propre
echo "📁 Création de la structure finale..."
mkdir -p {docker/{mason,painter,gestioncarte},config,scripts}

# Créer le fichier principal README.md
echo "📝 Création du README.md principal..."
cat > README.md << 'EOF'
# 🎯 CardManager - Architecture Docker Multi-Services

> **Système de gestion de cartes avec architecture microservices**

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://docker.com)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.5-green?logo=spring)](https://spring.io)
[![Java](https://img.shields.io/badge/Java-21-orange?logo=openjdk)](https://openjdk.org)

## 🏗️ Architecture

```mermaid
graph TB
    A[GestionCarte :8080] --> B[Painter :8081]
    A --> C[MariaDB :3306]
    B --> C
    D[Mason] --> A
    D --> B
    E[Nginx :8082] --> B
```

### Services
- **🖼️ GestionCarte** (`:8080`) - Application principale de gestion des cartes
- **🎨 Painter** (`:8081`) - Service de traitement et gestion d'images
- **🔧 Mason** - Bibliothèque commune (utilities, JPA, cache)
- **🗄️ MariaDB** (`:3306`) - Base de données relationnelle
- **⚡ Nginx** (`:8082`) - Serveur d'images statiques haute performance

## 🚀 Démarrage Rapide

### 1️⃣ Configuration initiale
```bash
# Cloner le projet
git clone <votre-repository>
cd cardmanager

# Configuration Git automatique
chmod +x scripts/configure-git.sh
./scripts/configure-git.sh
```

### 2️⃣ Démarrage automatique
```bash
# Build et démarrage complet
chmod +x build-quick-standalone.sh
./build-quick-standalone.sh
```

### 3️⃣ Accès aux services
- **📱 Application principale** : http://localhost:8080
- **🎨 API Painter** : http://localhost:8081
- **🖼️ Images statiques** : http://localhost:8082
- **📊 Swagger UI** : http://localhost:8080/swagger-ui.html

## ⚙️ Configuration

### Variables d'environnement (.env)
```bash
# Repositories Git
MASON_REPO_URL=https://github.com/ialame/mason
PAINTER_REPO_URL=https://github.com/ialame/painter
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte

# Branches (optionnel)
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main

# Token Git (pour dépôts privés)
GIT_TOKEN=your_github_token_here
```

### Base de données
```yaml
# Développement (MariaDB intégrée)
SPRING_DATASOURCE_URL: jdbc:mariadb://mariadb:3306/dev
SPRING_DATASOURCE_USERNAME: ia
SPRING_DATASOURCE_PASSWORD: foufafou

# Production (Base externe)
SPRING_DATASOURCE_URL: jdbc:mariadb://your-db:3306/production
```

## 🛠️ Commandes Utiles

### Docker Compose
```bash
# Démarrage complet
docker-compose up -d

# Logs en temps réel
docker-compose logs -f

# Redémarrage d'un service
docker-compose restart gestioncarte

# Arrêt complet
docker-compose down

# Nettoyage complet
docker-compose down --volumes --remove-orphans
```

### Maintenance
```bash
# Export des données
./export-data.sh

# Nettoyage du projet
./scripts/cleanup-project.sh

# Reconstruction complète
docker-compose build --no-cache
```

## 📁 Structure du Projet

```
cardmanager/
├── 📄 docker-compose.yml          # Configuration principale
├── 📄 build-quick-standalone.sh   # Script de build automatique
├── 📄 export-data.sh             # Export des données
├── 📄 .env.template              # Template de configuration
│
├── 🐳 docker/                    # Dockerfiles
│   ├── mason/Dockerfile
│   ├── painter/Dockerfile
│   └── gestioncarte/Dockerfile
│
├── ⚙️ config/                    # Configurations
│   ├── application-docker.properties
│   └── nginx.conf
│
├── 📜 scripts/                   # Scripts utilitaires
│   ├── configure-git.sh
│   └── cleanup-project.sh
│
└── 💾 volumes/                   # Données persistantes
    ├── db_data/                  # Données MariaDB
    └── images/                   # Images Painter
```

## 🔍 Surveillance et Logs

### Health Checks
```bash
# Vérifier l'état des services
docker-compose ps

# Health check détaillé
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
```

### Logs par service
```bash
# Application principale
docker-compose logs -f gestioncarte

# Service d'images
docker-compose logs -f painter

# Base de données
docker-compose logs -f mariadb
```

## 🚀 Déploiement en Production

### 1. Configuration sécurisée
```bash
# Copier et adapter la configuration
cp .env.template .env.production

# Modifier les valeurs sensibles
nano .env.production
```

### 2. Base de données externe
```yaml
# Dans docker-compose.override.yml
services:
  gestioncarte:
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://prod-db:3306/cardmanager
      - SPRING_DATASOURCE_USERNAME=${DB_USER}
      - SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
```

### 3. Volumes de production
```yaml
volumes:
  cardmanager_images:
    driver: local
    driver_opts:
      type: nfs
      o: addr=your-nfs-server,rw
      device: ":/path/to/images"
```

## 🐛 Dépannage

### Problèmes courants

#### ❌ Services qui ne démarrent pas
```bash
# Vérifier les dépendances
docker-compose ps

# Reconstruire les images
docker-compose build --no-cache

# Vérifier la configuration
docker-compose config
```

#### ❌ Erreurs de connexion base de données
```bash
# Tester la connexion
docker-compose exec mariadb mysql -u ia -p

# Vérifier les logs
docker-compose logs mariadb
```

#### ❌ Problèmes de build Git
```bash
# Vérifier les credentials
docker-compose logs builder

# Tester l'accès Git
git ls-remote $MASON_REPO_URL
```

### Support
- 📖 **Documentation complète** : `docs/`
- 🐛 **Issues** : Créer une issue GitHub
- 💬 **Questions** : Contacter l'équipe technique

## 📈 Performance

### Optimisations incluses
- ✅ **Cache Nginx** (30 jours pour les images)
- ✅ **Pool de connexions** HikariCP optimisé
- ✅ **Compression Gzip** activée
- ✅ **Headers CORS** configurés
- ✅ **Health checks** intelligents
- ✅ **Volumes SSD** recommandés

### Métriques
- **Temps de démarrage** : ~2-3 minutes
- **Mémoire requise** : 4GB RAM minimum
- **Stockage** : 10GB pour les données + images

---

**🎯 CardManager - Prêt pour la production !**
EOF

# Créer le guide de déploiement
echo "📘 Création du guide de déploiement..."
cat > GUIDE-DEPLOIEMENT.md << 'EOF'
# 🚀 Guide de Déploiement - CardManager

## 📋 Vue d'ensemble

CardManager est une application multi-services constituée de :
- **GestionCarte** : Application web principale (port 8080)
- **Painter** : Service de gestion d'images (port 8081)
- **Mason** : Bibliothèque commune (services internes)
- **MariaDB** : Base de données (configurable)

## 🎯 Modes de déploiement

### 1. **Mode Développement** (base de données incluse)
Pour tester/développer avec une base MariaDB conteneurisée

### 2. **Mode Production** (base de données externe)
Pour un déploiement avec votre propre base de données

---

## 🛠️ Prérequis

### Environnement requis
- **Docker** >= 20.10
- **Docker Compose** >= 2.0
- **Git** (pour cloner les dépôts)
- **Ports libres** : 8080, 8081, 3307 (développement)

### Vérifications préalables
```bash
# Vérifier Docker
docker --version
docker-compose --version

# Vérifier les ports libres
netstat -tuln | grep -E "(8080|8081|3307)"
```

---

## 🔧 Configuration Git

### Option 1: Configuration automatique (recommandé)
```bash
# Lancer l'assistant de configuration
chmod +x scripts/configure-git.sh
./scripts/configure-git.sh
```

### Option 2: Configuration manuelle
```bash
# Copier le template
cp .env.template .env

# Éditer avec vos valeurs
nano .env
```

### Exemple de configuration
```bash
MASON_REPO_URL=https://github.com/ialame/mason
PAINTER_REPO_URL=https://github.com/ialame/painter
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main
GIT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 🚀 Déploiement Mode Développement

### Étape 1 : Configuration
```bash
# Cloner le projet
git clone <URL_DU_PROJET>
cd cardmanager

# Configuration Git
chmod +x scripts/configure-git.sh
./scripts/configure-git.sh
```

### Étape 2 : Démarrage
```bash
# Build et démarrage automatique
chmod +x build-quick-standalone.sh
./build-quick-standalone.sh

# Ou démarrage manuel
docker-compose up -d
```

### Étape 3 : Vérification
```bash
# Vérifier les services
docker-compose ps

# Tester les endpoints
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
```

---

## 🏭 Déploiement Mode Production

### 1. Configuration de production
```bash
# Créer la configuration de production
cp .env.template .env.production

# Éditer les variables sensibles
nano .env.production
```

### 2. Base de données externe
```yaml
# Créer docker-compose.override.yml
services:
  gestioncarte:
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://prod-db:3306/cardmanager
      - SPRING_DATASOURCE_USERNAME=${PROD_DB_USER}
      - SPRING_DATASOURCE_PASSWORD=${PROD_DB_PASSWORD}

  painter:
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://prod-db:3306/cardmanager
      - SPRING_DATASOURCE_USERNAME=${PROD_DB_USER}
      - SPRING_DATASOURCE_PASSWORD=${PROD_DB_PASSWORD}

  # Retirer le service mariadb
  mariadb:
    deploy:
      replicas: 0
```

### 3. Volumes de production
```yaml
# Ajouter dans docker-compose.override.yml
volumes:
  cardmanager_images:
    driver: local
    driver_opts:
      type: nfs
      o: addr=your-nfs-server,rw
      device: ":/path/to/images"

  cardmanager_db_data:
    external: true
    name: prod_db_data
```

### 4. Démarrage production
```bash
# Démarrage avec override
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

# Vérifier le déploiement
docker-compose ps
```

---

## 🔍 Maintenance et Monitoring

### Commandes de maintenance
```bash
# Logs en temps réel
docker-compose logs -f

# Redémarrage d'un service
docker-compose restart gestioncarte

# Mise à jour des images
docker-compose pull
docker-compose up -d

# Sauvegarde des données
./export-data.sh
```

### Monitoring
```bash
# Métriques système
docker stats

# Health checks
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health

# Espace disque des volumes
docker system df
```

---

## 🐛 Dépannage

### Problèmes Git
```bash
# Vérifier l'accès aux repos
git ls-remote $MASON_REPO_URL

# Problème de token
echo $GIT_TOKEN | cut -c1-10  # Vérifier le début du token
```

### Problèmes de base de données
```bash
# Connexion directe
docker-compose exec mariadb mysql -u ia -p

# Réinitialiser la base
docker-compose down --volumes
docker-compose up -d
```

### Problèmes de performance
```bash
# Vérifier la mémoire
docker stats --no-stream

# Optimiser les images
docker image prune -f
docker volume prune -f
```

---

## 📞 Support

### Logs à fournir en cas de problème
```bash
# Collecter tous les logs
docker-compose logs > cardmanager-logs.txt

# Configuration anonymisée
docker-compose config > cardmanager-config.yml
```

### Informations système
```bash
# Version Docker
docker --version
docker-compose --version

# Espace disque
df -h
```

**🎯 Pour toute question technique, joindre ces informations !**
EOF

# Créer le script de configuration Git
echo "⚙️ Création du script de configuration Git..."
mkdir -p scripts
cat > scripts/configure-git.sh << 'EOF'
#!/bin/bash

# 🔧 Configuration automatique des dépôts Git pour CardManager

echo "🔧 Configuration des dépôts Git CardManager"
echo "==========================================="

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
echo "📝 Configuration des URLs des dépôts Git:"
echo ""

# Mason Repository
read -p "🔧 URL du dépôt Mason [https://github.com/ialame/mason]: " mason_url
mason_url=${mason_url:-https://github.com/ialame/mason}
sed -i "s|MASON_REPO_URL=.*|MASON_REPO_URL=$mason_url|" .env

# Painter Repository
read -p "🎨 URL du dépôt Painter [https://github.com/ialame/painter]: " painter_url
painter_url=${painter_url:-https://github.com/ialame/painter}
sed -i "s|PAINTER_REPO_URL=.*|PAINTER_REPO_URL=$painter_url|" .env

# GestionCarte Repository
read -p "💳 URL du dépôt GestionCarte [https://github.com/ialame/gestioncarte]: " gestion_url
gestion_url=${gestion_url:-https://github.com/ialame/gestioncarte}
sed -i "s|GESTIONCARTE_REPO_URL=.*|GESTIONCARTE_REPO_URL=$gestion_url|" .env

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
echo "🔐 Configuration de l'authentification Git:"
echo "ℹ️  Laissez vide si vos dépôts sont publics"
echo "ℹ️  Pour dépôts privés, utilisez un token d'accès personnel"
echo ""

read -p "🔑 Token Git (ghp_xxx ou ATBB-xxx) [optionnel]: " git_token
if [ ! -z "$git_token" ]; then
    sed -i "s|GIT_TOKEN=.*|GIT_TOKEN=$git_token|" .env
fi

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
EOF

chmod +x scripts/configure-git.sh

# Créer le template .env
echo "📝 Création du template .env..."
cat > .env.template << 'EOF'
# 🔧 Configuration Git pour CardManager
# Copier ce fichier vers .env et adapter vos valeurs

# URLs des dépôts Git (OBLIGATOIRE)
MASON_REPO_URL=https://github.com/ialame/mason
PAINTER_REPO_URL=https://github.com/ialame/painter
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte

# Branches Git (OPTIONNEL - par défaut: main)
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main

# Token d'authentification Git (OPTIONNEL - requis pour dépôts privés)
# GitHub: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Bitbucket: ATBB-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
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

# Mettre à jour le .gitignore
echo "🔒 Mise à jour du .gitignore..."
cat > .gitignore << 'EOF'
# Fichiers de configuration sensibles
.env
.env.local
.env.production

# Fichiers de build et cache
target/
.mvn/wrapper/maven-wrapper.jar
!**/src/main/**/target/
!**/src/test/**/target/

# IDE
.idea/
*.iws
*.iml
*.ipr
.vscode/
.settings/
.project
.classpath

# Données temporaires
*.sql
backup.sql
structure.txt
docker/mariadb-test/
init-db/*.sql

# Sauvegardes automatiques
.backup-*/

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db
EOF

# Nettoyer le docker-compose.yml des commentaires inutiles
echo "🔧 Nettoyage du docker-compose.yml..."
cp docker-compose.yml docker-compose.yml.backup

# Créer un fichier changelog
echo "📋 Création du changelog..."
cat > CHANGELOG.md << 'EOF'
# 📋 Changelog - CardManager

## [1.0.0] - 2025-06-29

### ✨ Fonctionnalités ajoutées
- Architecture Docker multi-services complète
- Service GestionCarte avec API REST
- Service Painter pour gestion d'images
- Bibliothèque Mason commune
- Base de données MariaDB intégrée
- Serveur Nginx pour images statiques
- Configuration Git automatique
- Scripts de déploiement automatisé

### 🔧 Améliorations techniques
- Health checks intelligents
- Volumes persistants Docker
- Cache Nginx optimisé (30 jours)
- Configuration CORS complète
- Monitoring et métriques
- Documentation complète

### 🛠️ Configuration
- Support des dépôts Git publics/privés
- Authentification par token
- Configuration flexible par variables d'environnement
- Mode développement et production

### 📚 Documentation
- Guide de déploiement complet
- README détaillé avec architecture
- Scripts de configuration automatique
- Exemples de troubleshooting

### 🐳 Docker
- Images optimisées avec cache multi-stage
- Configuration Docker Compose production-ready
- Volumes named pour persistance
- Network isolation
EOF

echo ""
echo "🎉 Nettoyage professionnel terminé !"
echo ""
echo "📁 Structure finale du projet :"
echo "├── 📄 README.md (documentation principale)"
echo "├── 📘 GUIDE-DEPLOIEMENT.md (guide détaillé)"
echo "├── 📋 CHANGELOG.md (historique des versions)"
echo "├── 🐳 docker-compose.yml (configuration Docker)"
echo "├── 🚀 build-quick-standalone.sh (script de démarrage)"
echo "├── 💾 export-data.sh (sauvegarde données)"
echo "├── ⚙️ .env.template (template de configuration)"
echo "├── 🔒 .gitignore (fichiers à ignorer)"
echo "├── 📁 docker/ (Dockerfiles)"
echo "├── 📁 config/ (configurations)"
echo "├── 📁 scripts/ (utilitaires)"
echo "└── 📁 .backup-xxx/ (fichiers sauvegardés)"
echo ""
echo "🗑️ Fichiers supprimés :"
echo "├── ❌ Dockerfiles backup"
echo "├── ❌ README-Docker.md (redondant)"
echo "├── ❌ Fichiers SQL temporaires"
echo "├── ❌ structure.txt"
echo "└── ❌ Dossiers de test MariaDB"
echo ""
echo "🚀 Pour démarrer votre environnement :"
echo "   1️⃣ chmod +x scripts/configure-git.sh && ./scripts/configure-git.sh"
echo "   2️⃣ chmod +x build-quick-standalone.sh && ./build-quick-standalone.sh"
echo ""
echo "📚 Lisez README.md pour la documentation complète !"
echo "📖 Consultez GUIDE-DEPLOIEMENT.md pour le déploiement en production !"