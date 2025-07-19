# 📺 Live Streaming Server - 完整部署方案

基于 Docker + Nginx-RTMP + HLS/FLV 的高性能直播流媒体服务器，支持多质量自适应流和超低延迟配置。

## 🚀 快速开始

### 1. 服务器要求
- **系统**: Ubuntu 18.04+
- **Docker**: 20.10+
- **端口**: 80 (HTTP), 1935 (RTMP), 8080 (FLV)
- **内存**: 2GB+
- **CPU**: 2核心+

### 2. 一键部署
```bash
# 下载配置包
wget https://your-server.com/media-streaming-server-config.tar.gz

# 解压并部署
tar -xzf media-streaming-server-config.tar.gz
cd media-server-config

# 启动服务（推荐配置：8-12秒延迟）
./start-ultra-low-latency.sh
```

### 3. 推流设置
**OBS Studio 配置:**
- **服务**: 自定义
- **服务器**: `rtmp://YOUR_SERVER_IP:1935/live`
- **推流码**: `123` (可自定义)

### 4. 观看直播
访问: `http://YOUR_SERVER_IP/`

选择播放模式：
- **Ultra Low Latency HLS**: 8-12秒延迟，支持质量切换
- **FLV (Lowest Latency)**: 2-5秒延迟，最低延迟模式

## 📊 延迟配置对比

| 配置方案 | 延迟 | 稳定性 | 网络要求 | 适用场景 |
|----------|------|--------|----------|----------|
| **标准配置** | 35秒 | ⭐⭐⭐⭐⭐ | 低 | 录播、网络差的环境 |
| **平衡配置** ⭐ | 8-12秒 | ⭐⭐⭐⭐ | 中等 | **推荐**，一般直播场景 |
| **稳定配置** | 18-25秒 | ⭐⭐⭐⭐⭐ | 低 | 网络不稳定的环境 |
| **FLV流** | 2-5秒 | ⭐⭐⭐ | 中等 | 实时互动、游戏直播 |

## ⚙️ 配置切换

### 切换到平衡配置 (推荐)
```bash
./stop-containers.sh
cp nginx_balanced_latency.conf nginx_ultra_low_latency.conf
./start-ultra-low-latency.sh
```

### 切换到稳定配置
```bash
./stop-containers.sh
cp nginx_stable_latency.conf nginx_ultra_low_latency.conf
./start-ultra-low-latency.sh
```

### 切换到标准配置
```bash
./stop-containers.sh
./start-containers.sh
```

## 📁 项目结构

```
media-server-config/
├── 🐳 Docker 配置
│   ├── Dockerfile.flv              # FLV代理Docker构建文件
│   ├── docker-compose.yml          # Docker编排配置
│   ├── flv-proxy.js                # FLV代理Node.js服务
│   └── package.json                # Node.js依赖
├── ⚙️ Nginx 配置
│   ├── nginx_production.conf       # 标准生产配置 (35s延迟)
│   ├── nginx_balanced_latency.conf # 平衡延迟配置 (8-12s延迟) ⭐
│   ├── nginx_stable_latency.conf   # 稳定延迟配置 (18-25s延迟)
│   └── nginx_ultra_low_latency.conf # 当前使用配置
├── 🎮 Web播放器
│   └── index_ultra_low_latency.html # 支持质量切换的播放器
├── 🚀 启动脚本
│   ├── start-containers.sh         # 标准启动 (35s延迟)
│   ├── start-ultra-low-latency.sh  # 低延迟启动 ⭐
│   └── stop-containers.sh          # 停止所有服务
└── 📖 文档
    ├── README.md                   # 本文档
    └── latency_optimization_guide.md # 延迟优化详细指南
```

## 🔧 核心配置参数详解

### HLS 延迟配置
```nginx
# 平衡配置 (推荐)
hls_fragment 2;           # 2秒片段
hls_playlist_length 4;    # 4个片段 = 8秒延迟
hls_cleanup on;           # 自动清理
hls_sync 200ms;           # 同步间隔
hls_continuous on;        # 连续模式
```

### 质量自适应配置
```nginx
# 5个质量等级
hls_variant _src BANDWIDTH=4096000;    # 源质量
hls_variant _hd720 BANDWIDTH=2048000;  # HD 720p
hls_variant _high BANDWIDTH=1152000;   # 高质量
hls_variant _mid BANDWIDTH=448000;     # 中等质量  
hls_variant _low BANDWIDTH=288000;     # 低质量
```

