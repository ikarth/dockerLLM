#!/bin/bash
cd /workspace/text-generation-webui

# Uncomment line below to enable SSL for websockets.
# WSSPORT=5006

if [ ! -z "$WSSPORT" ]; then
    echo "Setting up SSL"
    if [ ! -f "/etc/ssl/certs/nginx-selfsigned.crt" ]; then
        echo "Installing Certificate"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx-selfsigned.key \
        -out /etc/ssl/certs/nginx-selfsigned.crt \
        -subj "/C=US/ST=New York/L=New York City/O=Your Organization/OU=Your Department/CN=${RUNPOD_PUBLIC_IP}"
        openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    else
        echo "Certificate previously installed"
    fi
    echo "Setting up Nginx"
    echo "server {
        listen ${WSSPORT} ssl;
        server_name ${RUNPOD_PUBLIC_IP};

        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
        ssl_dhparam /etc/ssl/certs/dhparam.pem;

        location / {
            proxy_pass http://localhost:5005;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host \$host;
        }
    }" > /etc/nginx/sites-available/default
    nginx -t
    service nginx start
fi

# Edit these arguments if you want to customise text-generation-webui launch.
# Don't remove "$@" from the start unless you want to prevent automatic model loading from template arguments
ARGS=("$@" --listen --api)

echo "Launching text-generation-webui with args: ${ARGS[@]}"

python3 server.py "${ARGS[@]}"