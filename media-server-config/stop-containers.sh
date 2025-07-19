#\!/bin/bash

# Media Server Stop Script
echo "Stopping Media Server containers..."

# Stop containers
docker stop nginx-media-server flv-proxy-server 2>/dev/null || true

# Remove containers
docker rm nginx-media-server flv-proxy-server 2>/dev/null || true

echo "Media Server containers stopped and removed."
echo "Network 'media-network' preserved for future use."
