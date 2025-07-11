# =============================================================================
# Dockerfile Painter - SOLUTION MULTI-MODULES FINALE
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
# ÉTAPE 1 : Créer le parent POM CardManager
# ===================================================================

RUN echo "📦 ÉTAPE 1 : Création du parent POM CardManager..." && \
    mkdir -p cardmanager

WORKDIR /usr/src/app/cardmanager

# Créer le parent POM CardManager avec echo
RUN echo '<?xml version="1.0" encoding="UTF-8"?>' > pom.xml
RUN echo '<project xmlns="http://maven.apache.org/POM/4.0.0"' >> pom.xml
RUN echo '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' >> pom.xml
RUN echo '         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">' >> pom.xml
RUN echo '    <modelVersion>4.0.0</modelVersion>' >> pom.xml
RUN echo '    <groupId>com.pcagrade</groupId>' >> pom.xml
RUN echo '    <artifactId>cardmanager</artifactId>' >> pom.xml
RUN echo '    <version>1.0.0-SNAPSHOT</version>' >> pom.xml
RUN echo '    <packaging>pom</packaging>' >> pom.xml
RUN echo '    <name>CardManager Parent</name>' >> pom.xml
RUN echo '    <description>Parent POM for all CardManager projects</description>' >> pom.xml
RUN echo '    <properties>' >> pom.xml
RUN echo '        <maven.compiler.source>21</maven.compiler.source>' >> pom.xml
RUN echo '        <maven.compiler.target>21</maven.compiler.target>' >> pom.xml
RUN echo '        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>' >> pom.xml
RUN echo '        <spring-boot.version>3.2.5</spring-boot.version>' >> pom.xml
RUN echo '        <mason.version>2.4.1</mason.version>' >> pom.xml
RUN echo '        <painter.version>1.3.0</painter.version>' >> pom.xml
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
RUN echo '    <build>' >> pom.xml
RUN echo '        <pluginManagement>' >> pom.xml
RUN echo '            <plugins>' >> pom.xml
RUN echo '                <plugin>' >> pom.xml
RUN echo '                    <groupId>org.springframework.boot</groupId>' >> pom.xml
RUN echo '                    <artifactId>spring-boot-maven-plugin</artifactId>' >> pom.xml
RUN echo '                    <version>${spring-boot.version}</version>' >> pom.xml
RUN echo '                </plugin>' >> pom.xml
RUN echo '                <plugin>' >> pom.xml
RUN echo '                    <groupId>org.apache.maven.plugins</groupId>' >> pom.xml
RUN echo '                    <artifactId>maven-compiler-plugin</artifactId>' >> pom.xml
RUN echo '                    <version>3.11.0</version>' >> pom.xml
RUN echo '                    <configuration>' >> pom.xml
RUN echo '                        <source>21</source>' >> pom.xml
RUN echo '                        <target>21</target>' >> pom.xml
RUN echo '                    </configuration>' >> pom.xml
RUN echo '                </plugin>' >> pom.xml
RUN echo '            </plugins>' >> pom.xml
RUN echo '        </pluginManagement>' >> pom.xml
RUN echo '    </build>' >> pom.xml
RUN echo '</project>' >> pom.xml

# Installer le parent POM CardManager
RUN echo "🏗️ Installation du parent POM CardManager..." && \
    mvn clean install -N -B

# ===================================================================
# ÉTAPE 2 : Cloner et construire Mason
# ===================================================================

WORKDIR /usr/src/app

RUN echo "🔨 ÉTAPE 2 : Clonage et build de Mason..." && \
    git clone --depth 1 -b feature/RETRIEVER-511 git@bitbucket.org:pcafxc/mason.git mason && \
    cd mason && \
    mvn clean install -DskipTests -Dmaven.test.skip=true -B -q

# ===================================================================
# ÉTAPE 3 : Cloner Painter et construire multi-modules
# ===================================================================

WORKDIR /usr/src/app

RUN echo "🎨 ÉTAPE 3 : Clonage de Painter..." && \
    git clone --depth 1 -b feature/card-manager-511 git@bitbucket.org:pcafxc/painter.git painter

WORKDIR /usr/src/app/painter

# Corriger les tags <name> dans tous les POM
RUN echo "🔧 Correction des tags XML..." && \
    sed -i 's/<name>/<name>/g' pom.xml || true && \
    for module in painter-common painter-client painter; do \
        if [ -f "$module/pom.xml" ]; then \
            sed -i 's/<name>/<name>/g' "$module/pom.xml" || true; \
        fi; \
    done

# Essayer de construire la structure multi-modules
RUN echo "🎨 ÉTAPE 4 : Construction multi-modules..." && \
    echo "📦 Tentative de build du projet complet..." && \
    (mvn clean install -DskipTests -Dmaven.test.skip=true -B || echo "Build multi-modules échoué")

