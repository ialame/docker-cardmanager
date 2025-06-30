#!/bin/bash

# 🔧 Correction SSH Bitbucket - Solution Complète
# Ce script corrige le problème SSH dans les Dockerfiles

echo "🔧 Correction SSH pour Bitbucket"
echo "================================"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🎯 Problème identifié : SSH manquant dans les conteneurs Docker${NC}"
echo -e "${YELLOW}📋 Solution : Installer openssh-client et corriger les scripts Git${NC}"
echo ""

# 1. Sauvegarder les Dockerfiles actuels
echo -e "${BLUE}💾 Sauvegarde des Dockerfiles actuels...${NC}"
[ -f "docker/painter/Dockerfile" ] && cp docker/painter/Dockerfile docker/painter/Dockerfile.backup
[ -f "docker/gestioncarte/Dockerfile" ] && cp docker/gestioncarte/Dockerfile docker/gestioncarte/Dockerfile.backup
echo -e "${GREEN}✅ Dockerfiles sauvegardés${NC}"

# 2. Correction du Dockerfile Painter
echo -e "${BLUE}🎨 Correction du Dockerfile Painter...${NC}"
mkdir -p docker/painter
cat > docker/painter/Dockerfile << 'EOF'
# 🎨 Dockerfile Painter - Version Bitbucket SSH Corrigée
FROM maven:3.9.6-eclipse-temurin-21 AS builder
WORKDIR /usr/src/app

