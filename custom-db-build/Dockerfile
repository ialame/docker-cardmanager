FROM mariadb:11.0

# Copie des scripts d'initialisation
COPY initdb/ /docker-entrypoint-initdb.d/

# Permissions des scripts
RUN chmod -R 755 /docker-entrypoint-initdb.d/

# Configuration MariaDB optimisée
RUN echo '[mysqld]' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'character-set-server=utf8mb4' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'collation-server=utf8mb4_unicode_ci' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'max_connections=200' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'innodb_buffer_pool_size=256M' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'innodb_log_file_size=64M' >> /etc/mysql/conf.d/cardmanager.cnf && \
    echo 'innodb_flush_log_at_trx_commit=2' >> /etc/mysql/conf.d/cardmanager.cnf

# Variables d'environnement par défaut
ENV MYSQL_ROOT_PASSWORD=foufafou
ENV MYSQL_DATABASE=dev
ENV MYSQL_USER=ia
ENV MYSQL_PASSWORD=foufafou

# Health check personnalisé
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD mariadb-admin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD || exit 1

EXPOSE 3306
