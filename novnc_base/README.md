# novnc_base - Basic VNC Desktop Environment

A lightweight VNC desktop environment based on Debian Bullseye with noVNC support for web-based remote desktop access.

## Overview

This container provides a basic remote desktop environment with:
- Debian Bullseye slim base image
- noVNC 1.4.0 for web-based VNC access
- x11vnc server for VNC connectivity
- Firefox ESR browser
- Openbox window manager
- Supervisor for process management

## Features

- **Web-based Access**: Access desktop through any modern web browser
- **Lightweight**: Based on Debian Bullseye slim for minimal resource usage
- **Firefox Browser**: Pre-installed Firefox ESR for web browsing
- **Process Management**: Supervisor ensures all services stay running
- **No Authentication**: Simple setup without password requirements (for development/testing)

## Quick Start

### Build the Image

```bash
docker build -t vnc-base .
```

### Basic Run

```bash
docker run -d \
  --name vnc-base \
  -p 6080:6080 \
  -p 5900:5900 \
  vnc-base
```

### Access the Desktop

- **Web Browser**: Open `http://localhost:6080` in your browser
- **VNC Client**: Connect to `localhost:5900` using any VNC client

## Advanced Usage

### With Custom Ports

```bash
docker run -d \
  --name vnc-base \
  -p 8080:6080 \
  -p 5901:5900 \
  vnc-base
```

### With Resource Limits

```bash
docker run -d \
  --name vnc-base \
  -p 6080:6080 \
  -p 5900:5900 \
  --memory="1g" \
  --cpus="1.0" \
  vnc-base
```

### With Volume Mounts

```bash
docker run -d \
  --name vnc-base \
  -p 6080:6080 \
  -p 5900:5900 \
  -v $(pwd)/shared:/home/shared \
  vnc-base
```

## Container Details

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 6080 | noVNC | Web VNC client interface |
| 5900 | x11vnc | Traditional VNC server |

### Services

The container runs the following services managed by Supervisor:

1. **Xvfb**: Virtual framebuffer for X11
2. **Openbox**: Window manager
3. **x11vnc**: VNC server
4. **noVNC**: Web VNC proxy
5. **Firefox**: Web browser

### File Structure

```
/opt/novnc/          # noVNC installation
/opt/scripts/        # Startup and management scripts
/etc/supervisor/     # Supervisor configuration
```

## Environment Variables

This container doesn't use environment variables for configuration. All settings are hardcoded for simplicity.

## Troubleshooting

### Check Container Status

```bash
# View container logs
docker logs vnc-base

# Check if container is running
docker ps | grep vnc-base

# Access container shell
docker exec -it vnc-base bash
```

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using the port
   lsof -i :6080
   
   # Use different ports
   docker run -d --name vnc-base -p 8080:6080 -p 5901:5900 vnc-base
   ```

2. **Container Won't Start**
   ```bash
   # Check detailed logs
   docker logs vnc-base
   
   # Check system resources
   docker stats vnc-base
   ```

3. **VNC Connection Issues**
   - Ensure ports are correctly mapped
   - Check firewall settings
   - Verify container is running

### Debug Commands

```bash
# Check service status inside container
docker exec vnc-base supervisorctl status

# View X11 display info
docker exec vnc-base DISPLAY=:1 xdpyinfo

# Check network connections
docker exec vnc-base netstat -ln
```

## Development

### Customizing the Image

1. **Add Software Packages**
   ```dockerfile
   RUN apt-get update && apt-get install -y \
       your-package-name \
       && rm -rf /var/lib/apt/lists/*
   ```

2. **Modify Startup Script**
   Edit `/opt/scripts/start.sh` in the Dockerfile to customize startup behavior.

3. **Add Custom Files**
   ```dockerfile
   COPY your-file /path/in/container
   ```

### Building Custom Variants

```bash
# Build with custom tag
docker build -t my-vnc-base .

# Build with different base image
# Edit FROM line in Dockerfile
```

## Security Considerations

⚠️ **Warning**: This container is designed for development and testing environments. For production use:

1. **Add Authentication**: Implement VNC password protection
2. **Network Security**: Use reverse proxy or VPN
3. **Resource Limits**: Set appropriate memory and CPU limits
4. **Regular Updates**: Keep base image updated

## Use Cases

- **Development Environment**: Quick setup for remote development
- **Testing**: Browser testing in isolated environment
- **Learning**: Educational purposes for VNC/remote desktop concepts
- **Demo**: Demonstrating web-based remote desktop capabilities

## Related Projects

- [novnc_llm_cli](../novnc_llm_cli/): Enhanced version with AI tools
- [novnc_tool](../novnc_tool/): Tool-focused environment

## License

This project is part of the VNC Lab and follows the same MIT license. 