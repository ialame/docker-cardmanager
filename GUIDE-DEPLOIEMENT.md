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

### Configuration Git
Le projet clone automatiquement 3 dépôts Git :
- **Mason** : Bibliothèque commune
- **Painter** : Service d'images
- **GestionCarte** : Application principale

**Types de dépôts supportés :**
- ✅ **GitHub** public/privé (avec token ghp_xxx)
- ✅ **Bitbucket** public/privé (avec token ATBB-xxx)

### Authentification
- **Dépôts publics** : Aucune authentification requise
- **Dépôts privés** : Token d'accès personnel requis
    - GitHub : Token commençant par `ghp_`
    - Bitbucket : Token commençant par `ATBB-`

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
chmod +x configure-git.sh
./configure-git.sh
```

### Option 2: Configuration manuelle
```bash
# Copier le template
cp .env.template .env

# Éditer avec vos valeurs
nano .env
```

### Exemples de configuration

#### GitHub privé avec token :
```bash
MASON_REPO_URL=https://github.com/monentreprise/mason.git
PAINTER_REPO_URL=https://github.com/monentreprise/painter.git
GESTIONCARTE_REPO_URL=https://github.com/monentreprise/gestioncarte.git
MASON_BRANCH=develop
PAINTER_BRANCH=feature/new-ui
GESTIONCARTE_BRANCH=main
GIT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

#### Bitbucket privé :
```bash
MASON_REPO_URL=https://bitbucket.org/monentreprise/mason.git
PAINTER_REPO_URL=https://bitbucket.org/monentreprise/painter.git
GESTIONCARTE_REPO_URL=https://bitbucket.org/monentreprise/gestioncarte.git
GIT_TOKEN=ATBB-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 🚀 Déploiement Mode Développement

### Étape 1 : Récupération et configuration du projet
```bash
# Cloner le projet de déploiement
git clone <URL_DU_PROJET_DEPLOIEMENT>
cd docker-cardmanager

# Vérifier la structure
ls -la

# Configurer Git pour vos dépôts
chmod +x configure-git.sh
./configure-git.sh

# Ou configuration manuelle
cp .env.template .env
# Éditer .env avec vos URLs et authentification
```

### Étape 2 : Construction et démarrage
```bash
# Rendre les scripts exécutables
chmod +x *.sh

# Option A : Avec données de test vides
docker-compose up -d

# Option B : Avec import de données existantes (si disponible)
./export-data.sh    # Si vous avez une base locale
./build-quick-standalone.sh
```

### Étape 3 : Vérification
```bash
# Vérifier que tous les services sont actifs
docker-compose ps

# Tester l'application web
curl -I http://localhost:8080
# Ou ouvrir dans un navigateur : http://localhost:8080

# Tester le service Painter
curl -I http://localhost:8081
```

### Étape 4 : Connexion à la base de données
```bash
# Via Docker (pas de client mysql nécessaire)
docker exec -it cardmanager-mariadb-dev bash

