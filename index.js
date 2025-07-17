import NodeMediaServer from 'node-media-server';

const liveServer = new NodeMediaServer({
  bind: '192.168.1.104',
  rtmp: {
    port: 1935,
    chunk_size: 60000,
    ping: 30,
    ping_timeout: 60,
  },
  http: {
    port: 8000,
    // mediaroot: './media',
    allow_origin: '*',
  },
});

liveServer.run();