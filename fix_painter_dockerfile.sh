#!/bin/bash

echo "🎨 Correction du Dockerfile Painter"
echo "==================================="

# 1. Vérifier les logs du build pour comprendre où est le JAR
echo "🔍 Analyse des logs de build précédents..."
if [ -f "tototo.txt" ]; then
    echo "📋 Logs trouvés dans tototo.txt"
    echo "Recherche de la structure du build..."
    grep -A 5 -B 5 "Building Painter" tototo.txt || echo "Logs Painter non trouvés"
else
    echo "📋 Pas de logs précédents trouvés"
fi

# 2. Sauvegarde du Dockerfile actuel
echo ""
echo "💾 Sauvegarde du Dockerfile actuel..."
if [ -f "docker/painter/Dockerfile" ]; then
    cp docker/painter/Dockerfile docker/painter/Dockerfile.backup-$(date +%Y%m%d_%H%M%S)
    echo "✅ Dockerfile sauvegardé"
else
    echo "❌ Dockerfile Painter non trouvé"
    exit 1
fi

# 3. Diagnostic de la ligne problématique
echo ""
echo "🐛 Ligne problématique identifiée :"
grep -n "COPY.*||" docker/painter/Dockerfile || echo "Ligne avec || non trouvée"

# 4. Correction du Dockerfile
echo ""
echo "🔧 Correction du Dockerfile Painter..."

# Créer un nouveau Dockerfile corrigé
cat > docker/painter/Dockerfile << 'DOCKERFILE_EOF'
# 🎨 Dockerfile pour le service Painter
FROM maven:3.9.6-openjdk-21-slim AS builder

# Variables d'environnement
ARG MASON_REPO_URL
ARG PAINTER_REPO_URL
ARG MASON_BRANCH=main
ARG PAINTER_BRANCH=main
ARG GIT_TOKEN
ARG SSH_PRIVATE_KEY

# Installation des outils nécessaires
RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configuration Git
RUN git config --global user.name "Docker Builder" && \
    git config --global user.email "builder@docker.com"

# Configuration SSH si clé fournie
RUN if [ -n "${SSH_PRIVATE_KEY}" ]; then \
        mkdir -p /root/.ssh && \
        echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa && \
        chmod 600 /root/.ssh/id_rsa && \
        ssh-keyscan github.com >> /root/.ssh/known_hosts; \
    fi

# Répertoire de travail
WORKDIR /usr/src/app

# Clonage des repositories
RUN echo "🔄 Clonage de Mason..." && \
    if [ -n "${GIT_TOKEN}" ]; then \
        MASON_URL_WITH_TOKEN=$(echo ${MASON_REPO_URL} | sed "s|https://|https://${GIT_TOKEN}@|"); \
        git clone --depth 1 -b ${MASON_BRANCH} ${MASON_URL_WITH_TOKEN} mason; \
    else \
        git clone --depth 1 -b ${MASON_BRANCH} ${MASON_REPO_URL} mason; \
    fi

RUN echo "🎨 Clonage de Painter..." && \
    if [ -n "${GIT_TOKEN}" ]; then \
        PAINTER_URL_WITH_TOKEN=$(echo ${PAINTER_REPO_URL} | sed "s|https://|https://${GIT_TOKEN}@|"); \
        git clone --depth 1 -b ${PAINTER_BRANCH} ${PAINTER_URL_WITH_TOKEN} painter; \
    else \
        git clone --depth 1 -b ${PAINTER_BRANCH} ${PAINTER_REPO_URL} painter; \
    fi

# Build Mason en premier
RUN echo "🔨 Build de Mason..." && \
    cd mason && \
    mvn clean install -DskipTests -q

# Build Painter
RUN echo "🎨 Build de Painter..." && \
    cd painter && \
    mvn clean package -DskipTests -q

# Vérification des JARs construits
RUN echo "🔍 Vérification des JARs construits:" && \
    find /usr/src/app -name "*.jar" -type f | grep -v ".m2" | head -10

# Image finale
FROM openjdk:21-jre-slim

# Métadonnées
LABEL maintainer="ibrahim.alame@gmail.com"
LABEL description="Service Painter pour CardManager"

# Variables d'environnement
ENV SPRING_PROFILES_ACTIVE=docker
ENV SPRING_CONFIG_LOCATION=classpath:/application.properties,classpath:/application-docker.properties

# Création du répertoire applicatif
RUN mkdir -p /app/images
WORKDIR /app

# Installation des outils pour health check
RUN apt-get update && apt-get install -y \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copie du JAR - Utilisation de plusieurs tentatives avec RUN
RUN echo "🔍 Recherche du JAR Painter..."

# Tentative 1 : structure standard painter/target/
COPY --from=builder /usr/src/app/painter/target/painter-*.jar app.jar 2>/dev/null || echo "Tentative 1 échouée"

# Tentative 2 : structure avec sous-dossier painter/painter/target/
RUN if [ ! -f app.jar ]; then \
        echo "🔍 Tentative 2: sous-dossier painter/painter/target/"; \
    fi
COPY --from=builder /usr/src/app/painter/painter/target/painter-*.jar app.jar 2>/dev/null || echo "Tentative 2 échouée"

# Tentative 3 : recherche dans tous les sous-dossiers
RUN if [ ! -f app.jar ]; then \
        echo "🔍 Tentative 3: recherche dans tous les sous-dossiers"; \
        find /usr/src/app/painter -name "painter-*.jar" -type f | head -1 | xargs -I {} cp {} app.jar 2>/dev/null || echo "Tentative 3 échouée"; \
    fi

# Vérification finale
RUN if [ ! -f app.jar ]; then \
        echo "❌ ERREUR: Aucun JAR Painter trouvé !"; \
        echo "📋 Structure trouvée:"; \
        find /usr/src/app/painter -name "*.jar" -type f 2>/dev/null || echo "Aucun JAR trouvé"; \
        exit 1; \
    else \
        echo "✅ JAR Painter trouvé: $(ls -la app.jar)"; \
    fi

# Configuration des volumes
VOLUME ["/app/images"]

# Port d'exposition
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# Commande de démarrage
ENTRYPOINT ["java", "-Xmx512m", "-Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}", "-jar", "/app/app.jar"]
DOCKERFILE_EOF

echo "✅ Nouveau Dockerfile Painter créé"

# 5. Vérification du nouveau Dockerfile
echo ""
echo "📋 Vérification du nouveau Dockerfile:"
echo "Lignes COPY identifiées:"
grep -n "COPY\|RUN.*cp" docker/painter/Dockerfile | head -5

echo ""
echo "🚀 Le Dockerfile Painter est maintenant corrigé !"
echo ""
echo "💡 Ce qui a été corrigé :"
echo "   ❌ AVANT: COPY avec syntaxe || (invalide)"
echo "   ✅ APRÈS: Tentatives multiples avec gestion d'erreur"
echo ""
echo "🎯 Vous pouvez maintenant relancer :"
echo "   docker-compose up -d"
echo ""
echo "📊 Pour surveiller le build :"
echo "   docker-compose logs -f painter"