#!/bin/sh
# entrypoint.sh - Injects runtime env variables into nginx config

# Extract hostname from REACT_APP_API_URL
# e.g. "https://photoshare-ai-backend-123.azurewebsites.net/api" -> "photoshare-ai-backend-123.azurewebsites.net"
if [ -n "$REACT_APP_API_URL" ]; then
    # Strip https:// and any trailing /api or /
    BACKEND_HOST=$(echo "$REACT_APP_API_URL" | sed 's|https://||' | sed 's|/api.*||' | sed 's|/.*||')
    export BACKEND_HOST
    echo "[entrypoint] BACKEND_HOST resolved to: $BACKEND_HOST"
else
    # Fallback - prevents nginx from crashing if env var missing
    export BACKEND_HOST="localhost"
    echo "[entrypoint] WARNING: REACT_APP_API_URL not set, using localhost fallback"
fi

# Substitute the env variable into nginx config
envsubst '${BACKEND_HOST}' < /etc/nginx/conf.d/default.conf > /tmp/nginx-resolved.conf
cp /tmp/nginx-resolved.conf /etc/nginx/conf.d/default.conf

echo "[entrypoint] Nginx config ready. Starting nginx..."

# Start nginx in foreground
exec nginx -g "daemon off;"
