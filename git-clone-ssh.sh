                                           #!/bin/bash

                                           # 🔑 Configuration Git avec Clés SSH pour Docker

                                           echo "🔑 Configuration Git SSH pour Docker"
                                           echo "==================================="

                                           echo ""
                                           echo "💡 AVANTAGES DES CLÉS SSH :"
                                           echo "   ✅ Plus fiables que les tokens dans Docker"
                                           echo "   ✅ Pas de problème d'expiration"
                                           echo "   ✅ Authentification standard Git"
                                           echo "   ✅ Support natif Bitbucket/GitHub"
                                           echo ""

                                           # =====================================
                                           # ÉTAPE 1: Vérification clé SSH existante
                                           # =====================================
                                           echo "🔍 ÉTAPE 1: VÉRIFICATION CLÉS SSH EXISTANTES"
                                           echo "───────────────────────────────────────────"
                                           echo ""

                                           if [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_ed25519 ]; then
                                               echo "✅ Clés SSH détectées :"
                                               ls -la ~/.ssh/id_* 2>/dev/null || echo "Aucune clé privée trouvée"
                                               echo ""
                                               echo "📋 Clés publiques disponibles :"
                                               for key in ~/.ssh/id_*.pub; do
                                                   if [ -f "$key" ]; then
                                                       echo "🔑 $(basename $key):"
                                                       cat "$key"
                                                       echo ""
                                                   fi
                                               done
                                           else
                                               echo "❌ Aucune clé SSH trouvée"
                                               echo "💡 Nous allons en créer une"
                                           fi

                                           # =====================================
                                           # ÉTAPE 2: Création clé SSH si nécessaire
                                           # =====================================
                                           echo "🆕 ÉTAPE 2: CRÉATION CLÉS SSH"
                                           echo "───────────────────────────"
                                           echo ""

                                           read -p "💭 Voulez-vous créer une nouvelle clé SSH ? (y/N): " create_new_key

                                           if [[ $create_new_key =~ ^[Yy]$ ]]; then
                                               echo ""
                                               read -p "📧 Votre email pour la clé SSH: " ssh_email

                                               if [ ! -z "$ssh_email" ]; then
                                                   key_name="cardmanager_$(date +%Y%m%d)"
                                                   echo "🔨 Création de la clé SSH: $key_name"

                                                   # Créer clé ED25519 (plus moderne et sécurisée)
                                                   ssh-keygen -t ed25519 -C "$ssh_email" -f ~/.ssh/$key_name -N ""

                                                   echo "✅ Clé SSH créée !"
                                                   echo ""
                                                   echo "🔑 Clé publique (à ajouter sur Bitbucket) :"
                                                   echo "─────────────────────────────────────────"
                                                   cat ~/.ssh/${key_name}.pub
                                                   echo "─────────────────────────────────────────"
                                                   echo ""

                                                   # Sauvegarder le nom de la clé pour usage ultérieur
                                                   ssh_key_name="$key_name"
                                               fi
                                           else
                                               # Utiliser clé existante
                                               echo "📋 Clés existantes :"
                                               ls ~/.ssh/id_* 2>/dev/null | grep -v ".pub" | head -5
                                               echo ""
                                               read -p "🔑 Nom de la clé à utiliser (ex: id_rsa): " existing_key

                                               if [ -f ~/.ssh/$existing_key ]; then
                                                   ssh_key_name="$existing_key"
                                                   echo "✅ Utilisation de la clé: $ssh_key_name"
                                                   echo ""
                                                   echo "🔑 Clé publique correspondante :"
                                                   cat ~/.ssh/${ssh_key_name}.pub 2>/dev/null || echo "❌ Clé publique non trouvée"
                                               else
                                                   echo "❌ Clé non trouvée: ~/.ssh/$existing_key"
                                                   exit 1
                                               fi
                                           fi

                                           # =====================================
                                           # ÉTAPE 3: Configuration Bitbucket
                                           # =====================================
                                           echo ""
                                           echo "🔧 ÉTAPE 3: AJOUTER LA CLÉ SUR BITBUCKET"
                                           echo "───────────────────────────────────────"
                                           echo ""
                                           echo "📋 PROCÉDURE :"
                                           echo "1. Allez sur: https://bitbucket.org/account/settings/ssh-keys/"
                                           echo "2. Cliquez 'Add key'"
                                           echo "3. Label: 'Docker CardManager $(date +%Y-%m-%d)'"
                                           echo "4. Collez cette clé publique :"
                                           echo ""
                                           echo "─────── COPIEZ CETTE CLÉ ───────"
                                           if [ ! -z "$ssh_key_name" ]; then
                                               cat ~/.ssh/${ssh_key_name}.pub
                                           else
                                               echo "❌ Aucune clé sélectionnée"
                                           fi
                                           echo "─────────────────────────────────"
                                           echo ""
                                           read -p "✅ Avez-vous ajouté la clé sur Bitbucket ? (y/N): " key_added

                                           # =====================================
                                           # ÉTAPE 4: Test connexion SSH
                                           # =====================================
                                           if [[ $key_added =~ ^[Yy]$ ]]; then
                                               echo ""
                                               echo "🧪 ÉTAPE 4: TEST CONNEXION SSH"
                                               echo "─────────────────────────────"
                                               echo ""

                                               # Test connexion Bitbucket
                                               echo "🔍 Test connexion SSH Bitbucket..."
                                               if ssh -T git@bitbucket.org -o StrictHostKeyChecking=no 2>&1 | grep -q "logged in as"; then
                                                   echo "✅ SUCCÈS ! Connexion SSH Bitbucket OK"
                                                   ssh_works=true
                                               else
                                                   echo "⚠️ Test SSH inconcluant, mais continuons..."
                                                   ssh_works=false
                                               fi

                                               echo ""

                                               # Test clone repository
                                               echo "🧪 Test clone repository avec SSH..."
                                               test_clone_dir="test-ssh-clone-$$"

                                               if git clone git@bitbucket.org:pcafxc/mason.git "$test_clone_dir" 2>/dev/null; then
                                                   echo "✅ SUCCÈS ! Clone SSH fonctionne"
                                                   rm -rf "$test_clone_dir"
                                                   ssh_clone_works=true
                                               else
                                                   echo "❌ Clone SSH a échoué"
                                                   ssh_clone_works=false
                                               fi
                                           fi

                                           # =====================================
                                           # ÉTAPE 5: Configuration Docker avec SSH
                                           # =====================================
                                           echo ""
                                           echo "🐳 ÉTAPE 5: CONFIGURATION DOCKER AVEC SSH"
                                           echo "────────────────────────────────────────"
                                           echo ""

                                           if [ ! -z "$ssh_key_name" ]; then

                                               # Créer configuration .env avec URLs SSH
                                               cat > .env.ssh << EOF
                                           # Configuration SSH pour Bitbucket
                                           MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
                                           PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
                                           GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git
                                           MASON_BRANCH=main
                                           PAINTER_BRANCH=main
                                           GESTIONCARTE_BRANCH=main
                                           GIT_TOKEN=
                                           SSH_KEY_NAME=${ssh_key_name}
                                           DB_NAME=dev
                                           DB_USER=ia
                                           DB_PASSWORD=foufafou
                                           DB_ROOT_PASSWORD=root_password
                                           GESTIONCARTE_PORT=8080
                                           PAINTER_PORT=8081
                                           NGINX_PORT=8082
                                           MARIADB_PORT=3307
                                           EOF

                                               echo "✅ Configuration .env.ssh créée"
                                               echo ""

                                               # Créer Dockerfile modifié pour SSH
                                               echo "🔧 Création Dockerfile avec support SSH..."

                                               cat > docker/painter/Dockerfile.ssh << 'EOF'
                                           # 🎨 Dockerfile Painter avec support SSH
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
                                           ARG SSH_PRIVATE_KEY

                                           # Configuration SSH
                                           RUN mkdir -p ~/.ssh && \
                                               chmod 700 ~/.ssh && \
                                               ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts

                                           # Ajouter la clé SSH privée
                                           RUN if [ ! -z "$SSH_PRIVATE_KEY" ]; then \
                                                   echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa && \
                                                   chmod 600 ~/.ssh/id_rsa; \
                                               fi

                                           # Configuration Git
                                           RUN git config --global user.email "docker@cardmanager.local" && \
                                               git config --global user.name "Docker Builder"

                                           # Créer le POM parent
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
                                               echo '    </properties>' >> pom.xml && \
                                               echo '</project>' >> pom.xml

                                           # Installer le POM parent
                                           RUN mvn install -N

                                           # Cloner les repositories avec SSH
                                           RUN git clone --depth 1 --branch "$MASON_BRANCH" "$MASON_REPO_URL" mason
                                           RUN git clone --depth 1 --branch "$PAINTER_BRANCH" "$PAINTER_REPO_URL" painter

                                           # Build Mason
                                           WORKDIR /usr/src/app/mason
                                           RUN mvn clean install -DskipTests

                                           # Build Painter
                                           WORKDIR /usr/src/app/painter
                                           RUN mvn clean package -DskipTests

                                           # Image finale
                                           FROM eclipse-temurin:21-jre-alpine
                                           WORKDIR /app
                                           RUN apk add --no-cache curl
                                           COPY --from=builder /usr/src/app/painter/painter/target/painter-*.jar app.jar
                                           RUN mkdir -p /app/images
                                           ENV JAVA_OPTS="-Xmx1024m -Xms512m"
                                           ENV PAINTER_IMAGE_STORAGE_PATH="/app/images"
                                           EXPOSE 8080
                                           HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
                                               CMD curl -f http://localhost:8080/actuator/health || exit 1
                                           ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
                                           EOF

                                               echo "✅ Dockerfile SSH créé: docker/painter/Dockerfile.ssh"
                                               echo ""

                                               # Script pour configurer SSH build
                                               cat > configure-ssh-build.sh << EOF
                                           #!/bin/bash

                                           # Configuration SSH Build pour Docker

                                           echo "🔧 Configuration SSH Build"
                                           echo "=========================="

                                           # Lire la clé privée
                                           if [ -f ~/.ssh/${ssh_key_name} ]; then
                                               echo "📖 Lecture de la clé privée: ~/.ssh/${ssh_key_name}"
                                               SSH_KEY=\$(cat ~/.ssh/${ssh_key_name} | base64 -w 0)

                                               # Mettre à jour docker-compose.yml avec la clé SSH
                                               echo "🔧 Modification docker-compose.yml pour SSH..."

                                               # Créer version modifiée du docker-compose
                                               cp docker-compose.yml docker-compose.ssh.yml

                                               # Ajouter l'argument SSH_PRIVATE_KEY
                                               sed -i 's/args:/args:\
                                                   SSH_PRIVATE_KEY: \${SSH_PRIVATE_KEY}/g' docker-compose.ssh.yml

                                               echo "✅ Configuration SSH prête"
                                               echo ""
                                               echo "🚀 Pour builder avec SSH :"
                                               echo "   export SSH_PRIVATE_KEY=\$SSH_KEY"
                                               echo "   cp .env.ssh .env"
                                               echo "   cp docker/painter/Dockerfile.ssh docker/painter/Dockerfile"
                                               echo "   docker-compose -f docker-compose.ssh.yml build --no-cache"

                                           else
                                               echo "❌ Clé privée non trouvée: ~/.ssh/${ssh_key_name}"
                                           fi
                                           EOF

                                               chmod +x configure-ssh-build.sh
                                               echo "✅ Script configure-ssh-build.sh créé"
                                           fi

                                           echo ""
                                           echo "📋 RÉSUMÉ CONFIGURATION SSH"
                                           echo "─────────────────────────"
                                           echo ""
                                           echo "🎯 ÉTAPES POUR UTILISER SSH :"
                                           echo ""
                                           echo "1️⃣ AJOUTER CLÉ SUR BITBUCKET :"
                                           echo "   https://bitbucket.org/account/settings/ssh-keys/"
                                           echo ""
                                           echo "2️⃣ TESTER ACCÈS SSH :"
                                           echo "   ssh -T git@bitbucket.org"
                                           echo "   git clone git@bitbucket.org:pcafxc/mason.git test-ssh"
                                           echo ""
                                           echo "3️⃣ CONFIGURER DOCKER :"
                                           echo "   ./configure-ssh-build.sh"
                                           echo ""
                                           echo "4️⃣ BUILDER AVEC SSH :"
                                           echo "   cp .env.ssh .env"
                                           echo "   cp docker/painter/Dockerfile.ssh docker/painter/Dockerfile"
                                           echo "   # Puis suivre les instructions du script"
                                           echo ""
                                           echo "💡 AVANTAGES SSH :"
                                           echo "   ✅ Plus fiable que les tokens"
                                           echo "   ✅ Pas de problème de permissions"
                                           echo "   ✅ Standard Git universel"
                                           echo ""
                                           echo "⚠️ IMPORTANT :"
                                           echo "   La clé SSH doit être ajoutée sur Bitbucket"
                                           echo "   Et testée avant d'utiliser Docker"
