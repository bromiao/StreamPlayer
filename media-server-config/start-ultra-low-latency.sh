#\!/bin/bash

echo "🚀 Starting ULTRA Low Latency Media Server..."
echo "Expected latency: 2-5 seconds (aggressive configuration)"
echo ""

# Create Docker network
docker network create media-network 2>/dev/null || echo "Network exists"

# Stop existing containers
echo "Stopping existing containers..."
docker stop nginx-media-server flv-proxy-server 2>/dev/null || true
docker rm nginx-media-server flv-proxy-server 2>/dev/null || true

# Build flv-proxy if needed
if \! docker images | grep -q media-server-flv-proxy; then
    echo "Building flv-proxy image..."
    docker build -f Dockerfile.flv -t media-server-flv-proxy .
fi

# Start flv-proxy FIRST
echo "Starting FLV proxy server..."
docker run -d --name flv-proxy-server \
    --network media-network \
    -p 8080:8080 \
    media-server-flv-proxy

# Wait for flv-proxy to be ready
echo "Waiting for FLV proxy to be ready..."
sleep 5

# Start nginx with ultra low latency config
echo "Starting nginx with ULTRA low latency configuration..."
docker run -d --name nginx-media-server \
    --network media-network \
    -p 80:80 \
    -p 1935:1935 \
    -v $(pwd)/nginx_ultra_low_latency.conf:/etc/nginx/nginx.conf:ro \
    -v $(pwd)/index_ultra_low_latency.html:/usr/local/nginx/html/index.html:ro \
    alqutami/rtmp-hls:latest

sleep 3

echo ""
echo "✅ ULTRA Low Latency Server Ready\!"
echo ""
echo "🎯 Testing Instructions:"
echo "1. Start OBS streaming to: rtmp://13.113.238.113:1935/live/123"
echo "2. Open browser: http://13.113.238.113/"
echo "3. Try both HLS and FLV options"
echo "4. Use the latency test tool on the page"
echo ""
echo "⚡ For LOWEST latency: Use FLV option (2-5s expected)"
echo "📺 For compatibility: Use Ultra Low HLS (5-10s expected)"
echo ""
echo "⚠️  Note: Ultra low latency may cause more buffering on slow connections"

docker ps --filter "name=nginx-media-server" --filter "name=flv-proxy-server"
