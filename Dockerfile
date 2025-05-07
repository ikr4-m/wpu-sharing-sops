# Decrypt
FROM docker.io/library/alpine:latest AS decrypt
ARG GPG_PRIVATE_KEY GPG_PASSPHRASE ENCRYPTED_ENV_FILE
WORKDIR /app

ADD https://github.com/getsops/sops/releases/download/v3.10.2/sops-v3.10.2.linux.amd64 /usr/local/bin/sops
RUN chmod +x /usr/local/bin/sops;

COPY $ENCRYPTED_ENV_FILE .
RUN set -ex; \
    apk add gnupg --no-cache;
RUN set -ex; \
    echo "$GPG_PRIVATE_KEY" > ".sops.asc"; \
    gpg --batch --pinentry-mode loopback --passphrase "$GPG_PASSPHRASE" --import .sops.asc; \
    gpg --batch --pinentry-mode loopback --passphrase "$GPG_PASSPHRASE" --sign .sops.asc; \
    sops decrypt --input-type dotenv --output-type dotenv "$ENCRYPTED_ENV_FILE" > .env;

# JS Build
FROM docker.io/library/node:23-alpine AS build
WORKDIR /app

COPY package*.json .
RUN npm install --include=dev;

COPY . .
COPY --from=decrypt /app/.env .
RUN npm run build

# Host
FROM docker.io/library/nginx:alpine
COPY --from=build /app/dist /app
RUN echo "server {\
    listen 80;\
    access_log /dev/stdout;\
    root /app;\
    location / {\
        try_files \$uri \$uri/ /index.html;\
        index index.html;\
    }\
}" > /etc/nginx/conf.d/default.conf
EXPOSE 80
