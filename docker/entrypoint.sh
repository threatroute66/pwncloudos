#!/bin/bash
set -e

# PWNCLOUDOS Docker Entrypoint Script
# This script initializes the container and starts VNC services

echo "======================================"
echo "  PWNCLOUDOS - Multi-Cloud Security"
echo "======================================"
echo ""

# Set default VNC password if not provided
VNC_PASSWORD=${VNC_PASSWORD:-omvia}
VNC_RESOLUTION=${VNC_RESOLUTION:-1920x1080}

# Function to setup VNC password
setup_vnc_password() {
    echo "Setting up VNC password..."
    mkdir -p /home/omvia/.vnc

    # Generate VNC password file using Python with proper DES encryption
    python3 -c "
import os
import sys
from Cryptodome.Cipher import DES

def vnc_crypt(password):
    '''Encrypt password for VNC using DES'''
    # VNC password must be exactly 8 bytes
    key = (password[:8] + '\\x00' * 8)[:8].encode('latin-1')

    # VNC uses a mirrored key (swap bits in each byte)
    def mirror(byte):
        result = 0
        for i in range(8):
            result |= ((byte >> i) & 1) << (7 - i)
        return result

    key = bytes([mirror(b) for b in key])

    # Create DES cipher
    cipher = DES.new(key, DES.MODE_ECB)

    # Encrypt a fixed challenge (VNC spec)
    challenge = b'\\x17\\x52\\x6b\\x06\\x23\\x4e\\x58\\x07'
    encrypted = cipher.encrypt(challenge)

    return encrypted

password = os.environ.get('VNC_PASSWORD', 'omvia')
encrypted = vnc_crypt(password)

with open('/home/omvia/.vnc/passwd', 'wb') as f:
    f.write(encrypted)
" 2>/dev/null || {
        # Fallback if pycrypto not available: use expect or manual method
        echo "Warning: Could not generate VNC password file with encryption"
        # Create a dummy password file - tigervncserver will prompt to set it
        touch /home/omvia/.vnc/passwd
    }

    chmod 600 /home/omvia/.vnc/passwd
    chown -R omvia:omvia /home/omvia/.vnc
}

# Function to create xstartup file
setup_xstartup() {
    echo "Configuring VNC xstartup..."
    cat > /home/omvia/.vnc/xstartup << 'EOF'
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

    chmod +x /home/omvia/.vnc/xstartup
    chown omvia:omvia /home/omvia/.vnc/xstartup
}

# Function to create desktop icons
setup_desktop_icons() {
    echo "Setting up desktop icons..."
    mkdir -p /home/omvia/Desktop

    # Create Firefox desktop launcher
    cat > /home/omvia/Desktop/firefox.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox Web Browser
Comment=Browse the World Wide Web
GenericName=Web Browser
Keywords=Internet;WWW;Browser;Web;Explorer
Exec=firefox-esr %u
Terminal=false
X-MultipleArgs=false
Icon=firefox-esr
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
EOF

    # Create Terminal desktop launcher
    cat > /home/omvia/Desktop/terminal.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal Emulator
Comment=Use the command line
TryExec=xfce4-terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Categories=System;TerminalEmulator;
StartupNotify=true
EOF

    # Make desktop launchers executable and trusted
    chmod +x /home/omvia/Desktop/*.desktop
    chown -R omvia:omvia /home/omvia/Desktop
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
    echo "User: omvia"
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

# Setup desktop icons
setup_desktop_icons

# Create necessary directories
mkdir -p /home/omvia/.config
mkdir -p /home/omvia/.local/share
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Fix permissions (only for critical files to avoid timeout on 200k+ files)
chown -R omvia:omvia /home/omvia/.vnc
chown -R omvia:omvia /home/omvia/.config 2>/dev/null || true

# Display connection information
display_info

# Execute the command passed to the container
exec "$@"
