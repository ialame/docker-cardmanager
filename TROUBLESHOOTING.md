# 🔧 Guide de Dépannage - CardManager

## 🚨 Problèmes Courants

### 1. **Port déjà utilisé**
```
Error: bind: address already in use
```

**Solution :**
```bash
# Identifier le processus
sudo lsof -i :8080
sudo lsof -i :8081

# Tuer le processus
kill -9 PID

# Ou changer le port dans docker-compose.yml
ports:
  - "8082:8080"  # Utiliser 8082 au lieu de 8080
```

### 2. **Conteneur ne démarre pas**
```
Container exited with code 1
```

**Diagnostic :**
```bash
# Voir les logs détaillés
docker-compose logs -f [service_name]

# Vérifier l'état
docker-compose ps

# Redémarrer le service
docker-compose restart [service_name]
```

### 3. **Erreur de connexion base de données**
```
Could not open connection to database
```

**Solutions :**
```bash
# Vérifier que la base est accessible
docker exec -it cardmanager-mariadb-dev bash

# Tester la connectivité réseau
docker exec -it cardmanager-gestioncarte ping mariadb-standalone

# Vérifier les variables d'environnement
docker exec -it cardmanager-gestioncarte env | grep SPRING_DATASOURCE
```

### 4. **Page blanche / Erreur 404**
```
Application loads but shows blank page
```

**Solutions :**
```bash
# Vérifier le profil Spring actif
docker-compose logs gestioncarte | grep "profile is active"

# Doit afficher "docker" pas "local"
# Si "local", vérifier les variables d'environnement :
- SPRING_PROFILES_ACTIVE=docker
```

### 5. **Images Docker non trouvées**
```
Image not found / pull access denied
```

**Solutions :**
```bash
# Construire les images localement
docker-compose build --no-cache

# Vérifier les images disponibles
docker images | grep cardmanager

# Forcer la reconstruction
docker-compose down
docker-compose build
docker-compose up -d
```

### 6. **Problème de ressources / Lenteur**
```
Container runs slowly or crashes
```

**Solutions :**
```bash
# Vérifier l'utilisation des ressources
docker stats

# Augmenter la mémoire Java (dans docker-compose.yml)
environment:
  - JAVA_OPTS=-Xmx2048m -Xms1024m

# Nettoyer Docker
docker system prune -f
docker volume prune -f
```

### 7. **Erreur Maven lors du build**
```
Dependencies version missing
```

**Solution :**
```bash
# Utiliser le Dockerfile corrigé
# Le Dockerfile gestioncarte doit avoir le POM parent complet
# Voir docker/gestioncarte/Dockerfile ligne 3-50 pour le POM parent
```

---

## 🔍 Commandes de Diagnostic

### Vérification générale
```bash
# État complet de l'environnement
docker-compose ps
docker-compose logs --tail=50
docker stats --no-stream
```

### Vérification réseau
```bash
# Lister les réseaux
docker network ls

# Inspecter un réseau
docker network inspect cardmanager-network

# Tester la connectivité entre conteneurs
docker exec -it cardmanager-gestioncarte ping cardmanager-painter
```

### Vérification base de données
```bash
# Se connecter à la base (si mysql installé localement)
mysql -h localhost -P 3307 -u ia -pfoufafou dev

# Compter les tables
mysql -h localhost -P 3307 -u ia -pfoufafou -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='dev';" dev
```

### Vérification application
```bash
# Test simple de l'application
curl -I http://localhost:8080

# Test avec timeout
timeout 10 curl http://localhost:8080

# Vérifier les endpoints Spring Boot (si disponibles)
curl http://localhost:8080/actuator/health
```

---

## 🧹 Nettoyage et Reset

### Nettoyage léger
```bash
# Redémarrer les services
docker-compose restart

# Nettoyer les logs
docker-compose logs --since 1h
```

### Nettoyage complet
```bash
# Arrêter et supprimer les conteneurs
docker-compose down --volumes --remove-orphans

# Nettoyer Docker
docker system prune -f
docker volume prune -f
docker network prune -f

# Reconstruire depuis zéro
docker-compose build --no-cache
docker-compose up -d
```

### Reset total (⚠️ PERTE DE DONNÉES)
```bash
# ATTENTION : Supprime TOUTES les données
docker-compose down --volumes --remove-orphans
docker system prune -a -f
docker volume rm $(docker volume ls -q | grep cardmanager)

# Redémarrage complet
docker-compose up -d
```

---

## 📊 Monitoring en Temps Réel

### Surveillance continue
```bash
# Logs en temps réel de tous les services
docker-compose logs -f

# Logs d'un service spécifique
docker-compose logs -f gestioncarte

# Métriques système
watch docker stats

# Espace disque
watch "docker system df"
```

### Alertes automatiques
```bash
# Script de monitoring (à adapter)
#!/bin/bash
while true; do
    if ! curl -f -s http://localhost:8080 > /dev/null; then
        echo "ALERT: Application down at $(date)"
        # Envoyer notification / email
    fi
    sleep 60
done
```

---

## 🆘 Récupération d'urgence

### Sauvegarde rapide
```bash
# Sauvegarder les volumes critiques
docker run --rm -v cardmanager_db_data:/source -v $(pwd):/backup alpine tar czf /backup/emergency_db_backup_$(date +%Y%m%d_%H%M).tar.gz -C /source .
```

### Restauration rapide
```bash
# Restaurer depuis une sauvegarde
docker run --rm -v cardmanager_db_data:/target -v $(pwd):/backup alpine tar xzf /backup/emergency_db_backup_YYYYMMDD_HHMM.tar.gz -C /target
```

### Rollback
```bash
# Revenir à une version antérieure
docker tag cardmanager/gestioncarte:latest cardmanager/gestioncarte:backup
docker pull cardmanager/gestioncarte:previous
docker tag cardmanager/gestioncarte:previous cardmanager/gestioncarte:latest
docker-compose up -d
```

---

## 📞 Obtenir de l'aide

### Informations à fournir
```bash
# Collecter les informations de diagnostic
echo "=== SYSTÈME ===" > diagnostic.txt
docker --version >> diagnostic.txt
docker-compose --version >> diagnostic.txt
echo "" >> diagnostic.txt

echo "=== ÉTAT DES SERVICES ===" >> diagnostic.txt
docker-compose ps >> diagnostic.txt
echo "" >> diagnostic.txt

echo "=== LOGS RÉCENTS ===" >> diagnostic.txt
docker-compose logs --tail=100 >> diagnostic.txt
echo "" >> diagnostic.txt

echo "=== RESSOURCES ===" >> diagnostic.txt
docker stats --no-stream >> diagnostic.txt
echo "" >> diagnostic.txt

echo "=== RÉSEAU ===" >> diagnostic.txt
docker network ls >> diagnostic.txt
```

### Contacts et ressources
- 📖 Documentation complète : `GUIDE-DEPLOIEMENT.md`
- ⚡ Démarrage rapide : `QUICK-START.md`
- 🐳 Docker Compose : `docker-compose.yml`
- 🔧 Scripts utiles : `*.sh`