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

# Add custom index.html for subdomain compatibility
COPY index.html /opt/novnc/index.html

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
