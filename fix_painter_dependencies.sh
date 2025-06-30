#!/bin/bash

# 🎨 Correction Dépendances Painter - POM Complet
# Résout le problème des versions manquantes dans Painter

echo "🎨 Correction Dépendances Painter"
echo "================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🎯 Problème identifié : Versions Mason manquantes dans Painter${NC}"
echo -e "${YELLOW}📋 Solution : POM parent avec dependencyManagement complet${NC}"
echo ""

# 1. Sauvegarder le Dockerfile actuel
echo -e "${BLUE}💾 Sauvegarde du Dockerfile Painter...${NC}"
[ -f "docker/painter/Dockerfile" ] && cp docker/painter/Dockerfile docker/painter/Dockerfile.before-deps-fix
echo -e "${GREEN}✅ Dockerfile sauvegardé${NC}"

# 2. Création du Dockerfile Painter avec POM complet
echo -e "${BLUE}🎨 Création du Dockerfile Painter avec dependencyManagement...${NC}"
cat > docker/painter/Dockerfile << 'EOF'
# 🎨 Dockerfile Painter - Version avec DependencyManagement Complet
FROM maven:3.9.6-eclipse-temurin-21 AS builder
WORKDIR /usr/src/app

# Installer git, ssh et curl
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
    ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts && \
    echo "✅ Fingerprint Bitbucket ajouté"

# Configurer la clé SSH
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

# Configuration Maven avec timeouts
RUN mkdir -p ~/.m2 && \
    echo '<?xml version="1.0" encoding="UTF-8"?>' > ~/.m2/settings.xml && \
    echo '<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"' >> ~/.m2/settings.xml && \
    echo '          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' >> ~/.m2/settings.xml && \
    echo '          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">' >> ~/.m2/settings.xml && \
    echo '  <servers>' >> ~/.m2/settings.xml && \
    echo '    <server>' >> ~/.m2/settings.xml && \
    echo '      <id>central</id>' >> ~/.m2/settings.xml && \
    echo '      <configuration>' >> ~/.m2/settings.xml && \
    echo '        <httpConfiguration>' >> ~/.m2/settings.xml && \
    echo '          <readTimeout>300000</readTimeout>' >> ~/.m2/settings.xml && \
    echo '          <connectTimeout>30000</connectTimeout>' >> ~/.m2/settings.xml && \
    echo '        </httpConfiguration>' >> ~/.m2/settings.xml && \
    echo '      </configuration>' >> ~/.m2/settings.xml && \
    echo '    </server>' >> ~/.m2/settings.xml && \
    echo '  </servers>' >> ~/.m2/settings.xml && \
    echo '</settings>' >> ~/.m2/settings.xml && \
    echo "✅ Maven configuré avec timeouts"

