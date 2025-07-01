#!/bin/bash

echo "🔧 APPROCHE ECHO : PAS DE HEREDOC XML"
echo "====================================="

# Définir les couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔹 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_step "1. Arrêt des conteneurs existants"
docker-compose down --remove-orphans
print_success "Conteneurs arrêtés"

print_step "2. Création du Dockerfile Painter avec ECHO (pas de heredoc)"
cat > docker/painter/Dockerfile << 'EOF'
# =============================================================================
# Dockerfile Painter - APPROCHE ECHO (évite les problèmes XML)
# =============================================================================

FROM maven:3.9.6-eclipse-temurin-21 AS builder
LABEL maintainer="ibrahim.alame@gmail.com"

# Arguments de build
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_BRANCH=feature/card-manager-511
ARG SSH_PRIVATE_KEY

# Installer Git et SSH
RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configuration Git
RUN git config --global user.name "Docker Builder" && \
    git config --global user.email "builder@docker.com"

# Configuration SSH pour Bitbucket
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    ssh-keyscan -H bitbucket.org >> /root/.ssh/known_hosts

# Configurer la clé SSH privée
RUN if [ ! -z "$SSH_PRIVATE_KEY" ]; then \
        echo "$SSH_PRIVATE_KEY" | base64 -d > /root/.ssh/bitbucket_ed25519 && \
        chmod 600 /root/.ssh/bitbucket_ed25519 && \
        echo "Host bitbucket.org" >> /root/.ssh/config && \
        echo "  IdentityFile /root/.ssh/bitbucket_ed25519" >> /root/.ssh/config && \
        echo "  IdentitiesOnly yes" >> /root/.ssh/config; \
    fi

# Répertoire de travail
WORKDIR /usr/src/app

# Test SSH
RUN ssh -T git@bitbucket.org -o StrictHostKeyChecking=no || echo "SSH test terminé"

# ===================================================================
# STRATÉGIE DIRECTE : Mason → Painter (sans structure complexe)
# ===================================================================

# Cloner et construire Mason
RUN echo "🔨 Clonage et build de Mason..." && \
    git clone --depth 1 -b feature/RETRIEVER-511 git@bitbucket.org:pcafxc/mason.git mason && \
    cd mason && \
    mvn clean install -DskipTests -Dmaven.test.skip=true -B -q

# Cloner Painter
RUN echo "🎨 Clonage de Painter..." && \
    git clone --depth 1 -b feature/card-manager-511 git@bitbucket.org:pcafxc/painter.git painter

# Aller dans le répertoire painter/painter (module principal)
WORKDIR /usr/src/app/painter/painter

# Sauvegarder le POM original
RUN cp pom.xml pom.xml.original

