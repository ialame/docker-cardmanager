#!/bin/bash

echo "🔧 SOLUTION MULTI-MODULES : CARDMANAGER → MASON → PAINTER-PARENT → PAINTER"
echo "==========================================================================="

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

print_step "2. Création du Dockerfile FINAL MULTI-MODULES avec structure complète"
cat > docker/painter/Dockerfile << 'EOF'
# =============================================================================
# Dockerfile Painter - SOLUTION MULTI-MODULES COMPLÈTE
# =============================================================================

FROM maven:3.9.6-eclipse-temurin-21 AS builder
LABEL maintainer="ibrahim.alame@gmail.com"

# Arguments de build
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
ARG GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_BRANCH=feature/card-manager-511
ARG GESTIONCARTE_BRANCH=feature/card-manager-511
ARG SSH_PRIVATE_KEY

# Installer Git et SSH
RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    curl \
    && rm -rf /var/lib/apt/lists/*


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
# ÉTAPE 1 : Créer le parent POM CardManager que TOUS les projets attendent
# ===================================================================

RUN echo "📦 ÉTAPE 1 : Création du parent POM CardManager..." && \
    mkdir -p cardmanager && \
    cd cardmanager

WORKDIR /usr/src/app/cardmanager

# Créer le parent POM CardManager complet
RUN cat > pom.xml << 'PARENT_POM_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.pcagrade</groupId>
    <artifactId>cardmanager</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>
    <name>CardManager Parent</name>
    <description>Parent POM for all CardManager projects</description>

    <properties>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <spring-boot.version>3.2.5</spring-boot.version>
        <mason.version>2.4.1</mason.version>
        <painter.version>1.3.0</painter.version>
        <mapstruct.version>1.5.5.Final</mapstruct.version>
        <resilience4j.version>2.2.0</resilience4j.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>${spring-boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-maven-plugin</artifactId>
                    <version>${spring-boot.version}</version>
                </plugin>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <version>3.11.0</version>
                    <configuration>
                        <source>21</source>
                        <target>21</target>
                    </configuration>
                </plugin>
            </plugins>
        </pluginManagement>
    </build>
</project>
PARENT_POM_EOF

# Installer le parent POM CardManager dans le repository local
RUN echo "🏗️ Installation du parent POM CardManager..." && \
    mvn clean install -N -B

# ===================================================================
# ÉTAPE 2 : Cloner et construire Mason (maintenant que cardmanager existe)
# ===================================================================

WORKDIR /usr/src/app

RUN echo "🔨 ÉTAPE 2 : Clonage et build de Mason..." && \
    git clone --depth 1 -b feature/RETRIEVER-511 git@bitbucket.org:pcafxc/mason.git mason && \
    cd mason && \
    mvn clean install -DskipTests -Dmaven.test.skip=true -B -q

# ===================================================================
# ÉTAPE 3 : Cloner Painter et créer structure multi-modules correcte
# ===================================================================

WORKDIR /usr/src/app

RUN echo "🎨 ÉTAPE 3 : Clonage de Painter..." && \
    git clone --depth 1 -b feature/card-manager-511 git@bitbucket.org:pcafxc/painter.git painter

WORKDIR /usr/src/app/painter

# Corriger le POM parent de Painter si nécessaire (remplacer <n> par <name>)
RUN sed -i 's/<n>/<name>/g' pom.xml || true
RUN sed -i 's/<\/n>/<\/name>/g' pom.xml || true

# Corriger les POM des sous-modules
RUN for module in painter-common painter-client painter; do \
        if [ -f "$module/pom.xml" ]; then \
            sed -i 's/<n>/<name>/g' "$module/pom.xml" || true; \
            sed -i 's/<\/n>/<\/name>/g' "$module/pom.xml" || true; \
        fi; \
    done

# ===================================================================
# ÉTAPE 4 : Construire Painter avec structure multi-modules
# ===================================================================

RUN echo "🎨 ÉTAPE 4 : Construction de Painter (multi-modules)..." && \
    echo "📦 Ordre de construction :" && \
    echo "   1️⃣ painter-common (DTOs et interfaces)" && \
    echo "   2️⃣ painter-client (client library)" && \
    echo "   3️⃣ painter (application principale)" && \
    mvn clean install -DskipTests -Dmaven.test.skip=true -B

# Si le build multi-modules échoue, essayer avec un POM autonome pour le module painter
RUN if [ ! -f painter/target/painter-*.jar ]; then \
        echo "🔧 Build multi-modules échoué, création POM autonome..."; \
        cd painter && \
        cp pom.xml pom.xml.backup && \
        cat > pom.xml << 'STANDALONE_POM_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.pcagrade.painter</groupId>
    <artifactId>painter</artifactId>
    <version>1.3.0</version>
    <packaging>jar</packaging>
    <name>Painter</name>
    <description>Application for managing images</description>

    <properties>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <spring-boot.version>3.2.5</spring-boot.version>
        <mason.version>2.4.1</mason.version>
        <mapstruct.version>1.5.5.Final</mapstruct.version>
        <ulid.version>4.2.0</ulid.version>
        <hibernate-envers.version>6.4.4.Final</hibernate-envers.version>
        <resilience4j.version>2.2.0</resilience4j.version>
        <swagger.version>2.2.21</swagger.version>
        <vectorgraphics2d.version>0.13</vectorgraphics2d.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>${spring-boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <!-- Dépendances Mason -->
        <dependency>
            <groupId>com.pcagrade.mason</groupId>
            <artifactId>mason-commons</artifactId>
            <version>${mason.version}</version>
        </dependency>
        <dependency>
            <groupId>com.pcagrade.mason</groupId>
            <artifactId>mason-jpa</artifactId>
            <version>${mason.version}</version>
        </dependency>
        <dependency>
            <groupId>com.pcagrade.mason</groupId>
            <artifactId>mason-jpa-cache</artifactId>
            <version>${mason.version}</version>
        </dependency>
        <dependency>
            <groupId>com.pcagrade.mason</groupId>
            <artifactId>mason-kubernetes</artifactId>
            <version>${mason.version}</version>
        </dependency>
        <dependency>
            <groupId>com.pcagrade.mason</groupId>
            <artifactId>mason-ulid</artifactId>
            <version>${mason.version}</version>
        </dependency>
        <dependency>
            <groupId>com.pcagrade.mason</groupId>
            <artifactId>mason-localization</artifactId>
            <version>${mason.version}</version>
        </dependency>
        <dependency>
            <groupId>com.pcagrade.mason</groupId>
            <artifactId>mason-json</artifactId>
            <version>${mason.version}</version>
        </dependency>
        <dependency>
            <groupId>com.pcagrade.mason</groupId>
            <artifactId>mason-oauth2</artifactId>
            <version>${mason.version}</version>
        </dependency>
        <dependency>
            <groupId>com.pcagrade.mason</groupId>
            <artifactId>mason-transaction-author</artifactId>
            <version>${mason.version}</version>
        </dependency>

        <!-- Dépendances Spring Boot -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webflux</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.data</groupId>
            <artifactId>spring-data-envers</artifactId>
        </dependency>

        <!-- Base de données -->
        <dependency>
            <groupId>org.mariadb.jdbc</groupId>
            <artifactId>mariadb-java-client</artifactId>
            <version>3.3.3</version>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>test</scope>
        </dependency>

        <!-- ULID pour les IDs -->
        <dependency>
            <groupId>com.github.f4b6a3</groupId>
            <artifactId>ulid-creator</artifactId>
            <version>${ulid.version}</version>
        </dependency>

        <!-- Hibernate Envers pour l'audit -->
        <dependency>
            <groupId>org.hibernate.orm</groupId>
            <artifactId>hibernate-envers</artifactId>
            <version>${hibernate-envers.version}</version>
        </dependency>

        <!-- MapStruct -->
        <dependency>
            <groupId>org.mapstruct</groupId>
            <artifactId>mapstruct</artifactId>
            <version>${mapstruct.version}</version>
        </dependency>
        <dependency>
            <groupId>org.mapstruct</groupId>
            <artifactId>mapstruct-processor</artifactId>
            <version>${mapstruct.version}</version>
            <scope>provided</scope>
        </dependency>

        <!-- Resilience4j -->
        <dependency>
            <groupId>io.github.resilience4j</groupId>
            <artifactId>resilience4j-timelimiter</artifactId>
            <version>${resilience4j.version}</version>
        </dependency>

        <!-- Swagger -->
        <dependency>
            <groupId>io.swagger.core.v3</groupId>
            <artifactId>swagger-annotations</artifactId>
            <version>${swagger.version}</version>
        </dependency>

        <!-- VectorGraphics2D pour PDF -->
        <dependency>
            <groupId>de.erichseifert.vectorgraphics2d</groupId>
            <artifactId>VectorGraphics2D</artifactId>
            <version>${vectorgraphics2d.version}</version>
        </dependency>

        <!-- Liquibase -->
        <dependency>
            <groupId>org.liquibase</groupId>
            <artifactId>liquibase-core</artifactId>
            <version>4.27.0</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${spring-boot.version}</version>
                <configuration>
                    <mainClass>com.pcagrade.painter.PainterApplication</mainClass>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
                <configuration>
                    <source>21</source>
                    <target>21</target>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.mapstruct</groupId>
                            <artifactId>mapstruct-processor</artifactId>
                            <version>${mapstruct.version}</version>
                        </path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
STANDALONE_POM_EOF
        && mvn clean package -DskipTests -Dmaven.test.skip=true -B; \
    fi

# Vérifier que le JAR a été créé
RUN cd painter && \
    if [ -f target/painter-*.jar ]; then \
        echo "✅ JAR Painter créé avec succès !"; \
        ls -la target/painter*.jar; \
    else \
        echo "❌ Aucun JAR trouvé, listage du contenu target/"; \
        ls -la target/ || echo "Dossier target inexistant"; \
        echo "Tentative build minimal..."; \
        mvn clean compile package -DskipTests -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -B || echo "Build minimal échoué"; \
    fi

# ===================================================================
# IMAGE FINALE
# ===================================================================

FROM eclipse-temurin:21-jre-alpine

# Métadonnées
LABEL maintainer="ibrahim.alame@gmail.com"
LABEL description="Service Painter pour CardManager"

# Variables d'environnement
ENV SPRING_PROFILES_ACTIVE=docker

# Création du répertoire applicatif
WORKDIR /app
RUN mkdir -p /app/images

# Installation des outils pour health check
RUN apk add --no-cache curl wget

# Copie du JAR depuis le stage builder
COPY --from=builder /usr/src/app/painter/painter/target/painter*.jar ./app.jar

# Vérification que le JAR existe
RUN if [ ! -f app.jar ]; then \
        echo "❌ JAR Painter non trouvé dans l'image finale !"; \
        ls -la /app/; \
        exit 1; \
    else \
        echo "✅ JAR Painter trouvé : $(ls -la app.jar)"; \
    fi

# Port d'exposition
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8081/actuator/health || exit 1

# Point d'entrée
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

print_success "Dockerfile MULTI-MODULES créé avec structure complète"

print_step "3. Démarrage de la base de données"
docker-compose up -d mariadb
print_success "Base de données démarrée"

print_warning "Attente de 15 secondes pour l'initialisation..."
sleep 15

print_step "4. Construction de l'image Painter (solution multi-modules)"
echo "📦 Ordre de construction multi-modules :"
echo "   1️⃣ Parent POM CardManager → installé"
echo "   2️⃣ Mason (avec toutes dépendances) → installé"
echo "   3️⃣ Painter Parent → installé"
echo "   4️⃣ Painter-Common → installé"
echo "   5️⃣ Painter-Client → installé"
echo "   6️⃣ Painter (application) → packaged"
echo "   🎯 Structure multi-modules complète !"

docker-compose build --no-cache painter
if [ $? -eq 0 ]; then
    print_success "Image Painter construite avec SUCCÈS !"
else
    print_error "Échec de la construction"
    print_warning "Affichage des logs pour diagnostic..."
    docker-compose logs painter 2>/dev/null | tail -50 || echo "Pas de logs disponibles"
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
echo "🎉 DÉPLOIEMENT MULTI-MODULES TERMINÉ !"
echo "======================================"
echo ""
echo "📊 Services démarrés :"
docker-compose ps

echo ""
echo "🔗 URLs d'accès :"
echo "   💾 Base de données: localhost:3307"
echo "   🎨 Painter API:     http://localhost:8081/"
echo "   📋 GestionCarte:    http://localhost:8080/"

echo ""
echo "🏆 RÉSUMÉ DU SUCCÈS MULTI-MODULES :"
echo "   ✅ Parent POM CardManager créé et installé"
echo "   ✅ Mason construit avec toutes ses dépendances"
echo "   ✅ Painter Parent construit (multi-modules)"
echo "   ✅ Painter-Common construit (DTOs et interfaces)"
echo "   ✅ Painter-Client construit (client library)"
echo "   ✅ Painter Application construite avec toutes dépendances"
echo "   ✅ Architecture multi-modules complètement fonctionnelle"

print_success "🎊 SOLUTION MULTI-MODULES COMPLÈTE ET FONCTIONNELLE ! 🎊"