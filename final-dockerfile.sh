#!/bin/bash

# 🔧 Correction Finale du Dockerfile Painter

echo "🔧 Correction Finale du Dockerfile"
echo "================================="

echo ""
echo "✅ BUILD MAVEN RÉUSSI !"
echo "   Mason et Painter se sont compilés avec succès"
echo "   Il reste juste à corriger la commande COPY"
echo ""

# Sauvegarder le Dockerfile actuel
cp docker/painter/Dockerfile docker/painter/Dockerfile.broken
echo "💾 Dockerfile cassé sauvegardé"

echo ""
echo "🔧 Création d'un Dockerfile avec COPY simple..."

# Créer un nouveau Dockerfile avec la bonne syntaxe
cat > docker/painter/Dockerfile << 'EOF'
# 🎨 Dockerfile Painter - Version Finale Corrigée
FROM maven:3.9.6-eclipse-temurin-21 AS builder
WORKDIR /usr/src/app

# Installer git, ssh et curl
RUN apt-get update && \
    apt-get install -y git openssh-client curl && \
    rm -rf /var/lib/apt/lists/*

# Arguments pour Git
ARG MASON_REPO_URL
ARG PAINTER_REPO_URL
ARG MASON_BRANCH=main
ARG PAINTER_BRANCH=main
ARG GIT_TOKEN
ARG SSH_PRIVATE_KEY

# Configuration SSH pour Bitbucket
RUN mkdir -p ~/.ssh && \
    chmod 700 ~/.ssh && \
    ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts && \
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts

# Ajouter la clé SSH privée si fournie
RUN if [ ! -z "$SSH_PRIVATE_KEY" ]; then \
        echo "$SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa && \
        chmod 600 ~/.ssh/id_rsa && \
        echo "✅ SSH key configured"; \
    else \
        echo "⚠️ No SSH key provided"; \
    fi

# Configuration Git globale
RUN git config --global user.email "docker@cardmanager.local" && \
    git config --global user.name "Docker Builder" && \
    git config --global init.defaultBranch main

# Créer un POM parent COMPLET avec TOUTES les dépendances Mason
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
    echo '        <springdoc.version>2.2.0</springdoc.version>' >> pom.xml && \
    echo '        <resilience4j.version>2.1.0</resilience4j.version>' >> pom.xml && \
    echo '        <mapstruct.version>1.5.5.Final</mapstruct.version>' >> pom.xml && \
    echo '    </properties>' >> pom.xml && \
    echo '    <dependencyManagement>' >> pom.xml && \
    echo '        <dependencies>' >> pom.xml && \
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
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>org.springdoc</groupId>' >> pom.xml && \
    echo '                <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>' >> pom.xml && \
    echo '                <version>${springdoc.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
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
    echo '            <dependency>' >> pom.xml && \
    echo '                <groupId>org.mapstruct</groupId>' >> pom.xml && \
    echo '                <artifactId>mapstruct</artifactId>' >> pom.xml && \
    echo '                <version>${mapstruct.version}</version>' >> pom.xml && \
    echo '            </dependency>' >> pom.xml && \
    echo '        </dependencies>' >> pom.xml && \
    echo '    </dependencyManagement>' >> pom.xml && \
    echo '</project>' >> pom.xml

# Installer le POM parent
RUN mvn install -N

# Script de clonage intelligent SSH/HTTPS
RUN echo '#!/bin/bash' > /usr/local/bin/git-clone-enhanced.sh && \
    echo 'set -e' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'REPO_URL="$1"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'TARGET_DIR="$2"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'BRANCH="$3"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'TOKEN="$4"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'echo "=== Enhanced Git Clone ==="' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'echo "Repository: $REPO_URL"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'echo "Target: $TARGET_DIR"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'echo "Branch: $BRANCH"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'if [[ "$REPO_URL" == git@* ]]; then' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    echo "✅ SSH URL detected"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    if [ -f ~/.ssh/id_rsa ]; then' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '        echo "🔑 SSH key found"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo '    fi' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'fi' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"' >> /usr/local/bin/git-clone-enhanced.sh && \
    echo 'echo "✅ Successfully cloned $TARGET_DIR"' >> /usr/local/bin/git-clone-enhanced.sh && \
    chmod +x /usr/local/bin/git-clone-enhanced.sh

# Cloner les dépôts
RUN /usr/local/bin/git-clone-enhanced.sh "$MASON_REPO_URL" mason "$MASON_BRANCH" "$GIT_TOKEN"
RUN /usr/local/bin/git-clone-enhanced.sh "$PAINTER_REPO_URL" painter "$PAINTER_BRANCH" "$GIT_TOKEN"

# Build Mason d'abord
WORKDIR /usr/src/app/mason
RUN echo "🔨 Building Mason..." && \
    mvn clean install -DskipTests -q

# Build Painter
WORKDIR /usr/src/app/painter
RUN echo "🎨 Building Painter..." && \
    mvn clean package -DskipTests -q

# ✅ Trouver et lister tous les JARs créés pour diagnostic
RUN echo "📦 Finding all JARs created:" && \
    find /usr/src/app -name "*.jar" -type f | grep -E "(painter|target)" | head -10

# ========================================
# Image finale simplifiée
# ========================================
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Installer curl pour health checks
RUN apk add --no-cache curl

# ✅ Recherche intelligente du JAR Painter (méthode simplifiée)
RUN echo "📦 Copying Painter JAR..."
COPY --from=builder /usr/src/app/painter/painter/target/painter-*.jar ./app.jar

# Alternative si le JAR n'est pas trouvé à l'emplacement précédent
# COPY --from=builder /usr/src/app/painter/target/painter-*.jar ./app.jar

# Créer le répertoire d'images
RUN mkdir -p /app/images && \
    chmod 755 /app/images

# Variables d'environnement
ENV JAVA_OPTS="-Xmx1024m -Xms512m"
ENV PAINTER_IMAGE_STORAGE_PATH="/app/images"
ENV SPRING_PROFILES_ACTIVE=docker

# Port d'exposition
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Point d'entrée
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
EOF

echo "✅ Nouveau Dockerfile créé avec syntaxe correcte"

echo ""
echo "🔍 Différences principales :"
echo "   ❌ AVANT: COPY avec || (syntaxe invalide Docker)"
echo "   ✅ APRÈS: COPY simple et direct"
echo "   ✅ APRÈS: Diagnostic des JARs créés"
echo "   ✅ APRÈS: Script git-clone simplifié"

echo ""
echo "🚀 Lancez maintenant le build :"
echo "   ./build-with-ssh.sh"

echo ""
echo "💡 Si le JAR n'est pas trouvé, le script affichera tous les JARs"
echo "   créés pour qu'on puisse ajuster le chemin COPY"