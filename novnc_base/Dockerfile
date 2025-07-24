FROM debian:bullseye-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    python3 \
    python3-pip \
    x11vnc \
    xvfb \
    openbox \
    firefox-esr \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install websockify
RUN pip3 install websockify

# Download and setup noVNC
RUN mkdir -p /opt/novnc && \
    curl -sSL https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xzf - --strip-components=1 -C /opt/novnc

# Create custom noVNC configuration for dynamic subdomain support
COPY <<EOF /opt/novnc/index.html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>noVNC</title>
    <style>
        html, body {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
            overflow: hidden;
        }
        #screen {
            width: 100%;
            height: 100%;
            border: none;
        }
    </style>
</head>
<body>
    <div id="screen"></div>
    <script type="module">
        import RFB from './core/rfb.js';
        
        // Dynamic WebSocket URL resolution for subdomain support
        function getWebSocketURL() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const host = window.location.host;
            const path = window.location.pathname.replace(/\/$/, '');
            
            // Use current host for WebSocket connection (works for both localhost and subdomain)
            return `${protocol}//${host}${path}/websockify`;
        }
        
        // Initialize RFB connection
        function initVNC() {
            const rfb = new RFB(document.getElementById('screen'), getWebSocketURL(), {
                credentials: { password: '' },
                wsProtocols: ['binary']
            });
            
            rfb.addEventListener('connect', () => {
                console.log('Connected to VNC server');
            });
            
            rfb.addEventListener('disconnect', (e) => {
                console.log('Disconnected from VNC server:', e.detail.clean ? 'clean' : 'dirty');
            });
            
            rfb.addEventListener('credentialsrequired', () => {
                console.log('Credentials required');
            });
            
            rfb.addEventListener('securityfailure', (e) => {
                console.log('Security failure:', e.detail.reason);
            });
            
            rfb.addEventListener('clipboard', (e) => {
                console.log('Clipboard event:', e.detail.text);
            });
            
            rfb.addEventListener('bell', () => {
                console.log('Bell event');
            });
            
            rfb.addEventListener('desktopname', (e) => {
                console.log('Desktop name:', e.detail.name);
            });
            
            rfb.addEventListener('capabilities', (e) => {
                console.log('Capabilities:', e.detail.capabilities);
            });
            
            // Handle window resize
            window.addEventListener('resize', () => {
                rfb.scaleViewport = true;
                rfb.resizeSession = true;
            });
        }
        
        // Initialize when page loads
        document.addEventListener('DOMContentLoaded', initVNC);
    </script>
</body>
</html>
EOF

# Create startup script with environment variable support
RUN mkdir -p /opt/scripts
COPY <<EOF /opt/scripts/start.sh
#!/bin/bash

# This script is kept for compatibility but services are now managed by supervisor
echo "VNC services are managed by supervisor"
echo "Configuration:"
echo "  VNC Host: \${VNC_HOST:-0.0.0.0}"
echo "  VNC Port: \${VNC_PORT:-6080}"
echo "  Backend Host: \${VNC_BACKEND_HOST:-localhost}"
echo "  Backend Port: \${VNC_BACKEND_PORT:-5900}"

# Keep container running
exec supervisord -c /etc/supervisor/supervisord.conf
EOF

RUN chmod +x /opt/scripts/start.sh

# Create supervisor config
COPY <<EOF /etc/supervisor/conf.d/novnc.conf
[supervisord]
nodaemon=true
user=root

[program:xvfb]
command=Xvfb :1 -screen 0 1024x768x16
autostart=true
autorestart=true
stdout_logfile=/var/log/xvfb.log
stderr_logfile=/var/log/xvfb.log

[program:openbox]
command=bash -c "DISPLAY=:1 openbox"
autostart=true
autorestart=true
stdout_logfile=/var/log/openbox.log
stderr_logfile=/var/log/openbox.log

[program:x11vnc]
command=bash -c "x11vnc -display :1 -nopw -listen \${VNC_BACKEND_HOST:-localhost} -xkb -ncache 10 -ncache_cr -rfbport \${VNC_BACKEND_PORT:-5900}"
autostart=true
autorestart=true
stdout_logfile=/var/log/x11vnc.log
stderr_logfile=/var/log/x11vnc.log

[program:novnc]
command=bash -c "/opt/novnc/utils/novnc_proxy --vnc \${VNC_BACKEND_HOST:-localhost}:\${VNC_BACKEND_PORT:-5900} --listen \${VNC_PORT:-6080} --web /opt/novnc"
autostart=true
autorestart=true
stdout_logfile=/var/log/novnc.log
stderr_logfile=/var/log/novnc.log

[program:firefox]
command=bash -c "DISPLAY=:1 firefox-esr"
autostart=true
autorestart=true
stdout_logfile=/var/log/firefox.log
stderr_logfile=/var/log/firefox.log
EOF

EXPOSE 6080 5900

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