# Créer un POM autonome avec echo (évite les heredoc)
RUN echo '<?xml version="1.0" encoding="UTF-8"?>' > pom.xml
RUN echo '<project xmlns="http://maven.apache.org/POM/4.0.0"' >> pom.xml
RUN echo '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' >> pom.xml
RUN echo '         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">' >> pom.xml
RUN echo '    <modelVersion>4.0.0</modelVersion>' >> pom.xml
RUN echo '    <groupId>com.pcagrade.painter</groupId>' >> pom.xml
RUN echo '    <artifactId>painter</artifactId>' >> pom.xml
RUN echo '    <version>1.3.0</version>' >> pom.xml
RUN echo '    <packaging>jar</packaging>' >> pom.xml
RUN echo '    <name>Painter</name>' >> pom.xml
RUN echo '    <description>Application for managing images</description>' >> pom.xml
RUN echo '    <properties>' >> pom.xml
RUN echo '        <maven.compiler.source>21</maven.compiler.source>' >> pom.xml
RUN echo '        <maven.compiler.target>21</maven.compiler.target>' >> pom.xml
RUN echo '        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>' >> pom.xml
RUN echo '        <spring-boot.version>3.2.5</spring-boot.version>' >> pom.xml
RUN echo '        <mason.version>2.4.1</mason.version>' >> pom.xml
RUN echo '        <mapstruct.version>1.5.5.Final</mapstruct.version>' >> pom.xml
RUN echo '        <resilience4j.version>2.2.0</resilience4j.version>' >> pom.xml
RUN echo '    </properties>' >> pom.xml
RUN echo '    <dependencyManagement>' >> pom.xml
RUN echo '        <dependencies>' >> pom.xml
RUN echo '            <dependency>' >> pom.xml
RUN echo '                <groupId>org.springframework.boot</groupId>' >> pom.xml
RUN echo '                <artifactId>spring-boot-dependencies</artifactId>' >> pom.xml
RUN echo '                <version>${spring-boot.version}</version>' >> pom.xml
RUN echo '                <type>pom</type>' >> pom.xml
RUN echo '                <scope>import</scope>' >> pom.xml
RUN echo '            </dependency>' >> pom.xml
RUN echo '        </dependencies>' >> pom.xml
RUN echo '    </dependencyManagement>' >> pom.xml
RUN echo '    <dependencies>' >> pom.xml
RUN echo '        <!-- Mason Dependencies -->' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml
RUN echo '            <artifactId>mason-commons</artifactId>' >> pom.xml
RUN echo '            <version>${mason.version}</version>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml
RUN echo '            <artifactId>mason-jpa</artifactId>' >> pom.xml
RUN echo '            <version>${mason.version}</version>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml
RUN echo '            <artifactId>mason-jpa-cache</artifactId>' >> pom.xml
RUN echo '            <version>${mason.version}</version>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml
RUN echo '            <artifactId>mason-kubernetes</artifactId>' >> pom.xml
RUN echo '            <version>${mason.version}</version>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <!-- Spring Boot Dependencies -->' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>org.springframework.data</groupId>' >> pom.xml
RUN echo '            <artifactId>spring-data-envers</artifactId>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>org.springframework.boot</groupId>' >> pom.xml
RUN echo '            <artifactId>spring-boot-starter-webflux</artifactId>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>org.springframework.boot</groupId>' >> pom.xml
RUN echo '            <artifactId>spring-boot-starter-web</artifactId>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>org.springframework.boot</groupId>' >> pom.xml
RUN echo '            <artifactId>spring-boot-starter-data-jpa</artifactId>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <!-- Resilience4j -->' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>io.github.resilience4j</groupId>' >> pom.xml
RUN echo '            <artifactId>resilience4j-timelimiter</artifactId>' >> pom.xml
RUN echo '            <version>${resilience4j.version}</version>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <!-- MapStruct -->' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>org.mapstruct</groupId>' >> pom.xml
RUN echo '            <artifactId>mapstruct</artifactId>' >> pom.xml
RUN echo '            <version>${mapstruct.version}</version>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>org.mapstruct</groupId>' >> pom.xml
RUN echo '            <artifactId>mapstruct-processor</artifactId>' >> pom.xml
RUN echo '            <version>${mapstruct.version}</version>' >> pom.xml
RUN echo '            <scope>provided</scope>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <!-- VectorGraphics2D -->' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>de.erichseifert.vectorgraphics2d</groupId>' >> pom.xml
RUN echo '            <artifactId>VectorGraphics2D</artifactId>' >> pom.xml
RUN echo '            <version>0.13</version>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <!-- MariaDB -->' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>org.mariadb.jdbc</groupId>' >> pom.xml
RUN echo '            <artifactId>mariadb-java-client</artifactId>' >> pom.xml
RUN echo '            <version>3.3.3</version>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <!-- Liquibase -->' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>org.liquibase</groupId>' >> pom.xml
RUN echo '            <artifactId>liquibase-core</artifactId>' >> pom.xml
RUN echo '            <version>4.27.0</version>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <!-- Test Dependencies -->' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>com.h2database</groupId>' >> pom.xml
RUN echo '            <artifactId>h2</artifactId>' >> pom.xml
RUN echo '            <scope>test</scope>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '        <dependency>' >> pom.xml
RUN echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml
RUN echo '            <artifactId>mason-test</artifactId>' >> pom.xml
RUN echo '            <version>${mason.version}</version>' >> pom.xml
RUN echo '            <scope>test</scope>' >> pom.xml
RUN echo '        </dependency>' >> pom.xml
RUN echo '    </dependencies>' >> pom.xml
RUN echo '    <build>' >> pom.xml
RUN echo '        <plugins>' >> pom.xml
RUN echo '            <plugin>' >> pom.xml
RUN echo '                <groupId>org.springframework.boot</groupId>' >> pom.xml
RUN echo '                <artifactId>spring-boot-maven-plugin</artifactId>' >> pom.xml
RUN echo '                <version>${spring-boot.version}</version>' >> pom.xml
RUN echo '                <executions>' >> pom.xml
RUN echo '                    <execution>' >> pom.xml
RUN echo '                        <goals>' >> pom.xml
RUN echo '                            <goal>repackage</goal>' >> pom.xml
RUN echo '                        </goals>' >> pom.xml
RUN echo '                    </execution>' >> pom.xml
RUN echo '                </executions>' >> pom.xml
RUN echo '                <configuration>' >> pom.xml
RUN echo '                    <mainClass>com.pcagrade.painter.PainterApplication</mainClass>' >> pom.xml
RUN echo '                </configuration>' >> pom.xml
RUN echo '            </plugin>' >> pom.xml
RUN echo '            <plugin>' >> pom.xml
RUN echo '                <groupId>org.apache.maven.plugins</groupId>' >> pom.xml
RUN echo '                <artifactId>maven-compiler-plugin</artifactId>' >> pom.xml
RUN echo '                <version>3.11.0</version>' >> pom.xml
RUN echo '                <configuration>' >> pom.xml
RUN echo '                    <source>21</source>' >> pom.xml
RUN echo '                    <target>21</target>' >> pom.xml
RUN echo '                    <annotationProcessors>' >> pom.xml
RUN echo '                        <annotationProcessor>org.mapstruct.ap.MappingProcessor</annotationProcessor>' >> pom.xml
RUN echo '                    </annotationProcessors>' >> pom.xml
RUN echo '                </configuration>' >> pom.xml
RUN echo '            </plugin>' >> pom.xml
RUN echo '        </plugins>' >> pom.xml
RUN echo '    </build>' >> pom.xml
RUN echo '</project>' >> pom.xml

