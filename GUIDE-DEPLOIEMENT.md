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