# Si échec, créer un POM autonome pour le module painter
RUN if [ ! -f painter/target/painter-*.jar ]; then \
        echo "🔧 Création POM autonome pour Painter..."; \
        cd painter && \
        cp pom.xml pom.xml.backup && \
        echo '<?xml version="1.0" encoding="UTF-8"?>' > pom.xml && \
        echo '<project xmlns="http://maven.apache.org/POM/4.0.0"' >> pom.xml && \
        echo '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' >> pom.xml && \
        echo '         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">' >> pom.xml && \
        echo '    <modelVersion>4.0.0</modelVersion>' >> pom.xml && \
        echo '    <groupId>com.pcagrade.painter</groupId>' >> pom.xml && \
        echo '    <artifactId>painter</artifactId>' >> pom.xml && \
        echo '    <version>1.3.0</version>' >> pom.xml && \
        echo '    <packaging>jar</packaging>' >> pom.xml && \
        echo '    <name>Painter</name>' >> pom.xml && \
        echo '    <description>Application for managing images</description>' >> pom.xml && \
        echo '    <properties>' >> pom.xml && \
        echo '        <maven.compiler.source>21</maven.compiler.source>' >> pom.xml && \
        echo '        <maven.compiler.target>21</maven.compiler.target>' >> pom.xml && \
        echo '        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>' >> pom.xml && \
        echo '        <spring-boot.version>3.2.5</spring-boot.version>' >> pom.xml && \
        echo '        <mason.version>2.4.1</mason.version>' >> pom.xml && \
        echo '        <mapstruct.version>1.5.5.Final</mapstruct.version>' >> pom.xml && \
        echo '        <ulid.version>4.2.0</ulid.version>' >> pom.xml && \
        echo '        <resilience4j.version>2.2.0</resilience4j.version>' >> pom.xml && \
        echo '        <swagger.version>2.2.21</swagger.version>' >> pom.xml && \
        echo '        <vectorgraphics2d.version>0.13</vectorgraphics2d.version>' >> pom.xml && \
        echo '    </properties>' >> pom.xml && \
        echo '    <dependencyManagement>' >> pom.xml && \
        echo '        <dependencies>' >> pom.xml && \
        echo '            <dependency>' >> pom.xml && \
        echo '                <groupId>org.springframework.boot</groupId>' >> pom.xml && \
        echo '                <artifactId>spring-boot-dependencies</artifactId>' >> pom.xml && \
        echo '                <version>${spring-boot.version}</version>' >> pom.xml && \
        echo '                <type>pom</type>' >> pom.xml && \
        echo '                <scope>import</scope>' >> pom.xml && \
        echo '            </dependency>' >> pom.xml && \
        echo '        </dependencies>' >> pom.xml && \
        echo '    </dependencyManagement>' >> pom.xml && \
        echo '    <dependencies>' >> pom.xml && \
        echo '        <!-- Mason Dependencies -->' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
        echo '            <artifactId>mason-commons</artifactId>' >> pom.xml && \
        echo '            <version>${mason.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
        echo '            <artifactId>mason-jpa</artifactId>' >> pom.xml && \
        echo '            <version>${mason.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
        echo '            <artifactId>mason-jpa-cache</artifactId>' >> pom.xml && \
        echo '            <version>${mason.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
        echo '            <artifactId>mason-kubernetes</artifactId>' >> pom.xml && \
        echo '            <version>${mason.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
        echo '            <artifactId>mason-ulid</artifactId>' >> pom.xml && \
        echo '            <version>${mason.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
        echo '            <artifactId>mason-localization</artifactId>' >> pom.xml && \
        echo '            <version>${mason.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
        echo '            <artifactId>mason-json</artifactId>' >> pom.xml && \
        echo '            <version>${mason.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
        echo '            <artifactId>mason-oauth2</artifactId>' >> pom.xml && \
        echo '            <version>${mason.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.pcagrade.mason</groupId>' >> pom.xml && \
        echo '            <artifactId>mason-transaction-author</artifactId>' >> pom.xml && \
        echo '            <version>${mason.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <!-- Spring Boot Dependencies -->' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>org.springframework.boot</groupId>' >> pom.xml && \
        echo '            <artifactId>spring-boot-starter-web</artifactId>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>org.springframework.boot</groupId>' >> pom.xml && \
        echo '            <artifactId>spring-boot-starter-webflux</artifactId>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>org.springframework.boot</groupId>' >> pom.xml && \
        echo '            <artifactId>spring-boot-starter-data-jpa</artifactId>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>org.springframework.boot</groupId>' >> pom.xml && \
        echo '            <artifactId>spring-boot-starter-security</artifactId>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>org.springframework.data</groupId>' >> pom.xml && \
        echo '            <artifactId>spring-data-envers</artifactId>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <!-- Database -->' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>org.mariadb.jdbc</groupId>' >> pom.xml && \
        echo '            <artifactId>mariadb-java-client</artifactId>' >> pom.xml && \
        echo '            <version>3.3.3</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.h2database</groupId>' >> pom.xml && \
        echo '            <artifactId>h2</artifactId>' >> pom.xml && \
        echo '            <scope>test</scope>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <!-- ULID -->' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>com.github.f4b6a3</groupId>' >> pom.xml && \
        echo '            <artifactId>ulid-creator</artifactId>' >> pom.xml && \
        echo '            <version>${ulid.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <!-- Hibernate Envers -->' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>org.hibernate.orm</groupId>' >> pom.xml && \
        echo '            <artifactId>hibernate-envers</artifactId>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <!-- MapStruct -->' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>org.mapstruct</groupId>' >> pom.xml && \
        echo '            <artifactId>mapstruct</artifactId>' >> pom.xml && \
        echo '            <version>${mapstruct.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>org.mapstruct</groupId>' >> pom.xml && \
        echo '            <artifactId>mapstruct-processor</artifactId>' >> pom.xml && \
        echo '            <version>${mapstruct.version}</version>' >> pom.xml && \
        echo '            <scope>provided</scope>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <!-- Resilience4j -->' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>io.github.resilience4j</groupId>' >> pom.xml && \
        echo '            <artifactId>resilience4j-timelimiter</artifactId>' >> pom.xml && \
        echo '            <version>${resilience4j.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <!-- Swagger -->' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>io.swagger.core.v3</groupId>' >> pom.xml && \
        echo '            <artifactId>swagger-annotations</artifactId>' >> pom.xml && \
        echo '            <version>${swagger.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <!-- VectorGraphics2D -->' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>de.erichseifert.vectorgraphics2d</groupId>' >> pom.xml && \
        echo '            <artifactId>VectorGraphics2D</artifactId>' >> pom.xml && \
        echo '            <version>${vectorgraphics2d.version}</version>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '        <!-- Liquibase -->' >> pom.xml && \
        echo '        <dependency>' >> pom.xml && \
        echo '            <groupId>org.liquibase</groupId>' >> pom.xml && \
        echo '            <artifactId>liquibase-core</artifactId>' >> pom.xml && \
        echo '        </dependency>' >> pom.xml && \
        echo '    </dependencies>' >> pom.xml && \
        echo '    <build>' >> pom.xml && \
        echo '        <plugins>' >> pom.xml && \
        echo '            <plugin>' >> pom.xml && \
        echo '                <groupId>org.springframework.boot</groupId>' >> pom.xml && \
        echo '                <artifactId>spring-boot-maven-plugin</artifactId>' >> pom.xml && \
        echo '                <version>${spring-boot.version}</version>' >> pom.xml && \
        echo '                <configuration>' >> pom.xml && \
        echo '                    <mainClass>com.pcagrade.painter.PainterApplication</mainClass>' >> pom.xml && \
        echo '                </configuration>' >> pom.xml && \
        echo '            </plugin>' >> pom.xml && \
        echo '            <plugin>' >> pom.xml && \
        echo '                <groupId>org.apache.maven.plugins</groupId>' >> pom.xml && \
        echo '                <artifactId>maven-compiler-plugin</artifactId>' >> pom.xml && \
        echo '                <version>3.11.0</version>' >> pom.xml && \
        echo '                <configuration>' >> pom.xml && \
        echo '                    <source>21</source>' >> pom.xml && \
        echo '                    <target>21</target>' >> pom.xml && \
        echo '                    <annotationProcessorPaths>' >> pom.xml && \
        echo '                        <path>' >> pom.xml && \
        echo '                            <groupId>org.mapstruct</groupId>' >> pom.xml && \
        echo '                            <artifactId>mapstruct-processor</artifactId>' >> pom.xml && \
        echo '                            <version>${mapstruct.version}</version>' >> pom.xml && \
        echo '                        </path>' >> pom.xml && \
        echo '                    </annotationProcessorPaths>' >> pom.xml && \
        echo '                </configuration>' >> pom.xml && \
        echo '            </plugin>' >> pom.xml && \
        echo '        </plugins>' >> pom.xml && \
        echo '    </build>' >> pom.xml && \
        echo '</project>' >> pom.xml && \
        mvn clean package -DskipTests -Dmaven.test.skip=true -B; \
    fi

# Vérifier que le JAR a été créé
RUN cd painter && \
    if [ -f target/painter-*.jar ]; then \
        echo "✅ JAR Painter créé avec succès !"; \
        ls -la target/painter*.jar; \
    else \
        echo "❌ JAR non trouvé, tentative de build minimal..."; \
        mvn clean compile package -DskipTests -Dmaven.test.skip=true -B || echo "Build minimal échoué"; \
        find . -name "*.jar" -type f || echo "Aucun JAR trouvé"; \
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
