FROM debian:bullseye-slim

# Install required packages in one layer to keep image small
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
    vim \
    htop \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x (required for gemini-cli)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install websockify

# Install ttyd for terminal access
RUN wget -O /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 \
    && chmod +x /usr/local/bin/ttyd

# Install cloudflared for tunnel access
RUN wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
    && dpkg -i cloudflared.deb \
    && rm cloudflared.deb

# Install Atlassian CLI
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -nv -O- https://acli.atlassian.com/gpg/public-key.asc | gpg --dearmor -o /etc/apt/keyrings/acli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/acli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/acli-archive-keyring.gpg] https://acli.atlassian.com/linux/deb stable main" > /etc/apt/sources.list.d/acli.list && \
    apt-get update && \
    apt-get install -y acli && \
    rm -rf /var/lib/apt/lists/*

# Install CLI tools via npm (only essential ones to keep lightweight)
RUN npm install -g @anthropic-ai/claude-code @google/gemini-cli

# Download and setup noVNC
RUN mkdir -p /opt/novnc && \
    curl -sSL https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xzf - --strip-components=1 -C /opt/novnc

# Add custom index.html for subdomain compatibility
COPY index.html /opt/novnc/index.html

# Create directories
RUN mkdir -p /opt/scripts /home/firefox-profile

# Create startup script
RUN cat > /opt/scripts/start.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting services..."

# Create log directory
mkdir -p /var/log/services

# Function to start service with restart capability
start_service_with_restart() {
    local service_name=$1
    local log_file=$2
    shift 2
    local cmd="$@"
    
    echo "Starting $service_name..."
    (
        while true; do
            echo "$(date): Starting $service_name..." >> "$log_file"
            $cmd >> "$log_file" 2>&1 || true
            echo "$(date): $service_name exited, restarting in 3 seconds..." >> "$log_file"
            sleep 3
        done
    ) &
    echo "$service_name started with auto-restart"
}

# Start Xvfb
echo "Starting Xvfb..."
Xvfb :1 -screen 0 1024x768x16 > /var/log/services/xvfb.log 2>&1 &
XVFB_PID=$!
echo "Xvfb started with PID: $XVFB_PID"
sleep 2

# Start window manager
echo "Starting openbox..."
DISPLAY=:1 openbox > /var/log/services/openbox.log 2>&1 &
OPENBOX_PID=$!
echo "Openbox started with PID: $OPENBOX_PID"
sleep 1

# Start x11vnc with auto-restart
start_service_with_restart "x11vnc" "/var/log/services/x11vnc.log" \
    x11vnc -display :1 -nopw -listen localhost -xkb -ncache 10 -ncache_cr \
           -rfbport 5900 -forever -shared -permitfiletransfer \
           -tightfilexfer -verbose
sleep 3

# Start noVNC with auto-restart
cd /opt/novnc
start_service_with_restart "noVNC" "/var/log/services/novnc.log" \
    ./utils/novnc_proxy --vnc localhost:5900 --listen 6080 --web /opt/novnc
sleep 2

# Start ttyd terminal
echo "Starting ttyd..."
ttyd -p 7681 -i 127.0.0.1 -W bash > /var/log/services/ttyd.log 2>&1 &
TTYD_PID=$!
echo "ttyd started with PID: $TTYD_PID"

# Start cloudflared if token is provided
if [ ! -z "$TUNNEL_TOKEN" ]; then
    echo "Starting cloudflared tunnel..."
    cloudflared tunnel run --token $TUNNEL_TOKEN > /var/log/services/cloudflared.log 2>&1 &
    CLOUDFLARED_PID=$!
    echo "cloudflared started with PID: $CLOUDFLARED_PID"
fi

# Start Firefox
echo "Starting Firefox..."
sleep 3
DISPLAY=:1 firefox-esr --new-instance --profile /home/firefox-profile \
         > /var/log/services/firefox.log 2>&1 &
FIREFOX_PID=$!
echo "Firefox started with PID: $FIREFOX_PID"

echo "All services started. Container ready."
echo "Log files available in /var/log/services/"

# Simple monitoring loop
while true; do
    sleep 60
    
    # Check if Xvfb is still running
    if ! kill -0 $XVFB_PID 2>/dev/null; then
        echo "$(date): Xvfb died, restarting container..." >> /var/log/services/monitor.log
        exit 1
    fi
    
    # Log status
    echo "$(date): Services running normally" >> /var/log/services/monitor.log
done
EOF

RUN chmod +x /opt/scripts/start.sh

# Create monitoring script for debugging
RUN cat > /opt/scripts/debug.sh << 'EOF'
#!/bin/bash
echo "=== VNC Debug Information ==="
echo "Date: $(date)"
echo ""

echo "=== Process Status ==="
ps aux | grep -E "(Xvfb|x11vnc|novnc|firefox|ttyd)" | grep -v grep
echo ""

echo "=== Port Status ==="
netstat -ln | grep -E "(5900|6080|7681)"
echo ""

echo "=== Recent X11VNC Logs ==="
if [ -f /var/log/services/x11vnc.log ]; then
    echo "Last 10 lines of x11vnc.log:"
    tail -10 /var/log/services/x11vnc.log
else
    echo "No x11vnc.log found"
fi
echo ""

echo "=== Recent noVNC Logs ==="
if [ -f /var/log/services/novnc.log ]; then
    echo "Last 10 lines of novnc.log:"
    tail -10 /var/log/services/novnc.log
else
    echo "No novnc.log found"
fi
echo ""

echo "=== System Resources ==="
free -h
df -h /tmp
echo ""

echo "=== X Display Info ==="
DISPLAY=:1 xdpyinfo 2>/dev/null | head -10 || echo "Cannot connect to X display"
EOF

RUN chmod +x /opt/scripts/debug.sh

# Create supervisor config - simplified single program approach
RUN cat > /etc/supervisor/conf.d/services.conf << 'EOF'
[supervisord]
nodaemon=true
user=root

[program:services]
command=/opt/scripts/start.sh
autostart=true
autorestart=true
stdout_logfile=/var/log/services.log
stderr_logfile=/var/log/services.log
EOF

# Create log file
RUN touch /var/log/services.log

# Create volume for Firefox profile persistence
VOLUME ["/home/firefox-profile"]

# Expose ports
EXPOSE 6080 5900 7681

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
