#!/bin/sh

# Substitute environment variables in the HTML template
envsubst '${USER_NAME}' < /usr/share/nginx/html/index.html.template > /usr/share/nginx/html/index.html

# Set proper permissions for all files
chmod -R 644 /usr/share/nginx/html/*

# Start nginx
exec nginx -g "daemon off;"
