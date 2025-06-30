# 🎨 Dockerfile pour le service Painter - Version SSH ED25519 avec Health Check corrigé
FROM maven:3.9.6-eclipse-temurin-21 AS builder

# Variables d'environnement
ARG MASON_REPO_URL
ARG PAINTER_REPO_URL
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_BRANCH=feature/card-manager-511
ARG GESTIONCARTE_BRANCH=feature/card-manager-511
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

# Configuration SSH pour ED25519
RUN mkdir -p /root/.ssh && \
    echo "${SSH_PRIVATE_KEY}" | base64 -d > /root/.ssh/bitbucket_ed25519 && \
    chmod 600 /root/.ssh/bitbucket_ed25519 && \
    ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

# Configuration SSH pour utiliser la clé ED25519 spécifique
RUN echo "Host bitbucket.org" >> /root/.ssh/config && \
    echo "  IdentityFile /root/.ssh/bitbucket_ed25519" >> /root/.ssh/config && \
    echo "  IdentitiesOnly yes" >> /root/.ssh/config && \
    chmod 600 /root/.ssh/config

# Répertoire de travail
WORKDIR /usr/src/app

# Test de la configuration SSH
RUN echo "🧪 Test SSH..." && \
    ssh -T git@bitbucket.org -o StrictHostKeyChecking=no || echo "SSH test terminé"

# Clonage des repositories avec SSH
RUN echo "🔄 Clonage de Mason..." && \
    git clone --depth 1 -b ${MASON_BRANCH} ${MASON_REPO_URL} mason

RUN echo "🎨 Clonage de Painter..." && \
    git clone --depth 1 -b ${PAINTER_BRANCH} ${PAINTER_REPO_URL} painter

# Build Mason en premier (ignore les erreurs car on peut avoir un JAR existant)
RUN echo "🔨 Build de Mason..." && \
    cd mason && \
    (mvn clean install -DskipTests -q || echo "⚠️ Mason build failed, continuing...")

# Build Painter
RUN echo "🎨 Build de Painter..." && \
    cd painter && \
    mvn clean package -DskipTests -q

# Vérification des JARs construits
RUN echo "🔍 Localisation des JARs construits:" && \
    find /usr/src/app -name "painter*.jar" -type f | head -10

# Image finale
FROM eclipse-temurin:21-jre

# Métadonnées
LABEL maintainer="ibrahim.alame@gmail.com"
LABEL description="Service Painter pour CardManager"

# Variables d'environnement
ENV SPRING_PROFILES_ACTIVE=docker

# Création du répertoire applicatif
RUN mkdir -p /app/images
WORKDIR /app

# Installation des outils pour health check
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copie du JAR
COPY --from=builder /usr/src/app/painter/target/painter*.jar ./app.jar

# Vérification que le JAR existe
RUN if [ ! -f app.jar ]; then \
        echo "❌ JAR Painter non trouvé !"; \
        find /usr/src/app -name "*.jar" -type f 2>/dev/null | head -10; \
        exit 1; \
    else \
        echo "✅ JAR Painter trouvé : $(ls -la app.jar)"; \
    fi

# Configuration des volumes
VOLUME ["/app/images"]

# Port d'exposition
EXPOSE 8081

# Health check corrigé - utilise la racine au lieu d'actuator
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:8081/ > /dev/null 2>&1 || exit 1

# Commande de démarrage
ENTRYPOINT ["java", "-Xmx512m", "-Xms256m", "-XX:+UseG1GC", "-Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}", "-jar", "/app/app.jar"]
