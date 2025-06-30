# 🗄️ MariaDB Image Personnalisée pour CardManager
FROM mariadb:11.0

# Informations sur l'image
LABEL maintainer="ibrahim.alame@gmail.com"
LABEL description="MariaDB avec données CardManager pré-chargées"
LABEL version="1.0"

# Variables d'environnement par défaut
ENV MYSQL_ROOT_PASSWORD=root_password
ENV MYSQL_DATABASE=dev
ENV MYSQL_USER=ia
ENV MYSQL_PASSWORD=foufafou

# Copier les scripts d'initialisation
COPY initdb/ /docker-entrypoint-initdb.d/

# Définir les permissions correctes
RUN chmod -R 755 /docker-entrypoint-initdb.d/

# Exposer le port standard
EXPOSE 3306

# Configuration MariaDB optimisée
RUN echo '[mysqld]' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'character-set-server=utf8mb4' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'collation-server=utf8mb4_unicode_ci' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'max_connections=200' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'innodb_buffer_pool_size=256M' >> /etc/mysql/conf.d/cardmanager.cnf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD mysqladmin ping -h localhost -u $MYSQL_USER -p$MYSQL_PASSWORD || exit 1
