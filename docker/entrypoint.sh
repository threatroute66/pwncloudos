#!/bin/bash
set -e

# PWNCLOUDOS Docker Entrypoint Script
# This script initializes the container and starts VNC services

echo "======================================"
echo "  PWNCLOUDOS - Multi-Cloud Security"
echo "======================================"
echo ""

# Set default VNC password if not provided
VNC_PASSWORD=${VNC_PASSWORD:-pwnedlabs}
VNC_RESOLUTION=${VNC_RESOLUTION:-1920x1080}

# Function to setup VNC password
setup_vnc_password() {
    echo "Setting up VNC password..."
    mkdir -p /home/pwncloudos/.vnc
    echo "${VNC_PASSWORD}" | vncpasswd -f > /home/pwncloudos/.vnc/passwd
    chmod 600 /home/pwncloudos/.vnc/passwd
    chown -R pwncloudos:pwncloudos /home/pwncloudos/.vnc
}

# Function to create xstartup file
setup_xstartup() {
    echo "Configuring VNC xstartup..."
    cat > /home/pwncloudos/.vnc/xstartup << 'EOF'
#!/bin/sh
# PWNCLOUDOS VNC Startup Script

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Start D-Bus
if [ -x /usr/bin/dbus-launch ]; then
    eval `dbus-launch --sh-syntax --exit-with-session`
fi

# Set background
xsetroot -solid grey

# Start XFCE4 desktop environment
exec startxfce4
EOF

    chmod +x /home/pwncloudos/.vnc/xstartup
    chown pwncloudos:pwncloudos /home/pwncloudos/.vnc/xstartup
}

# Function to display connection information
display_info() {
    echo ""
    echo "======================================"
    echo "  Container Started Successfully!"
    echo "======================================"
    echo ""
    echo "VNC Access:"
    echo "  VNC Viewer: localhost:5901"
    echo "  Password: ${VNC_PASSWORD}"
    echo ""
    echo "noVNC Web Access:"
    echo "  URL: http://localhost:6080/vnc.html"
    echo "  Password: ${VNC_PASSWORD}"
    echo ""
    echo "Desktop Environment: XFCE4"
    echo "Resolution: ${VNC_RESOLUTION}"
    echo "User: pwncloudos"
    echo ""
    echo "======================================"
    echo "  Tools Location:"
    echo "======================================"
    echo "  AWS Tools: /opt/aws_tools/"
    echo "  Azure Tools: /opt/azure_tools/"
    echo "  GCP Tools: /opt/gcp_tools/"
    echo "  Multi-Cloud: /opt/multi_cloud_tools/"
    echo "  PowerShell: /opt/ps_tools/"
    echo "  Code Scanning: /opt/code_scanning/"
    echo "  Cracking: /opt/cracking_tools/"
    echo ""
    echo "======================================"
}

# Setup VNC
setup_vnc_password
setup_xstartup

# Create necessary directories
mkdir -p /home/pwncloudos/.config
mkdir -p /home/pwncloudos/.local/share
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Fix permissions
chown -R pwncloudos:pwncloudos /home/pwncloudos

# Display connection information
display_info

# Execute the command passed to the container
exec "$@"
