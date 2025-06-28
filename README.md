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