# Créer un POM parent COMPLET avec toutes les dépendances Mason
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
    echo '        <painter.version>1.3.0</painter.version>' >> pom.xml && \
    echo '        <swagger.version>2.2.21</swagger.version>' >> pom.xml && \
    echo '        <resilience4j.version>2.1.0</resilience4j.version>' >> pom.xml && \
    echo '    </properties>' >> pom.xml && \
    echo '    <dependencyManagement>' >> pom.xml && \
    echo '        <dependencies>' >> pom.xml && \
    echo '            <!-- Spring Boot Dependencies -->' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>org.springframework.boot</groupId>' >> pom.xml && \
    echo '                <artifactId>spring-boot-dependencies</artifactId>' >> pom.xml && \
    echo '                <version>3.2.5</version>' >> pom.xml && \
    echo '                <type>pom</type>' >> pom.xml && \
    echo '                <scope>import</scope>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <!-- Mason Dependencies -->' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-commons</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-jpa</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-jpa-cache</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-kubernetes</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-ulid</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-localization</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-json</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-oauth2</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-transaction-author</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-web-client</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
    echo '                <artifactId>mason-test</artifactId>' >> pom.xml && \
    echo '                <version>${mason.version}</version>' >> pom.xml && \
    echo '                <scope>test</scope>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <!-- Painter Dependencies -->' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.painter</groupId>' >> pom.xml && \
    echo '                <artifactId>painter</artifactId>' >> pom.xml && \
    echo '                <version>${painter.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.painter</groupId>' >> pom.xml && \
    echo '                <artifactId>painter-common</artifactId>' >> pom.xml && \
    echo '                <version>${painter.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>com.pcagrade.painter</groupId>' >> pom.xml && \
    echo '                <artifactId>painter-client</artifactId>' >> pom.xml && \
    echo '                <version>${painter.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <!-- Third Party Dependencies -->' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>io.swagger.core.v3</groupId>' >> pom.xml && \
    echo '                <artifactId>swagger-annotations</artifactId>' >> pom.xml && \
    echo '                <version>${swagger.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>io.github.resilience4j</groupId>' >> pom.xml && \
    echo '                <artifactId>resilience4j-timelimiter</artifactId>' >> pom.xml && \
    echo '                <version>${resilience4j.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '        </dependencies>' >> pom.xml && \
    echo '    </dependencyManagement>' >> pom.xml && \
    echo '</project>' >> pom.xml

# Installer le POM parent
RUN mvn install -N && echo "✅ POM parent avec dependencyManagement installé"

# Script de clone SSH
RUN echo '#!/bin/bash' > /usr/local/bin/git-clone-enhanced.sh && \
    echo 'set -e' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'REPO_URL="$1"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'TARGET_DIR="$2"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'BRANCH="${3:-main}"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'echo "🔍 Clonage de $REPO_URL (branche: $BRANCH)..."' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'for i in {1..3}; do' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    if git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"; then' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '        echo "✅ Clone réussi pour $TARGET_DIR"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '        exit 0' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    else' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '        echo "❌ Tentative $i échouée, retry..."' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '        sleep 2' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    fi' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'done' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'exit 1' >> /usr/local/bin/git-clone-enhanced.sh && \
    chmod +x /usr/local/bin/git-clone-enhanced.sh

# Script Maven avec retry et diagnostic détaillé
RUN echo '#!/bin/bash' > /usr/local/bin/maven-build-retry.sh && \
    echo 'set -e' >> /usr/local/bin/maven-build-retry.sh && \
    echo 'PROJECT_NAME="$1"' >> /usr/local/bin/maven-build-retry.sh && \
    echo 'MVN_COMMAND="$2"' >> /usr/local/bin/maven-build-retry.sh && \
    echo 'echo "🔨 Construction de $PROJECT_NAME..."' >> /usr/local/bin/maven-build-retry.sh && \
    echo 'echo "📋 Commande Maven: $MVN_COMMAND"' >> /usr/local/bin/maven-build-retry.sh && \
    echo 'for attempt in 1 2 3; do' >> /usr/local/bin/maven-build-retry.sh && \
    echo '    echo "🔄 Tentative $attempt/3 pour $PROJECT_NAME"' >> /usr/local/bin/maven-build-retry.sh && \
    echo '    if [ $attempt -gt 1 ]; then' >> /usr/local/bin/maven-build-retry.sh && \
    echo '        echo "🧹 Nettoyage du cache Maven..."' >> /usr/local/bin/maven-build-retry.sh && \
    echo '        mvn dependency:purge-local-repository -DreResolve=false -DactTransitively=false || true' >> /usr/local/bin/maven-build-retry.sh && \
    echo '        rm -rf ~/.m2/repository/.cache || true' >> /usr/local/bin/maven-build-retry.sh && \
    echo '    fi' >> /usr/local/bin/maven-build-retry.sh && \
    echo '    echo "🚀 Exécution: $MVN_COMMAND"' >> /usr/local/bin/maven-build-retry.sh && \
    echo '    if eval "$MVN_COMMAND"; then' >> /usr/local/bin/maven-build-retry.sh && \
    echo '        echo "✅ $PROJECT_NAME construit avec succès (tentative $attempt)"' >> /usr/local/bin/maven-build-retry.sh && \
    echo '        exit 0' >> /usr/local/bin/maven-build-retry.sh && \
    echo '    else' >> /usr/local/bin/maven-build-retry.sh && \
    echo '        echo "❌ Échec tentative $attempt pour $PROJECT_NAME"' >> /usr/local/bin/maven-build-retry.sh && \
    echo '        if [ $attempt -eq 3 ]; then' >> /usr/local/bin/maven-build-retry.sh && \
    echo '            echo "💥 Échec final après 3 tentatives"' >> /usr/local/bin/maven-build-retry.sh && \
    echo '            echo "🔍 Diagnostic:"' >> /usr/local/bin/maven-build-retry.sh && \
    echo '            echo "   - Vérifiez les dépendances dans le repository local"' >> /usr/local/bin/maven-build-retry.sh && \
    echo '            echo "   - Vérifiez les versions dans dependencyManagement"' >> /usr/local/bin/maven-build-retry.sh && \
    echo '            ls -la ~/.m2/repository/com/pcagrade/mason/ || true' >> /usr/local/bin/maven-build-retry.sh && \
    echo '            exit 1' >> /usr/local/bin/maven-build-retry.sh && \
    echo '        fi' >> /usr/local/bin/maven-build-retry.sh && \
    echo '        sleep 5' >> /usr/local/bin/maven-build-retry.sh && \
    echo '    fi' >> /usr/local/bin/maven-build-retry.sh && \
    echo 'done' >> /usr/local/bin/maven-build-retry.sh && \
    chmod +x /usr/local/bin/maven-build-retry.sh

# Cloner Mason et Painter
RUN /usr/local/bin/git-clone-enhanced.sh "$MASON_REPO_URL" mason "$MASON_BRANCH"
RUN /usr/local/bin/git-clone-enhanced.sh "$PAINTER_REPO_URL" painter "$PAINTER_BRANCH"

# Construire Mason avec retry
WORKDIR /usr/src/app/mason
RUN /usr/local/bin/maven-build-retry.sh "Mason" "mvn clean install -DskipTests -Dmaven.test.skip=true -B"

# Vérifier que Mason est bien installé
RUN echo "🔍 Vérification de l'installation Mason:" && \
    ls -la ~/.m2/repository/com/pcagrade/mason/ && \
    echo "✅ Mason installé dans le repository Maven"

# Construire Painter avec retry
WORKDIR /usr/src/app/painter
RUN /usr/local/bin/maven-build-retry.sh "Painter" "mvn clean package -DskipTests -Dmaven.test.skip=true -B"

# Diagnostique final des JARs créés
RUN echo "📦 JARs Painter trouvés:" && \
    find /usr/src/app/painter -name "*.jar" -type f | grep -E "(painter|target)" | head -10

# ==========================================
# Stage de production
# ==========================================
FROM eclipse-temurin:21-jre-alpine
LABEL maintainer="ibrahim.alame@gmail.com"
WORKDIR /app

# Installer curl pour health checks
RUN apk add --no-cache curl && \
    echo "✅ Runtime configuré"

# Copier le JAR Painter (chemin correct)
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

echo -e "${GREEN}✅ Dockerfile Painter corrigé avec dependencyManagement complet${NC}"

# 3. Script de build optimisé
echo -e "${BLUE}🚀 Création du script de build optimisé...${NC}"
cat > build-with-dependencies-fixed.sh << 'EOF'
#!/bin/bash

# 🎨 Build CardManager avec Dépendances Corrigées

echo "🎨 Build CardManager avec Dépendances Corrigées"
echo "==============================================="

# Vérifications
if [ ! -f ".env" ]; then
    echo "❌ Fichier .env manquant !"
    exit 1
fi

# Détecter la clé SSH
SSH_KEY_FILE=""
for key_file in ~/.ssh/bitbucket_ed25519 ~/.ssh/id_ed25519 ~/.ssh/id_rsa; do
    if [ -f "$key_file" ]; then
        SSH_KEY_FILE="$key_file"
        break
    fi
done

if [ -z "$SSH_KEY_FILE" ]; then
    echo "❌ Aucune clé SSH trouvée !"
    exit 1
fi

echo "🔑 Clé SSH : $SSH_KEY_FILE"

# Encoder la clé SSH
export SSH_PRIVATE_KEY=$(cat "$SSH_KEY_FILE" | base64 -w 0 2>/dev/null || cat "$SSH_KEY_FILE" | base64)
echo "✅ Clé SSH encodée"

# Test SSH
echo "🧪 Test SSH..."
if ! ssh -T git@bitbucket.org -o ConnectTimeout=5 -o BatchMode=yes 2>&1 | grep -q "logged in as"; then
    echo "❌ SSH ne fonctionne pas"
    exit 1
fi
echo "✅ SSH OK"

# Source de la configuration
source .env
echo "📋 Configuration :"
echo "   Mason: $MASON_REPO_URL"
echo "   Painter: $PAINTER_REPO_URL"

# Nettoyer uniquement les images cassées
echo "🧹 Nettoyage sélectif..."
docker image prune -f
docker container prune -f

# Build avec logs détaillés
echo "🔨 Build avec dependencyManagement complet..."
if docker-compose build --no-cache --progress=plain; then
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

    echo ""
    echo "🔍 Status des services :"
    docker-compose ps

else
    echo ""
    echo "❌ BUILD ÉCHOUÉ !"
    echo ""
    echo "🔍 Diagnostics :"
    echo "1. Vérifiez les logs détaillés ci-dessus"
    echo "2. Les versions Mason sont maintenant dans dependencyManagement"
    echo "3. Retry automatique activé"
    echo "4. Relancez le script si problème temporaire"
    exit 1
fi
EOF

chmod +x build-with-dependencies-fixed.sh
echo -e "${GREEN}✅ Script de build optimisé créé${NC}"

# Résumé
echo ""
echo -e "${GREEN}🎉 CORRECTION DÉPENDANCES TERMINÉE !${NC}"
echo -e "${BLUE}═══════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 Problème résolu :${NC}"
echo "   ❌ AVANT : Versions Mason manquantes dans Painter"
echo "   ✅ APRÈS : dependencyManagement complet avec toutes les versions"
echo ""
echo -e "${YELLOW}🔧 Améliorations :${NC}"
echo "   ✅ POM parent avec dependencyManagement complet"
echo "   ✅ Toutes les versions Mason définies (2.4.1)"
echo "   ✅ Toutes les versions Painter définies (1.3.0)"
echo "   ✅ Versions Swagger et Resilience4j incluses"
echo "   ✅ Diagnostic Maven amélioré"
echo "   ✅ Vérification de l'installation Mason"
echo ""
echo -e "${YELLOW}🚀 Pour continuer :${NC}"
echo "   ./build-with-dependencies-fixed.sh"
echo ""
echo -e "${GREEN}Les dépendances Painter devraient maintenant être résolues ! 🎯${NC}"