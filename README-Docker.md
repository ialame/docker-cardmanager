# Configuration Docker Multi-Services

Ce projet configure un environnement Docker complet pour vos trois applications : Mason, Painter, et GestionCarte.

## 🏗️ Architecture

- **MariaDB** (port 3306) : Base de données principale
- **Mason** : Bibliothèque commune (services utilitaires)
- **Painter** (port 8081) : Service de gestion d'images
- **GestionCarte** (port 8080) : Application principale

## 🚀 Démarrage rapide

1. **Cloner vos dépôts et préparer l'environnement :**
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

2. **Ou démarrage manuel :**
   ```bash
   # Créer la structure
   mkdir -p docker/mason docker/painter docker/gestioncarte init-db config
   
   # Démarrer les services
   docker-compose up -d
   ```

## 📁 Structure des fichiers

```
├── docker-compose.yml              # Configuration principale
├── build.sh                        # Script de build automatisé
├── docker/
│   ├── mason/Dockerfile            # Image Mason
│   ├── painter/Dockerfile          # Image Painter
│   └── gestioncarte/Dockerfile     # Image GestionCarte
├── config/
│   └── application-docker.properties  # Configuration Spring Boot
└── init-db/
    └── 01-init.sql                 # Initialisation de la DB
```

## 🔧 Configuration

### Base de données
- **URL** : `jdbc:mariadb://mariadb:3306/dev`
- **Utilisateur** : `ia`
- **Mot de passe** : `foufafou`

### Services
- **Painter** : http://localhost:8081
- **GestionCarte** : http://localhost:8080
- **MariaDB** : localhost:3306

## 📊 Commandes utiles

```bash
# Voir les logs d'un service
docker-compose logs -f [service_name]

# Redémarrer un service
docker-compose restart [service_name]

# Accéder à un conteneur
docker-compose exec [service_name] sh

# Vérifier le statut
docker-compose ps

# Arrêter tout
docker-compose down

# Nettoyer complètement
docker-compose down --volumes --remove-orphans
docker system prune -f
```

## 🔍 Dépannage

### Problèmes de build
1. Vérifiez que les URLs GitHub sont accessibles
2. Assurez-vous que les Dockerfiles pointent vers les bons JARs
3. Vérifiez les logs : `docker-compose logs builder`

### Problèmes de connexion DB
1. Vérifiez que MariaDB est démarré : `docker-compose ps mariadb`
2. Testez la connexion : `docker-compose exec mariadb mysql -u ia -p dev`

### Services qui ne démarrent pas
1. Vérifiez les health checks : `docker-compose ps`
2. Regardez les logs détaillés : `docker-compose logs -f [service_name]`

## 🛠️ Personnalisation

### Modifier les ports
Éditez le fichier `docker-compose.yml` section `ports`.

### Ajouter des variables d'environnement
Ajoutez-les dans la section `environment` de chaque service.

### Changer la configuration de la DB
Modifiez le fichier `init-db/01-init.sql`.

## 📝 Notes importantes

- Les dépôts GitHub sont clonés à chaque build
- Les volumes persistants sauvegardent les données DB et images
- Les health checks garantissent l'ordre de démarrage
- Configuration optimisée pour le développement