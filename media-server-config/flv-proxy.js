const express = require('express');
const { spawn } = require('child_process');
const cors = require('cors');

const app = express();
const PORT = 8080;

// Enable CORS for all routes
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Range', 'User-Agent', 'Accept'],
    exposedHeaders: ['Content-Length', 'Content-Range']
}));

// FLV live streaming endpoint
app.get('/live/:streamKey', (req, res) => {
    const streamKey = req.params.streamKey;
    const rtmpUrl = `rtmp://nginx-media-server:1935/live/${streamKey}`;
    
    console.log(`Starting FLV stream for: ${streamKey}`);
    
    // Set FLV headers
    res.writeHead(200, {
        'Content-Type': 'video/x-flv',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Range',
        'Transfer-Encoding': 'chunked'
    });
    
    // FFmpeg command to convert RTMP to FLV
    const ffmpeg = spawn('ffmpeg', [
        '-i', rtmpUrl,
        '-c', 'copy',
        '-f', 'flv',
        'pipe:1'
    ], {
        stdio: ['ignore', 'pipe', 'pipe']
    });
    
    // Pipe FFmpeg output to response
    ffmpeg.stdout.pipe(res);
    
    // Handle errors
    ffmpeg.stderr.on('data', (data) => {
        console.error(`FFmpeg error: ${data}`);
    });
    
    ffmpeg.on('error', (error) => {
        console.error(`FFmpeg spawn error: ${error}`);
        if (!res.headersSent) {
            res.status(500).end('Stream error');
        }
    });
    
    ffmpeg.on('close', (code) => {
        console.log(`FFmpeg process closed with code ${code}`);
        if (!res.finished) {
            res.end();
        }
    });
    
    // Handle client disconnect
    req.on('close', () => {
        console.log(`Client disconnected from stream: ${streamKey}`);
        if (!ffmpeg.killed) {
            ffmpeg.kill('SIGTERM');
        }
    });
    
    req.on('aborted', () => {
        console.log(`Request aborted for stream: ${streamKey}`);
        if (!ffmpeg.killed) {
            ffmpeg.kill('SIGTERM');
        }
    });
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'FLV Proxy' });
});

// RTMP statistics proxy
app.get('/stat', async (req, res) => {
    try {
        const fetch = (await import('node-fetch')).default;
        const response = await fetch('http://nginx-media-server/stat');
        const data = await response.text();
        res.set('Content-Type', 'application/xml');
        res.send(data);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch statistics' });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`FLV Proxy server running on port ${PORT}`);
});