## 🎯 功能特性

### ✅ 已实现功能
- **多协议支持**: HLS、FLV、RTMP
- **自适应码率**: 5个质量等级自动切换
- **超低延迟**: 最低2-5秒延迟
- **容器化部署**: Docker 一键启动
- **实时监控**: 内置延迟测试工具
- **跨平台兼容**: 支持所有主流浏览器
- **负载均衡**: 支持多服务器部署

### 🎮 播放器功能
- **质量手动切换**: 6个档位 (Auto/Source/HD720p/High/Medium/Low)
- **延迟实时测试**: 内置计时器测量实际延迟
- **双播放模式**: HLS(兼容性好) + FLV(延迟最低)
- **状态监控**: 实时显示缓冲、延迟状态
- **响应式设计**: 支持移动端访问

## 🚦 部署步骤详解

### 步骤 1: 环境准备
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到 docker 组
sudo usermod -aG docker $USER
```

### 步骤 2: 部署服务
```bash
# 下载项目
git clone <your-repo-url>
cd media-server-config

# 构建 FLV 代理镜像
docker build -f Dockerfile.flv -t media-server-flv-proxy .

# 创建网络
docker network create media-network

# 启动服务
./start-ultra-low-latency.sh
```

### 步骤 3: 验证部署
```bash
# 检查容器状态
docker ps

# 测试HTTP服务
curl -I http://localhost/

# 测试FLV代理
curl -I http://localhost:8080/health

# 查看日志
docker logs nginx-media-server
docker logs flv-proxy-server
```

## 🔍 故障排除

### 常见问题

**1. nginx 启动失败**
```bash
# 检查配置文件语法
docker run --rm -v $(pwd)/nginx_ultra_low_latency.conf:/etc/nginx/nginx.conf nginx nginx -t

# 查看详细错误
docker logs nginx-media-server
```

**2. 推流连接失败**
```bash
# 检查防火墙
sudo ufw allow 1935

# 检查端口占用
netstat -tulpn | grep 1935

# 查看RTMP统计
curl http://localhost/stat
```

**3. 播放卡顿频繁**
```bash
# 切换到稳定配置
./stop-containers.sh
cp nginx_stable_latency.conf nginx_ultra_low_latency.conf
./start-ultra-low-latency.sh
```

**4. FLV 播放 404 错误**
```bash
# 检查容器网络连接
docker exec nginx-media-server ping flv-proxy-server

# 重启FLV代理
docker restart flv-proxy-server
```

### 性能优化

**服务器优化:**
```bash
# 增加文件描述符限制
echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf

# 优化内核参数
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" >> /etc/sysctl.conf
sysctl -p
```

**OBS 推流优化:**
- **编码器**: x264 (软件) 或 NVENC (硬件)
- **码率控制**: CBR (恒定码率)
- **关键帧间隔**: 1秒 (低延迟) 或 2秒 (稳定)
- **预设**: ultrafast (最低延迟) 或 superfast (平衡)

## 📈 监控和日志

### 实时统计
- **RTMP 统计**: `http://YOUR_SERVER_IP/stat`
- **Nginx 状态**: `docker logs nginx-media-server`
- **FLV 代理状态**: `docker logs flv-proxy-server`

### 性能指标
```bash
# CPU 和内存使用
docker stats

# 网络流量监控
docker exec nginx-media-server iftop

# 磁盘使用情况
df -h
```

## 🌐 生产环境部署

### 安全配置
```nginx
# 限制推流IP
allow publish 192.168.1.0/24;
deny publish all;

# 添加认证
on_publish http://your-auth-server.com/auth;
```

### 负载均衡
```bash
# 使用 nginx 代理多个流服务器
upstream streaming_backend {
    server stream1.example.com:1935;
    server stream2.example.com:1935;
}
```

### HTTPS 配置
```bash
# 使用 Let's Encrypt
sudo apt install certbot
sudo certbot --nginx -d your-domain.com
```

## 📞 技术支持

- **项目地址**: [GitHub Repository]
- **问题反馈**: [Issues]
- **文档更新**: 2025-07-19

## 📄 许可证

MIT License

---

**⚡ 享受低延迟直播体验！**