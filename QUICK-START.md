# ⚡ Quick Start Guide - CardManager

## 🎯 Démarrage en 5 minutes

### 1. **Prérequis** (2 min)
```bash
# Vérifier Docker
docker --version  # >= 20.10
docker-compose --version  # >= 2.0

# Vérifier les ports libres
netstat -tuln | grep -E "(8080|8081)"  # Doivent être libres
```

### 2. **Installation** (1 min)
```bash
# Cloner le projet
git clone <URL_DU_PROJET>
cd docker-cardmanager

# Rendre les scripts exécutables
chmod +x *.sh
```

### 3. **Démarrage** (2 min)
```bash
# Démarrage simple (base vide)
docker-compose up -d

# OU avec vos données existantes
./export-data.sh && ./build-quick-standalone.sh
```

### 4. **Vérification** (30 sec)
```bash
# Vérifier que tout fonctionne
docker-compose ps
curl -I http://localhost:8080
```

### 5. **Accès**
- 🌐 **Application** : http://localhost:8080
- 🎨 **Painter** : http://localhost:8081
- 🗄️ **Base** : localhost:3307 (ia/foufafou)

---

## 🚀 Commandes essentielles

```bash
# Démarrer
docker-compose up -d

# Arrêter  
docker-compose down

# Logs
docker-compose logs -f

# Statut
docker-compose ps

# Nettoyer
docker-compose down --volumes
```

---

## 🏭 Production rapide

### Modifier `docker-compose.yml` :
```yaml
environment:
  - SPRING_DATASOURCE_URL=jdbc:mariadb://VOTRE_DB:3306/prod
  - SPRING_DATASOURCE_USERNAME=prod_user
  - SPRING_DATASOURCE_PASSWORD=prod_password
```

### Démarrer :
```bash
docker-compose up -d
```

C'est tout ! 🎉