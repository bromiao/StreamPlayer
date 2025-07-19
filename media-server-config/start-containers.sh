#\!/bin/bash

# Media Server Startup Script
echo "Starting Media Server containers..."

# Create Docker network if it doesn't exist
docker network create media-network 2>/dev/null || echo "Network media-network already exists"

# Stop and remove existing containers
echo "Stopping existing containers..."
docker stop nginx-media-server flv-proxy-server 2>/dev/null || true
docker rm nginx-media-server flv-proxy-server 2>/dev/null || true

# Start nginx-media-server
echo "Starting nginx-media-server..."
docker run -d --name nginx-media-server \
    --network media-network \
    -p 80:80 \
    -p 1935:1935 \
    -v $(pwd)/nginx_production.conf:/etc/nginx/nginx.conf:ro \
    -v $(pwd)/index.html:/usr/local/nginx/html/index.html:ro \
    alqutami/rtmp-hls:latest

# Build flv-proxy image if it doesn't exist
if \! docker images | grep -q media-server-flv-proxy; then
    echo "Building flv-proxy-server image..."
    docker build -f Dockerfile.flv -t media-server-flv-proxy .
fi

# Start flv-proxy-server  
echo "Starting flv-proxy-server..."
docker run -d --name flv-proxy-server \
    --network media-network \
    -p 8080:8080 \
    media-server-flv-proxy

# Wait a moment for containers to start
sleep 3

# Check container status
echo "Container status:"
docker ps --filter "name=nginx-media-server" --filter "name=flv-proxy-server"

echo ""
echo "Media Server is ready\!"
echo "Web player: http://localhost/"
echo "RTMP input: rtmp://localhost:1935/live/YOUR_STREAM_KEY"
echo "FLV stream: http://localhost:8080/live/YOUR_STREAM_KEY"
echo "HLS stream: http://localhost/hls/YOUR_STREAM_KEY.m3u8"
