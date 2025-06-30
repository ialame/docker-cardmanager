#!/bin/bash

echo "🔑 Configuration SSH pour Docker"
echo "================================"

# 1. Vérifier que les clés SSH existent
echo "🔍 Vérification des clés SSH..."

SSH_KEY_PATH="$HOME/.ssh/bitbucket_ed25519"
SSH_PUB_PATH="$HOME/.ssh/bitbucket_ed25519.pub"

if [ -f "$SSH_KEY_PATH" ]; then
    echo "✅ Clé SSH ED25519 Bitbucket trouvée : $SSH_KEY_PATH"

    # Vérifier les permissions
    perms=$(stat -f "%OLp" "$SSH_KEY_PATH" 2>/dev/null || stat -c "%a" "$SSH_KEY_PATH" 2>/dev/null)
    if [ "$perms" = "600" ]; then
        echo "✅ Permissions correctes (600)"
    else
        echo "⚠️ Permissions incorrectes ($perms), correction..."
        chmod 600 "$SSH_KEY_PATH"
    fi
else
    echo "❌ Clé SSH non trouvée à $SSH_KEY_PATH"
    echo "💡 Générez une clé SSH :"
    echo "   ssh-keygen -t rsa -b 4096 -C 'votre-email@exemple.com'"
    exit 1
fi

# 2. Test de connexion SSH à Bitbucket
echo ""
echo "🧪 Test de connexion SSH à Bitbucket..."
if ssh -i "$SSH_KEY_PATH" -T git@bitbucket.org -o ConnectTimeout=10 2>&1 | grep -q "authenticated via ssh key\|logged in as"; then
    echo "✅ Connexion SSH à Bitbucket réussie"
else
    echo "❌ Connexion SSH à Bitbucket échouée"
    echo "💡 Vérifiez que votre clé publique ED25519 est ajoutée à Bitbucket :"
    echo "   https://bitbucket.org/account/settings/ssh-keys/"
    echo ""
    echo "📋 Votre clé publique ED25519 :"
    if [ -f "$SSH_PUB_PATH" ]; then
        cat "$SSH_PUB_PATH"
    else
        echo "❌ Clé publique non trouvée"
    fi
    exit 1
fi

# 3. Préparer la clé SSH pour Docker
echo ""
echo "🔧 Préparation de la clé SSH pour Docker..."

# Lire la clé privée et l'encoder pour Docker
SSH_PRIVATE_KEY=$(cat "$SSH_KEY_PATH" | base64 | tr -d '\n')

# Mettre à jour le fichier .env
if [ -f ".env" ]; then
    echo "📝 Mise à jour du fichier .env..."

    # Supprimer l'ancienne ligne SSH_PRIVATE_KEY si elle existe
    grep -v "^SSH_PRIVATE_KEY=" .env > .env.tmp && mv .env.tmp .env

    # Ajouter la nouvelle clé SSH
    echo "SSH_PRIVATE_KEY=$SSH_PRIVATE_KEY" >> .env

    echo "✅ Clé SSH ajoutée au fichier .env"
else
    echo "❌ Fichier .env non trouvé"
    exit 1
fi

# 4. Vérifier la configuration actuelle
echo ""
echo "📋 Configuration Git actuelle :"
grep -E "^(MASON_REPO_URL|PAINTER_REPO_URL|GESTIONCARTE_REPO_URL)" .env

echo ""
echo "📋 Branches configurées :"
grep -E "^(MASON_BRANCH|PAINTER_BRANCH|GESTIONCARTE_BRANCH)" .env

# 5. Test d'accès aux repositories avec SSH
echo ""
echo "🧪 Test d'accès aux repositories..."

test_ssh_repo() {
    local repo_url="$1"
    local repo_name="$2"

    if [ -z "$repo_url" ]; then
        echo "⚠️ $repo_name : URL non configurée"
        return
    fi

    echo -n "📋 Test $repo_name ($repo_url)... "
    if git ls-remote --heads "$repo_url" >/dev/null 2>&1; then
        echo "✅ Accès OK"
    else
        echo "❌ Accès échoué"
    fi
}

source .env

test_ssh_repo "$MASON_REPO_URL" "Mason"
test_ssh_repo "$PAINTER_REPO_URL" "Painter"
test_ssh_repo "$GESTIONCARTE_REPO_URL" "GestionCarte"

# 6. Créer un docker-compose.yml optimisé pour SSH
echo ""
echo "🐳 Mise à jour du docker-compose.yml pour SSH..."

# Sauvegarder l'actuel
cp docker-compose.yml docker-compose.yml.backup-ssh-$(date +%s)

# Mettre à jour pour passer la clé SSH
sed -i.tmp \
    -e '/args:/,/GIT_TOKEN:/s/GIT_TOKEN: \${GIT_TOKEN}/GIT_TOKEN: ${GIT_TOKEN}\n        SSH_PRIVATE_KEY: ${SSH_PRIVATE_KEY}/' \
    docker-compose.yml

rm -f docker-compose.yml.tmp

echo "✅ docker-compose.yml mis à jour"

# 7. Créer un Dockerfile Painter optimisé pour SSH
echo ""
echo "🎨 Mise à jour du Dockerfile Painter pour SSH..."

cat > docker/painter/Dockerfile << 'DOCKERFILE_EOF'
# 🎨 Dockerfile pour le service Painter - Version SSH
FROM maven:3.9.6-eclipse-temurin-21 AS builder

# Variables d'environnement
ARG MASON_REPO_URL
ARG PAINTER_REPO_URL
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_BRANCH=feature/card-manager-511

ARG GIT_TOKEN
ARG SSH_PRIVATE_KEY

# Installation des outils nécessaires
RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    curl \
    && rm -rf /var/lib/apt/lists/*


# Configuration SSH
RUN mkdir -p /root/.ssh && \
    echo "${SSH_PRIVATE_KEY}" | base64 -d > /root/.ssh/bitbucket_ed25519 && \
    chmod 600 /root/.ssh/bitbucket_ed25519 && \
    ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

# Répertoire de travail
WORKDIR /usr/src/app

# Clonage des repositories avec SSH
RUN echo "🔄 Clonage de Mason..." && \
    git clone --depth 1 -b ${MASON_BRANCH} ${MASON_REPO_URL} mason

RUN echo "🎨 Clonage de Painter..." && \
    git clone --depth 1 -b ${PAINTER_BRANCH} ${PAINTER_REPO_URL} painter

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

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:8081/actuator/health || exit 1

# Commande de démarrage
ENTRYPOINT ["java", "-Xmx512m", "-Xms256m", "-XX:+UseG1GC", "-Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}", "-jar", "/app/app.jar"]
DOCKERFILE_EOF

echo "✅ Dockerfile Painter mis à jour pour SSH"

echo ""
echo "🚀 Configuration SSH terminée !"
echo "==============================="
echo "✅ Clé SSH configurée pour Docker"
echo "✅ docker-compose.yml mis à jour"
echo "✅ Dockerfile Painter optimisé pour SSH"
echo ""
echo "🎯 Prochaines étapes :"
echo "   docker-compose build painter --no-cache"
echo "   docker-compose up -d"
echo ""
echo "📋 Si le build échoue :"
echo "   - Vérifiez que votre clé SSH est ajoutée à Bitbucket"
echo "   - Vérifiez les logs : docker-compose logs painter"