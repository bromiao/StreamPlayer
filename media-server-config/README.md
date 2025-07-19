# Media Server Configuration Package

This package contains all the working configurations for the media streaming server setup.

## NGINX配置文件说明

### nginx_production.conf (当前使用)
- **架构**: 双阶段转码架构
  - `live` 应用: 接收RTMP输入，使用单个FFmpeg命令转码为多个质量
  - `show` 应用: 处理HLS输出和自适应流
- **优势**:
  - ✅ 更高效：单个FFmpeg进程多输出
  - ✅ 更低CPU使用率
  - ✅ 更好的性能
  - ✅ 当前正在使用且经过测试
- **质量级别**: 5个 (src, hd720, high, mid, low)
- **存储路径**: `/mnt/hls/`

### nginx_alternative.conf (备选)
- **架构**: 单应用多进程架构
  - `live` 应用: 处理输入和输出，每个质量单独的FFmpeg进程
- **优势**:
  - ✅ 配置更简单易懂
  - ✅ 包含录制功能
  - ✅ 有主播放列表端点
- **劣势**:
  - ❌ 多个FFmpeg进程，效率较低
  - ❌ 更高的CPU和内存使用
- **质量级别**: 4个 (original, hd, sd, mobile)
- **存储路径**: `/www/static/hls/`

## 主要区别对比

| 特性 | nginx_production.conf | nginx_alternative.conf |
|------|----------------------|------------------------|
| FFmpeg进程数 | 1个 | 4个 |
| CPU使用率 | 低 | 高 |
| 配置复杂度 | 中等 | 简单 |
| 质量级别 | 5个 | 4个 |
| 录制功能 | 无 | 有 |
| 主播放列表 | 自动生成 | 手动配置 |
| 当前状态 | 正在使用 | 备选方案 |

## 转码方式对比

### Production配置 (推荐)
```bash
# 单个FFmpeg命令，多输出流
exec_push ffmpeg -i input \
  -c:v libx264 -b:v 256k  -vf scale=480:270   -f flv rtmp://localhost:1935/show/stream_low \
  -c:v libx264 -b:v 768k  -vf scale=720:404   -f flv rtmp://localhost:1935/show/stream_mid \
  -c:v libx264 -b:v 1024k -vf scale=960:540   -f flv rtmp://localhost:1935/show/stream_high \
  -c:v libx264 -b:v 1920k -vf scale=1280:720  -f flv rtmp://localhost:1935/show/stream_hd720 \
  -c copy -f flv rtmp://localhost:1935/show/stream_src
```

### Alternative配置 (备选)
```bash
# 多个独立的FFmpeg进程
exec ffmpeg -i input -c:v libx264 -b:v 2500k -s 1920x1080 -f hls /www/static/hls/hd/stream/index.m3u8
exec ffmpeg -i input -c:v libx264 -b:v 1500k -s 1280x720  -f hls /www/static/hls/sd/stream/index.m3u8
exec ffmpeg -i input -c:v libx264 -b:v 800k  -s 854x480   -f hls /www/static/hls/mobile/stream/index.m3u8
```

## 使用建议

**推荐使用 nginx_production.conf**，因为：
1. **性能更好** - 单进程多输出减少系统负载
2. **稳定性更高** - 更少的进程意味着更少的故障点
3. **延迟更低** - 减少了进程间的数据传输
4. **已经测试** - 当前正在生产环境使用

**何时考虑 nginx_alternative.conf**：
1. 需要录制功能
2. 需要更简单的配置
3. 系统资源充足，不在乎效率
4. 需要独立控制每个质量级别

## 文件详细说明

### 核心配置文件
- **nginx_production.conf**: 当前生产环境配置
- **nginx_alternative.conf**: 备选配置方案
- **index.html**: 播放器网页界面
- **flv-proxy.js**: FLV代理服务器

### 管理脚本
- **start-containers.sh**: 自动启动脚本
- **stop-containers.sh**: 自动停止脚本

### Docker相关
- **Dockerfile.flv**: FLV代理服务器构建文件
- **package.json**: Node.js依赖配置
- **docker-compose.yml**: 编排配置(仅参考)

## 快速启动

```bash
# 解压配置包
tar -xzf media-server-config-20250719.tar.gz
cd media-server-config

# 启动服务(使用production配置)
./start-containers.sh

# 停止服务
./stop-containers.sh
```

## 流媒体地址

- **RTMP推流**: `rtmp://YOUR_SERVER_IP:1935/live/STREAM_KEY`
- **HLS播放**: `http://YOUR_SERVER_IP/hls/STREAM_KEY.m3u8`
- **FLV播放**: `http://YOUR_SERVER_IP:8080/live/STREAM_KEY`
- **网页播放器**: `http://YOUR_SERVER_IP/`

当前服务器IP: 13.113.238.113