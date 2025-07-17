FROM alpine:3.16

# Install dependencies
RUN apk add --no-cache \
    build-base \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    curl \
    gnupg \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    perl-dev \
    ffmpeg \
    ffmpeg-dev

# Set nginx version
ENV NGINX_VERSION=1.22.1
ENV NGINX_RTMP_VERSION=1.2.2
ENV NGINX_FLV_VERSION=1.2.10

# Create nginx user
RUN addgroup -S nginx && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

# Download and compile nginx with modules
RUN cd /tmp && \
    # Download nginx
    curl -fSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz && \
    # Download nginx-rtmp-module
    curl -fSL https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz -o nginx-rtmp-module.tar.gz && \
    # Download nginx-http-flv-module
    curl -fSL https://github.com/winshining/nginx-http-flv-module/archive/v${NGINX_FLV_VERSION}.tar.gz -o nginx-http-flv-module.tar.gz && \
    # Extract all
    tar -xzf nginx.tar.gz && \
    tar -xzf nginx-rtmp-module.tar.gz && \
    tar -xzf nginx-http-flv-module.tar.gz && \
    # Compile nginx
    cd nginx-${NGINX_VERSION} && \
    ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --add-module=../nginx-rtmp-module-${NGINX_RTMP_VERSION} \
        --add-module=../nginx-http-flv-module-${NGINX_FLV_VERSION} && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    # Clean up
    rm -rf /tmp/* && \
    # Create cache directories
    mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp && \
    chown -R nginx:nginx /var/cache/nginx

# Create required directories
RUN mkdir -p /www/static/hls \
             /www/static/dash \
             /www/static/recordings \
             /var/log/nginx && \
    chown -R nginx:nginx /www/static /var/log/nginx

# Copy default stat.xsl
RUN curl -fSL https://raw.githubusercontent.com/arut/nginx-rtmp-module/master/stat.xsl -o /www/static/stat.xsl

# Expose ports
EXPOSE 80 1935 8080

# Start nginx
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]