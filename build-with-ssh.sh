#!/bin/bash

# Encoder votre clé SSH en base64
export SSH_PRIVATE_KEY=$(cat ~/.ssh/id_rsa | base64 -w 0)

# Builder avec la clé SSH
docker-compose build --no-cache painter

# Ou pour tout builder
# docker-compose build --no-cache