# CRITIQUE : Installer openssh-client pour SSH
RUN apt-get update && \
    apt-get install -y git openssh-client curl && \
    rm -rf /var/lib/apt/lists/* && \
    echo "✅ SSH client installé"

# Arguments pour les dépôts Bitbucket
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_BRANCH=feature/card-manager-511
ARG GIT_TOKEN
ARG SSH_PRIVATE_KEY

# Configuration SSH pour Bitbucket
RUN mkdir -p ~/.ssh && \
    chmod 700 ~/.ssh && \
    echo "✅ Dossier SSH créé"

# Ajouter les fingerprints SSH
RUN ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts && \
    echo "✅ Fingerprint Bitbucket ajouté"

# Configurer la clé SSH si fournie
RUN if [ ! -z "$SSH_PRIVATE_KEY" ]; then \
        echo "$SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa && \
        chmod 600 ~/.ssh/id_rsa && \
        echo "✅ Clé SSH configurée"; \
    else \
        echo "⚠️ Aucune clé SSH fournie"; \
    fi

# Configuration Git
RUN git config --global user.email "docker@cardmanager.local" && \
    git config --global user.name "Docker Builder" && \
    git config --global init.defaultBranch main && \
    echo "✅ Git configuré"

# Créer un POM parent complet
RUN echo '<?xml version="1.0" encoding="UTF-8"?>' > pom.xml && \
    echo '<project xmlns="http://maven.apache.org/POM/4.0.0"' >> pom.xml && \
    echo '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' >> pom.xml && \
    echo '         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">' >> pom.xml && \
    echo '    <modelVersion>4.0.0</modelVersion>' >> pom.xml && \
    echo '    <parent>' >> pom.xml && \
    echo '        <groupId>org.springframework.boot</groupId>' >> pom.xml && \
    echo '        <artifactId>spring-boot-starter-parent</artifactId>' >> pom.xml && \
    echo '        <version>3.2.5</version>' >> pom.xml && \
    echo '        <relativePath/>' >> pom.xml && \
    echo '    </parent>' >> pom.xml && \
    echo '    <groupId>com.pcagrade</groupId>' >> pom.xml && \
    echo '    <artifactId>cardmanager</artifactId>' >> pom.xml && \
    echo '    <version>1.0.0-SNAPSHOT</version>' >> pom.xml && \
    echo '    <packaging>pom</packaging>' >> pom.xml && \
    echo '    <properties>' >> pom.xml && \
    echo '        <java.version>21</java.version>' >> pom.xml && \
    echo '        <maven.compiler.source>21</maven.compiler.source>' >> pom.xml && \
    echo '        <maven.compiler.target>21</maven.compiler.target>' >> pom.xml && \
    echo '        <mason.version>2.4.1</mason.version>' >> pom.xml && \
    echo '    </properties>' >> pom.xml && \
    echo '</project>' >> pom.xml

# Installer le POM parent
RUN mvn install -N && echo "✅ POM parent installé"

# Script de clone SSH intelligent et robuste
RUN echo '#!/bin/bash' > /usr/local/bin/git-clone-enhanced.sh && \
    echo 'set -e' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'REPO_URL="$1"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'TARGET_DIR="$2"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'BRANCH="${3:-main}"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'TOKEN="$4"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'echo "🔍 Clonage de $REPO_URL (branche: $BRANCH)..."' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '# Test de connexion SSH' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'if echo "$REPO_URL" | grep -q "git@"; then' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    echo "📡 Test SSH..."' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    ssh -T git@bitbucket.org -o ConnectTimeout=10 -o BatchMode=yes || echo "⚠️ SSH test warning"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'fi' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '# Clone avec retry' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'for i in {1..3}; do' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    if git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"; then' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '        echo "✅ Clone réussi pour $TARGET_DIR"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '        exit 0' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    else' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '        echo "❌ Tentative $i échouée, retry..."' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '        sleep 2' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    fi' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'done' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'echo "❌ Clone échoué après 3 tentatives"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'exit 1' >> /usr/local/bin/git-clone-enhanced.sh && \
    chmod +x /usr/local/bin/git-clone-enhanced.sh

# Cloner Mason et Painter depuis Bitbucket
RUN /usr/local/bin/git-clone-enhanced.sh "$MASON_REPO_URL" mason "$MASON_BRANCH" "$GIT_TOKEN"
RUN /usr/local/bin/git-clone-enhanced.sh "$PAINTER_REPO_URL" painter "$PAINTER_BRANCH" "$GIT_TOKEN"

# Construire Mason
WORKDIR /usr/src/app/mason
RUN echo "🔨 Construction de Mason..." && \
    mvn clean install -DskipTests -q && \
    echo "✅ Mason construit avec succès"

# Construire Painter
WORKDIR /usr/src/app/painter
RUN echo "🎨 Construction de Painter..." && \
    mvn clean package -DskipTests -q && \
    echo "✅ Painter construit avec succès"

# Diagnostic des JARs créés
RUN echo "📦 JARs trouvés:" && \
    find /usr/src/app -name "*.jar" -type f | grep -E "(painter|target)" | head -10

# ==========================================
# Stage de production
# ==========================================
FROM eclipse-temurin:21-jre-alpine
LABEL maintainer="ibrahim.alame@gmail.com"
WORKDIR /app

# Installer curl pour les health checks
RUN apk add --no-cache curl && \
    echo "✅ Runtime configuré"

# Copier le JAR Painter (chemin corrigé)
COPY --from=builder /usr/src/app/painter/painter/target/painter-*.jar ./app.jar

# Créer le dossier images
RUN mkdir -p /app/images && \
    chmod 755 /app/images && \
    echo "✅ Dossier images créé"

# Port d'exposition
EXPOSE 8081

# Variables d'environnement
ENV SPRING_PROFILES_ACTIVE=docker

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8081/actuator/health || exit 1

# Point d'entrée
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

echo -e "${GREEN}✅ Dockerfile Painter corrigé${NC}"

# 3. Correction du Dockerfile GestionCarte
echo -e "${BLUE}🖼️ Correction du Dockerfile GestionCarte...${NC}"
mkdir -p docker/gestioncarte
cat > docker/gestioncarte/Dockerfile << 'EOF'
# 🖼️ Dockerfile GestionCarte - Version Bitbucket SSH Corrigée
FROM maven:3.9.6-eclipse-temurin-21 AS builder
WORKDIR /usr/src/app

# CRITIQUE : Installer openssh-client pour SSH
RUN apt-get update && \
    apt-get install -y git openssh-client curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    echo "✅ SSH client et Node.js installés"

# Arguments pour les dépôts Bitbucket
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
ARG GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_BRANCH=feature/card-manager-511
ARG GESTIONCARTE_BRANCH=feature/card-manager-511
ARG GIT_TOKEN
ARG SSH_PRIVATE_KEY

# Configuration SSH pour Bitbucket
RUN mkdir -p ~/.ssh && \
    chmod 700 ~/.ssh && \
    ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts && \
    echo "✅ SSH configuré pour Bitbucket"

# Configurer la clé SSH si fournie
RUN if [ ! -z "$SSH_PRIVATE_KEY" ]; then \
        echo "$SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa && \
        chmod 600 ~/.ssh/id_rsa && \
        echo "✅ Clé SSH configurée"; \
    fi

# Configuration Git
RUN git config --global user.email "docker@cardmanager.local" && \
    git config --global user.name "Docker Builder"

# Créer POM parent
RUN echo '<?xml version="1.0" encoding="UTF-8"?>' > pom.xml && \
    echo '<project xmlns="http://maven.apache.org/POM/4.0.0"' >> pom.xml && \
    echo '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' >> pom.xml && \
    echo '         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">' >> pom.xml && \
    echo '    <modelVersion>4.0.0</modelVersion>' >> pom.xml && \
    echo '    <parent>' >> pom.xml && \
    echo '        <groupId>org.springframework.boot</groupId>' >> pom.xml && \
    echo '        <artifactId>spring-boot-starter-parent</artifactId>' >> pom.xml && \
    echo '        <version>3.2.5</version>' >> pom.xml && \
    echo '        <relativePath/>' >> pom.xml && \
    echo '    </parent>' >> pom.xml && \
    echo '    <groupId>com.pcagrade</groupId>' >> pom.xml && \
    echo '    <artifactId>cardmanager</artifactId>' >> pom.xml && \
    echo '    <version>1.0.0-SNAPSHOT</version>' >> pom.xml && \
    echo '    <packaging>pom</packaging>' >> pom.xml && \
    echo '    <properties>' >> pom.xml && \
    echo '        <java.version>21</java.version>' >> pom.xml && \
    echo '        <maven.compiler.source>21</maven.compiler.source>' >> pom.xml && \
    echo '        <maven.compiler.target>21</maven.compiler.target>' >> pom.xml && \
    echo '    </properties>' >> pom.xml && \
    echo '</project>' >> pom.xml

RUN mvn install -N

# Script de clone SSH robuste
RUN echo '#!/bin/bash' > /usr/local/bin/git-clone-smart.sh && \
    echo 'set -e' >> /usr/local/bin/git-clone-smart.sh && \
    echo 'REPO_URL=$1' >> /usr/local/bin/git-clone-smart.sh && \
    echo 'TARGET_DIR=$2' >> /usr/local/bin/git-clone-smart.sh && \
    echo 'BRANCH=${3:-main}' >> /usr/local/bin/git-clone-smart.sh && \
    echo 'TOKEN=$4' >> /usr/local/bin/git-clone-smart.sh && \
    echo 'echo "🔍 Clonage de $REPO_URL (branche: $BRANCH)..."' >> /usr/local/bin/git-clone-smart.sh && \
    echo 'for i in {1..3}; do' >> /usr/local/bin/git-clone-smart.sh && \
    echo '    if git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"; then' >> /usr/local/bin/git-clone-smart.sh && \
    echo '        echo "✅ Clone réussi pour $TARGET_DIR"' >> /usr/local/bin/git-clone-smart.sh && \
    echo '        exit 0' >> /usr/local/bin/git-clone-smart.sh && \
    echo '    else' >> /usr/local/bin/git-clone-smart.sh && \
    echo '        echo "❌ Tentative $i échouée"' >> /usr/local/bin/git-clone-smart.sh && \
    echo '        sleep 2' >> /usr/local/bin/git-clone-smart.sh && \
    echo '    fi' >> /usr/local/bin/git-clone-smart.sh && \
    echo 'done' >> /usr/local/bin/git-clone-smart.sh && \
    echo 'exit 1' >> /usr/local/bin/git-clone-smart.sh && \
    chmod +x /usr/local/bin/git-clone-smart.sh

# Cloner tous les dépôts
RUN /usr/local/bin/git-clone-smart.sh "$MASON_REPO_URL" mason "$MASON_BRANCH" "$GIT_TOKEN"
RUN /usr/local/bin/git-clone-smart.sh "$PAINTER_REPO_URL" painter "$PAINTER_BRANCH" "$GIT_TOKEN"
RUN /usr/local/bin/git-clone-smart.sh "$GESTIONCARTE_REPO_URL" gestioncarte "$GESTIONCARTE_BRANCH" "$GIT_TOKEN"

# Construire Mason
WORKDIR /usr/src/app/mason
RUN echo "🔨 Construction de Mason..." && \
    mvn clean install -DskipTests -q

# Construire Painter (pour les dépendances)
WORKDIR /usr/src/app/painter
RUN echo "🎨 Construction de Painter..." && \
    mvn clean install -DskipTests -q

# Construire GestionCarte
WORKDIR /usr/src/app/gestioncarte
RUN echo "🖼️ Construction de GestionCarte..." && \
    mvn clean package -DskipTests -q

# Stage de production
FROM eclipse-temurin:21-jre-alpine
LABEL maintainer="ibrahim.alame@gmail.com"
WORKDIR /app

# Installer curl pour health checks
RUN apk add --no-cache curl

# Copier le JAR GestionCarte
COPY --from=builder /usr/src/app/gestioncarte/target/gestioncarte-*.jar ./app.jar

# Port d'exposition
EXPOSE 8080

# Variables d'environnement
ENV SPRING_PROFILES_ACTIVE=docker

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Point d'entrée
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

echo -e "${GREEN}✅ Dockerfile GestionCarte corrigé${NC}"

# 4. Mise à jour du script de build SSH
echo -e "${BLUE}🔧 Mise à jour du script de build...${NC}"
cat > build-with-ssh-fixed.sh << 'EOF'
#!/bin/bash

# 🔑 Build CardManager avec SSH Bitbucket - Version Corrigée

echo "🔑 Build CardManager avec SSH (Version Corrigée)"
echo "================================================"

# Vérifications préliminaires
if [ ! -f ".env" ]; then
    echo "❌ Fichier .env manquant !"
    echo "💡 Créez un fichier .env avec :"
    cat << 'ENVEOF'
# Configuration SSH Bitbucket
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511
GIT_TOKEN=
DB_NAME=dev
DB_USER=ia
DB_PASSWORD=foufafou
DB_ROOT_PASSWORD=root_password
GESTIONCARTE_PORT=8080
PAINTER_PORT=8081
NGINX_PORT=8082
MARIADB_PORT=3307
ENVEOF
    exit 1
fi

# Détecter et encoder la clé SSH
SSH_KEY_FILE=""
if [ -f ~/.ssh/bitbucket_ed25519 ]; then
    SSH_KEY_FILE=~/.ssh/bitbucket_ed25519
elif [ -f ~/.ssh/id_ed25519 ]; then
    SSH_KEY_FILE=~/.ssh/id_ed25519
elif [ -f ~/.ssh/id_rsa ]; then
    SSH_KEY_FILE=~/.ssh/id_rsa
else
    echo "❌ Aucune clé SSH trouvée !"
    echo "💡 Créez une clé SSH :"
    echo "   ssh-keygen -t ed25519 -C 'votre.email@domain.com'"
    echo "   ssh-add ~/.ssh/id_ed25519"
    echo "   # Puis ajoutez la clé publique sur Bitbucket"
    exit 1
fi

echo "🔑 Clé SSH détectée : $SSH_KEY_FILE"

# Encoder la clé SSH
export SSH_PRIVATE_KEY=$(cat "$SSH_KEY_FILE" | base64 -w 0 2>/dev/null || cat "$SSH_KEY_FILE" | base64)

if [ -z "$SSH_PRIVATE_KEY" ]; then
    echo "❌ Erreur lors de l'encodage de la clé SSH"
    exit 1
fi

echo "✅ Clé SSH encodée (${#SSH_PRIVATE_KEY} caractères)"

# Test de connexion SSH
echo "🧪 Test de connexion SSH..."
if ssh -T git@bitbucket.org -o ConnectTimeout=5 -o BatchMode=yes 2>&1 | grep -q "logged in as"; then
    echo "✅ Connexion SSH OK"
else
    echo "❌ Connexion SSH échouée"
    echo "💡 Vérifiez :"
    echo "   1. Que votre clé SSH est ajoutée sur Bitbucket"
    echo "   2. Que ssh-agent est lancé : eval \$(ssh-agent -s) && ssh-add $SSH_KEY_FILE"
    echo "   3. Test manuel : ssh -T git@bitbucket.org"
    exit 1
fi

# Source du fichier .env
source .env

echo ""
echo "📋 Configuration :"
echo "   Mason: $MASON_REPO_URL"
echo "   Painter: $PAINTER_REPO_URL"
echo "   GestionCarte: $GESTIONCARTE_REPO_URL"

# Nettoyer l'environnement
echo ""
echo "🧹 Nettoyage..."
docker-compose down --volumes --remove-orphans 2>/dev/null

# Build avec SSH
echo ""
echo "🔨 Lancement du build avec SSH..."
if docker-compose build --no-cache; then
    echo ""
    echo "🎉 BUILD RÉUSSI !"
    echo ""
    echo "🚀 Démarrage des services..."
    docker-compose up -d

    echo ""
    echo "✅ Services démarrés !"
    echo "   📱 GestionCarte : http://localhost:${GESTIONCARTE_PORT:-8080}"
    echo "   🎨 Painter : http://localhost:${PAINTER_PORT:-8081}"
    echo "   🗄️ MariaDB : localhost:${MARIADB_PORT:-3307}"

else
    echo ""
    echo "❌ BUILD ÉCHOUÉ !"
    echo ""
    echo "🔍 Diagnostics :"
    echo "1. Vérifiez les logs : docker-compose logs"
    echo "2. Vérifiez SSH : ssh -T git@bitbucket.org"
    echo "3. Vérifiez les branches dans .env"
    echo "4. Vérifiez que openssh-client est installé dans les Dockerfiles"
    exit 1
fi
EOF

chmod +x build-with-ssh-fixed.sh
echo -e "${GREEN}✅ Script de build SSH créé${NC}"

# 5. Affichage du résumé
echo ""
echo -e "${GREEN}🎉 CORRECTION TERMINÉE !${NC}"
echo -e "${BLUE}═══════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 Ce qui a été corrigé :${NC}"
echo "   ✅ Ajout de openssh-client dans les Dockerfiles"
echo "   ✅ Scripts Git robustes avec retry"
echo "   ✅ Configuration SSH complète"
echo "   ✅ Gestion des clés SSH"
echo "   ✅ Script de build amélioré"
echo ""
echo -e "${YELLOW}🚀 Pour continuer :${NC}"
echo "   1. Vérifiez votre clé SSH : ssh -T git@bitbucket.org"
echo "   2. Lancez le build : ./build-with-ssh-fixed.sh"
echo ""
echo -e "${YELLOW}🔑 Si vous n'avez pas de clé SSH :${NC}"
echo "   ssh-keygen -t ed25519 -C 'votre.email@domain.com'"
echo "   ssh-add ~/.ssh/id_ed25519"
echo "   # Puis ajoutez ~/.ssh/id_ed25519.pub sur Bitbucket"
echo ""
echo -e "${GREEN}Le problème SSH devrait maintenant être résolu ! 🎯${NC}"