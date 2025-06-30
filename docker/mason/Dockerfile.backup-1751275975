# Dockerfile pour Mason - Bibliothèque commune
FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /usr/src/app

# Créer le POM parent que Mason attend
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
    echo '    </properties>' >> pom.xml && \
    echo '</project>' >> pom.xml

# Installer le POM parent dans le repository local Maven
RUN mvn install -N

# Cloner Mason
RUN git clone https://github.com/ialame/mason.git mason

# Build Mason
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests

# Image finale légère
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
CMD ["tail", "-f", "/dev/null"]