# Depuis votre machine (si mysql installé)
mysql -h localhost -P 3307 -u ia -pfoufafou dev
```

---

## 🏭 Déploiement Mode Production

### Étape 1 : Préparation de votre base de données

Assurez-vous d'avoir :
- Un conteneur MariaDB/MySQL opérationnel
- Une base de données créée
- Un utilisateur avec les droits appropriés

```sql
-- Exemple de configuration base
CREATE DATABASE cardmanager_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'cardmanager_user'@'%' IDENTIFIED BY 'VOTRE_MOT_DE_PASSE_SECURISE';
GRANT ALL PRIVILEGES ON cardmanager_prod.* TO 'cardmanager_user'@'%';
FLUSH PRIVILEGES;
```

### Étape 2 : Configuration pour la production

Créez un fichier `docker-compose.production.yml` :

```yaml
services:
  mason:
    image: cardmanager/mason:latest
    container_name: cardmanager-mason-prod
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://VOTRE_DB_HOST:3306/cardmanager_prod
      - SPRING_DATASOURCE_USERNAME=cardmanager_user
      - SPRING_DATASOURCE_PASSWORD=VOTRE_MOT_DE_PASSE_SECURISE
      - SPRING_PROFILES_ACTIVE=production
    networks:
      - VOTRE_RESEAU_PRODUCTION

  painter:
    image: cardmanager/painter:latest
    container_name: cardmanager-painter-prod
    ports:
      - "8081:8081"
    depends_on:
      - mason
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://VOTRE_DB_HOST:3306/cardmanager_prod
      - SPRING_DATASOURCE_USERNAME=cardmanager_user
      - SPRING_DATASOURCE_PASSWORD=VOTRE_MOT_DE_PASSE_SECURISE
      - SPRING_PROFILES_ACTIVE=production
      - PAINTER_IMAGE_STORAGE_PATH=/app/images
    volumes:
      - cardmanager_images_prod:/app/images
    networks:
      - VOTRE_RESEAU_PRODUCTION

  gestioncarte:
    image: cardmanager/gestioncarte:latest
    container_name: cardmanager-gestioncarte-prod
    ports:
      - "8080:8080"
    depends_on:
      - mason
      - painter
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://VOTRE_DB_HOST:3306/cardmanager_prod
      - SPRING_DATASOURCE_USERNAME=cardmanager_user
      - SPRING_DATASOURCE_PASSWORD=VOTRE_MOT_DE_PASSE_SECURISE
      - SPRING_PROFILES_ACTIVE=production
      - PAINTER_SERVICE_URL=http://painter:8081
      - SPRING_LIQUIBASE_ENABLED=false
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
    networks:
      - VOTRE_RESEAU_PRODUCTION

volumes:
  cardmanager_images_prod:
    name: cardmanager_images_prod

networks:
  VOTRE_RESEAU_PRODUCTION:
    external: true
```

### Étape 3 : Construction des images de production

```bash
# Construire les images optimisées
docker build -f docker/mason/Dockerfile -t cardmanager/mason:latest .
docker build -f docker/painter/Dockerfile -t cardmanager/painter:latest .
docker build -f docker/gestioncarte/Dockerfile -t cardmanager/gestioncarte:latest .

# Optionnel : Push vers un registry
docker tag cardmanager/mason:latest VOTRE_REGISTRY/cardmanager/mason:latest
docker push VOTRE_REGISTRY/cardmanager/mason:latest
# ... répéter pour painter et gestioncarte
```

### Étape 4 : Déploiement en production

```bash
# Personnaliser la configuration
cp docker-compose.production.yml docker-compose.prod.yml
# Éditer docker-compose.prod.yml avec vos valeurs

# Démarrer en production
docker-compose -f docker-compose.prod.yml up -d

# Vérifier le déploiement
docker-compose -f docker-compose.prod.yml ps
curl -I http://VOTRE_SERVER:8080
```

---

## 🔧 Configuration Avancée

### Variables d'environnement importantes

| Variable | Description | Valeur par défaut |
|----------|-------------|------------------|
| `SPRING_DATASOURCE_URL` | URL de connexion à la base | `jdbc:mariadb://mariadb-standalone:3306/dev` |
| `SPRING_DATASOURCE_USERNAME` | Utilisateur base de données | `ia` |
| `SPRING_DATASOURCE_PASSWORD` | Mot de passe base de données | `foufafou` |
| `SPRING_PROFILES_ACTIVE` | Profil Spring actif | `docker` |
| `PAINTER_SERVICE_URL` | URL du service Painter | `http://painter:8081` |
| `PAINTER_IMAGE_STORAGE_PATH` | Chemin stockage images | `/app/images` |

### Configuration réseau

```bash
# Créer un réseau personnalisé
docker network create cardmanager-network

# Connecter votre base de données au réseau
docker network connect cardmanager-network VOTRE_CONTENEUR_DB
```

### Gestion des volumes

