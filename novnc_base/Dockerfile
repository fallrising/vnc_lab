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

# Create startup script
RUN mkdir -p /opt/scripts
COPY <<EOF /opt/scripts/start.sh
#!/bin/bash
# Start Xvfb
Xvfb :1 -screen 0 1024x768x16 &

# Start window manager
DISPLAY=:1 openbox &

# Start x11vnc
x11vnc -display :1 -nopw -listen localhost -xkb -ncache 10 -ncache_cr -rfbport 5900 &

# Start noVNC
/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &

# Start Firefox
DISPLAY=:1 firefox-esr &

# Keep container running
wait
EOF

RUN chmod +x /opt/scripts/start.sh

# Create supervisor config
COPY <<EOF /etc/supervisor/conf.d/novnc.conf
[supervisord]
nodaemon=true
user=root

[program:novnc]
command=/opt/scripts/start.sh
autostart=true
autorestart=true
stdout_logfile=/var/log/novnc.log
stderr_logfile=/var/log/novnc.log
EOF

EXPOSE 6080 5900

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