# Construire Painter avec le POM autonome
RUN echo "🎨 Build de Painter autonome..." && \
    mvn clean package -DskipTests -Dmaven.test.skip=true -B

# Vérifier le JAR final
RUN echo "📦 JAR Painter trouvé:" && \
    find . -name "*.jar" -type f | head -5

# =============================================================================
# Stage de production
# =============================================================================
FROM eclipse-temurin:21-jre-alpine
LABEL maintainer="ibrahim.alame@gmail.com"
WORKDIR /app

# Créer répertoire pour les images
RUN mkdir -p /app/images

# Installer curl pour health checks
RUN apk add --no-cache curl wget

# Copier le JAR Painter
COPY --from=builder /usr/src/app/painter/painter/target/painter-*.jar ./app.jar

# Port d'exposition
EXPOSE 8081

# Variables d'environnement
ENV SPRING_PROFILES_ACTIVE=docker
ENV SERVER_PORT=8081

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8081/ || exit 1

# Point d'entrée
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

print_success "Dockerfile Painter avec ECHO créé (pas de heredoc)"

print_step "3. Démarrage de la base de données"
docker-compose up -d mariadb
print_success "Base de données démarrée"

print_warning "Attente de 15 secondes pour l'initialisation..."
sleep 15

print_step "4. Construction de l'image Painter (avec echo)"
echo "📦 Stratégie ECHO :"
echo "   ✅ Aucun heredoc XML"
echo "   ✅ POM créé ligne par ligne avec echo"
echo "   ✅ Mason → Painter autonome"

docker-compose build --no-cache painter
if [ $? -eq 0 ]; then
    print_success "Image Painter construite avec succès !"
else
    print_error "Échec de la construction"
    print_warning "Affichage des logs pour diagnostic..."
    docker-compose logs painter 2>/dev/null | tail -30 || echo "Pas de logs disponibles"
    exit 1
fi

print_step "5. Démarrage de Painter"
docker-compose up -d painter
print_success "Painter démarré"

print_warning "Attente de 30 secondes pour le démarrage..."
sleep 30

print_step "6. Test de Painter"
if curl -f http://localhost:8081/ > /dev/null 2>&1; then
    print_success "Painter répond correctement !"
elif curl -f http://localhost:8081/actuator/health > /dev/null 2>&1; then
    print_success "Painter répond sur /actuator/health !"
else
    print_warning "Test de connectivité..."
    echo "Status HTTP de Painter :"
    curl -I http://localhost:8081/ 2>/dev/null || echo "Pas de réponse"
    echo ""
    echo "Logs Painter (dernières lignes) :"
    docker-compose logs painter | tail -20
fi

print_step "7. Construction et démarrage de GestionCarte"
docker-compose build --no-cache gestioncarte
docker-compose up -d

echo ""
echo "🎉 DÉPLOIEMENT TERMINÉ (APPROCHE ECHO) !"
echo "======================================="
echo ""
echo "📊 Services démarrés :"
docker-compose ps

echo ""
echo "🔗 URLs d'accès :"
echo "   💾 Base de données: localhost:3307"
echo "   🎨 Painter API:     http://localhost:8081/"
echo "   📋 GestionCarte:    http://localhost:8080/"

echo ""
print_success "Painter construit avec approche ECHO (pas de heredoc XML) !"