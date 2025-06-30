#!/bin/bash

echo "☕ Correction des Images Java Docker"
echo "===================================="

echo "🔍 Problème identifié : openjdk:21-jre-slim n'existe plus"
echo "💡 Solution : Utiliser eclipse-temurin ou amazoncorretto"

# Fonction pour corriger un Dockerfile
fix_dockerfile() {
    local dockerfile_path="$1"
    local service_name="$2"

    if [ -f "$dockerfile_path" ]; then
        echo "🔧 Correction de $dockerfile_path..."

        # Sauvegarde
        cp "$dockerfile_path" "${dockerfile_path}.backup-$(date +%s)"

        # Remplacement des images Java obsolètes
        sed -i.tmp \
            -e 's|FROM openjdk:21-jre-slim|FROM eclipse-temurin:21-jre|g' \
            -e 's|FROM openjdk:21-slim|FROM eclipse-temurin:21-jdk|g' \
            -e 's|FROM openjdk:17-jre-slim|FROM eclipse-temurin:17-jre|g' \
            -e 's|FROM openjdk:17-slim|FROM eclipse-temurin:17-jdk|g' \
            "$dockerfile_path"

        # Supprimer le fichier temporaire
        rm -f "${dockerfile_path}.tmp"

        echo "✅ $service_name Dockerfile corrigé"

        # Afficher les changements
        echo "📋 Images Java modifiées dans $service_name :"
        grep -n "FROM.*temurin" "$dockerfile_path" || echo "   Aucune image Java trouvée"
    else
        echo "⚠️ $dockerfile_path non trouvé"
    fi
}

# Correction de tous les Dockerfiles
echo ""
echo "🔧 Correction des Dockerfiles..."

fix_dockerfile "docker/mason/Dockerfile" "Mason"
fix_dockerfile "docker/painter/Dockerfile" "Painter"
fix_dockerfile "docker/gestioncarte/Dockerfile" "GestionCarte"

# Vérification des images disponibles
echo ""
echo "🔍 Vérification des images Java disponibles..."

# Test de disponibilité des nouvelles images
echo "📋 Test d'accès aux images de remplacement :"

images_to_test=(
    "eclipse-temurin:21-jre"
    "eclipse-temurin:21-jdk"
    "maven:3.9.6-eclipse-temurin-21"
)

for image in "${images_to_test[@]}"; do
    echo -n "   Testing $image... "
    if docker pull "$image" >/dev/null 2>&1; then
        echo "✅ Available"
    else
        echo "❌ Not available"
    fi
done

echo ""
echo "🔧 Mise à jour des images Maven si nécessaire..."

# Correction des images Maven obsolètes
for dockerfile in docker/*/Dockerfile; do
    if [ -f "$dockerfile" ]; then
        sed -i.tmp \
            -e 's|FROM maven:3.9.6-openjdk-21-slim|FROM maven:3.9.6-eclipse-temurin-21|g' \
            -e 's|FROM maven:.*-openjdk-21-slim|FROM maven:3.9.6-eclipse-temurin-21|g' \
            "$dockerfile"
        rm -f "${dockerfile}.tmp"
    fi
done

echo "✅ Images Maven mises à jour"

# Créer un Dockerfile de test pour painter corrigé
echo ""
echo "🎨 Création d'un Dockerfile Painter corrigé..."

cat > docker/painter/Dockerfile << 'DOCKERFILE_EOF'
# 🎨 Dockerfile pour le service Painter - Version corrigée
FROM maven:3.9.6-eclipse-temurin-21 AS builder

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
RUN echo "🔍 Localisation des JARs construits:" && \
    find /usr/src/app -name "painter*.jar" -type f | head -10

# Image finale avec Eclipse Temurin
FROM eclipse-temurin:21-jre

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
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copie du JAR avec gestion d'erreur robuste
COPY --from=builder /usr/src/app/painter/target/painter*.jar ./app.jar

# Vérification que le JAR existe
RUN if [ ! -f app.jar ]; then \
        echo "❌ JAR Painter non trouvé !"; \
        echo "📁 Contenu du répertoire :"; \
        ls -la /app/; \
        echo "🔍 Recherche dans tout le système :"; \
        find /usr/src/app -name "*.jar" -type f 2>/dev/null | head -10; \
        exit 1; \
    else \
        echo "✅ JAR Painter trouvé : $(ls -la app.jar)"; \
    fi

# Configuration des volumes
VOLUME ["/app/images"]

# Port d'exposition
EXPOSE 8081

# Health check optimisé
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:8081/actuator/health || exit 1

# Commande de démarrage avec optimisations mémoire
ENTRYPOINT ["java", "-Xmx512m", "-Xms256m", "-XX:+UseG1GC", "-Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}", "-jar", "/app/app.jar"]
DOCKERFILE_EOF

echo "✅ Nouveau Dockerfile Painter créé avec eclipse-temurin"

echo ""
echo "🚀 Corrections appliquées !"
echo "========================================="
echo "✅ Images Java mises à jour vers eclipse-temurin"
echo "✅ Images Maven mises à jour"
echo "✅ Dockerfile Painter entièrement réécrit"
echo ""
echo "🎯 Commandes pour tester :"
echo "   docker-compose build painter"
echo "   docker-compose up -d"
echo ""
echo "📋 Si le build échoue encore :"
echo "   docker-compose build --progress=plain painter"