```bash
# Lister les volumes
docker volume ls | grep cardmanager

# Sauvegarder un volume
docker run --rm -v cardmanager_db_data:/source -v $(pwd):/backup alpine tar czf /backup/db_backup.tar.gz -C /source .

# Restaurer un volume
docker run --rm -v cardmanager_db_data:/target -v $(pwd):/backup alpine tar xzf /backup/db_backup.tar.gz -C /target
```

---

## 🔍 Dépannage

### Problèmes courants

#### 1. Port déjà utilisé
```bash
# Identifier le processus
sudo lsof -i :8080
# Tuer le processus ou changer le port
```

#### 2. Problème de connexion base de données
```bash
# Tester la connexion réseau
docker exec -it cardmanager-gestioncarte-prod ping VOTRE_DB_HOST

# Vérifier les logs
docker-compose logs gestioncarte | grep -i "database\|connection\|error"
```

#### 3. Images non trouvées
```bash
# Reconstruire les images
docker-compose build --no-cache

# Vérifier les images disponibles
docker images | grep cardmanager
```

#### 4. Service ne démarre pas
```bash
# Logs détaillés
docker-compose logs -f [service_name]

# État des conteneurs
docker-compose ps

# Ressources système
docker stats
```

### Logs utiles

```bash
# Logs de tous les services
docker-compose logs

# Logs d'un service spécifique
docker-compose logs -f gestioncarte

# Logs avec timestamps
docker-compose logs -t --tail=50 gestioncarte

# Suivre les logs en temps réel
docker-compose logs -f
```

### Commandes de maintenance

```bash
# Redémarrer un service
docker-compose restart gestioncarte

# Redémarrer tout l'environnement
docker-compose restart

# Mettre à jour les images
docker-compose pull
docker-compose up -d

# Nettoyer l'environnement
docker-compose down --volumes --remove-orphans
docker system prune -f
```

---

## 📊 Monitoring et Santé

### Vérifications de santé

```bash
# Status des conteneurs
docker-compose ps

# Santé de l'application
curl -f http://localhost:8080/actuator/health

# Métriques (si disponible)
curl http://localhost:8080/actuator/metrics
```

### Surveillance des ressources

```bash
# Utilisation CPU/Mémoire
docker stats

# Espace disque des volumes
docker system df

# Logs d'erreurs
docker-compose logs | grep -i error
```

---

## 🚨 Sécurité

### Recommandations de production

1. **Mots de passe forts** : Utilisez des mots de passe complexes
2. **Réseau isolé** : Créez un réseau Docker dédié
3. **HTTPS** : Utilisez un reverse proxy (nginx, traefik)
4. **Firewall** : Limitez l'accès aux ports nécessaires
5. **Backups** : Sauvegardez régulièrement les volumes

### Configuration HTTPS (exemple avec nginx)

```nginx
server {
    listen 443 ssl;
    server_name votre-domaine.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 📞 Support

### Informations de diagnostic

En cas de problème, fournissez :

```bash
# Version Docker
docker --version
docker-compose --version

# État des services
docker-compose ps

# Logs récents
docker-compose logs --tail=100

# Configuration réseau
docker network ls
docker network inspect cardmanager-network

# Utilisation des ressources
docker stats --no-stream
```

### Structure des logs

Les logs sont organisés par service :
- `gestioncarte` : Application principale
- `painter` : Service d'images
- `mason` : Services internes
- `mariadb-standalone` : Base de données (mode dev)

---

## ✅ Checklist de déploiement

### Avant déploiement
- [ ] Docker et Docker Compose installés
- [ ] Ports 8080, 8081 libres
- [ ] Base de données configurée (production)
- [ ] Réseau Docker créé (production)
- [ ] Variables d'environnement définies

### Après déploiement
- [ ] Tous les conteneurs sont UP
- [ ] Application accessible sur port 8080
- [ ] Service Painter accessible sur port 8081
- [ ] Connexion base de données opérationnelle
- [ ] Logs sans erreurs critiques
- [ ] Tests fonctionnels passés

### Maintenance régulière
- [ ] Backup des volumes
- [ ] Surveillance des logs
- [ ] Mise à jour des images
- [ ] Monitoring des ressources
- [ ] Tests de santé automatisés