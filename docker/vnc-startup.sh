#!/bin/bash
set -e

# PWNCLOUDOS VNC Startup Script
# Starts VNC server and noVNC websocket proxy

VNC_PORT=${VNC_PORT:-5901}
NOVNC_PORT=${NOVNC_PORT:-6080}
VNC_RESOLUTION=${VNC_RESOLUTION:-1920x1080}
DISPLAY=${DISPLAY:-:1}

echo "Starting PWNCLOUDOS VNC services..."

# Kill any existing VNC servers
su - pwncloudos -c "vncserver -kill ${DISPLAY} 2>/dev/null || true"

# Wait a moment
sleep 2

# Start VNC server as pwncloudos user
echo "Starting VNC server on display ${DISPLAY}..."
su - pwncloudos -c "vncserver ${DISPLAY} \
    -geometry ${VNC_RESOLUTION} \
    -depth 24 \
    -localhost no \
    -SecurityTypes VncAuth,TLSVnc"

# Wait for VNC server to start
echo "Waiting for VNC server to initialize..."
sleep 3

# Check if VNC server is running
if ! pgrep -f "Xtigervnc ${DISPLAY}" > /dev/null; then
    echo "ERROR: VNC server failed to start!"
    exit 1
fi

echo "VNC server started successfully on ${DISPLAY}"

# Start noVNC websockify proxy
echo "Starting noVNC websocket proxy on port ${NOVNC_PORT}..."

# Find noVNC installation
NOVNC_PATH=$(find /usr/share -name "novnc" -type d 2>/dev/null | head -1)

if [ -z "$NOVNC_PATH" ]; then
    echo "WARNING: noVNC not found. Web interface will not be available."
    echo "You can still connect via VNC client on port ${VNC_PORT}"
else
    # Start websockify in background
    websockify --web="${NOVNC_PATH}" ${NOVNC_PORT} localhost:${VNC_PORT} &
    WEBSOCKIFY_PID=$!
    echo "noVNC web interface started (PID: ${WEBSOCKIFY_PID})"
fi

echo ""
echo "======================================"
echo "  PWNCLOUDOS is ready!"
echo "======================================"
echo ""
echo "Connect via:"
echo "  - VNC client: localhost:${VNC_PORT}"
echo "  - Web browser: http://localhost:${NOVNC_PORT}/vnc.html"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Shutting down PWNCLOUDOS..."
    su - pwncloudos -c "vncserver -kill ${DISPLAY} 2>/dev/null || true"
    if [ ! -z "$WEBSOCKIFY_PID" ]; then
        kill $WEBSOCKIFY_PID 2>/dev/null || true
    fi
    echo "Goodbye!"
    exit 0
}

# Trap SIGTERM and SIGINT
trap cleanup SIGTERM SIGINT

# Keep container running and show VNC logs
echo "Monitoring VNC server logs (Ctrl+C to stop)..."
echo ""

# Tail VNC log file
VNC_LOG="/home/pwncloudos/.vnc/$(hostname)${DISPLAY}.log"

# Wait for log file to be created
for i in {1..10}; do
    if [ -f "$VNC_LOG" ]; then
        break
    fi
    sleep 1
done

if [ -f "$VNC_LOG" ]; then
    tail -f "$VNC_LOG" &
    TAIL_PID=$!
fi

# Wait indefinitely
wait
