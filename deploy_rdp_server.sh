#!/bin/bash

# Raspberry Pi Raspian Homeless Tech Remote Desktop Suite v1.0
# Support: https://www.youtube.com/@HomelessTechnology
# Purpose: High-performance RDP with two-way audio, Wayland support, and Network Turbo.

set -e

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Information & Disclaimer Screen ---
SHOW_DISCLAIMER() {
    clear
    cat <<EOF | more
################################################################################
#                                                                              #
#      Raspberry Pi Raspian Homeless Tech Remote Desktop Suite v1.0            #
#                https://www.youtube.com/@HomelessTechnology                   #
#                                                                              #
################################################################################

OVERVIEW:
This script automates the installation and configuration of a high-performance 
Remote Desktop Protocol (RDP) stack for the Raspberry Pi 5. It integrates 
modern components like Wayland, PipeWire, and FUSE to provide a "Standard VNC" 
replacement with features like two-way audio, drive redirection, and hardware 
acceleration support.

WHAT THIS SCRIPT DOES:
1. Installs xrdp and xorgxrdp with Wayland refinements.
2. Compiles a native PipeWire-xrdp audio bridge (in RAM to protect SD card).
3. Optimized network throughput and TCP buffers for 1080p/60fps streaming.
4. Enables Printer, Serial Port, and FUSE-based Drive Redirection.
5. Suppresses Polkit authentication popups for remote users.
6. Future-proofs for both Wayfire and Labwc compositors.

LIABILITY DISCLAIMER:
- This script is provided "AS-IS" without any warranty of any kind.
- Homeless Technology does NOT manufacture or maintain the underlying tools 
  (xrdp, PipeWire, CUPS, etc.) used in this suite.
- By running this script, you acknowledge that you are doing so at your own risk.
- We are NOT liable for any data loss, hardware damage, or security issues 
  that may arise from the use of this script or the tools it installs.
- For support regarding the individual tools, please contact the respective 
  developers and authors of those tools.
- This script is intended to make users' lives easier by bringing these 
  powerful tools together in a cohesive environment.

################################################################################
EOF
}

SHOW_DISCLAIMER

echo -e "${YELLOW}Do you accept the terms and conditions? (y/n)${NC}"
read -r acceptance
if [[ ! "$acceptance" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Exiting. Terms were not accepted.${NC}"
    exit 1
fi

echo -e "${GREEN}Terms accepted. Starting deployment...${NC}"

# --- Configuration ---
BUILD_DIR="/tmp/rdp_build"
XRDP_PW_REPO="https://github.com/neutrinolabs/pipewire-module-xrdp.git"
VIRTUAL_RES="1920x1080"

echo -e "${BLUE}Starting RDP Wrapper Deployment v1.5 for Raspberry Pi 5...${NC}"

# 0. Pre-Installation Cleanup (Idempotency)
echo -e "${BLUE}[0/6] Cleaning up previous build artifacts...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 1. Initial System Setup & Session Conflict Prevention
echo -e "${BLUE}[1/6] Installing dependencies and disabling auto-login...${NC}"
sudo apt update
sudo apt install -y \
    xrdp xorgxrdp \
    pipewire pipewire-audio-client-libraries \
    libpipewire-0.3-dev libspa-0.2-dev \
    build-essential git pkg-config \
    autoconf automake libtool \
    wl-clipboard \
    pavucontrol \
    avahi-daemon fuse3 \
    dbus-user-session \
    cups smbclient

# Disable auto-login to prevent "Black Screen" session conflicts
sudo raspi-config nonint do_boot_behaviour B3 

# Ensure FUSE is loaded
sudo modprobe fuse || true

# 2. PipeWire & Permissions
echo -e "${BLUE}[2/6] Configuring PipeWire & Permissions...${NC}"
sudo usermod -a -G pipewire,audio,video xrdp || true
systemctl --user enable pipewire pipewire-pulse || true
systemctl --user start pipewire pipewire-pulse || true
mkdir -p ~/.config/pipewire

# --- Ultimate Audio Stability (v1.5) ---
# Lock clock rate and quantum system-wide to prevent drift/scratchiness
sudo mkdir -p /etc/pipewire/pipewire.conf.d
sudo bash -c "cat > /etc/pipewire/pipewire.conf.d/20-xrdp-audio.conf <<EOF
context.properties = {
    default.clock.rate          = 48000
    default.clock.allowed-rates = [ 48000 ]
    default.clock.min-quantum   = 1024
    default.clock.max-quantum   = 1024
}
EOF"

# 3. Compiling pipewire-module-xrdp (tmpfs)
echo -e "${BLUE}[3/6] Building pipewire-module-xrdp...${NC}"
cd "$BUILD_DIR"
git clone "$XRDP_PW_REPO"
cd pipewire-module-xrdp
./bootstrap
./configure
make -j$(nproc)
sudo make install

# 4. Headless Resolution (Labwc & Wayfire Future-Proofing)
echo -e "${BLUE}[4/6] Configuring Wayland for Headless (Labwc/Wayfire)...${NC}"

# Labwc configuration
mkdir -p ~/.config/labwc
cat > ~/.config/labwc/autostart <<EOF
wlr-randr --output VNC-1 --mode $VIRTUAL_RES
EOF

# Wayfire configuration
WAYFIRE_CONFIG="/etc/wayfire/wayfire.ini"
if [ -f "$WAYFIRE_CONFIG" ]; then
    # Clean up old VNC-1 entry if exists (idempotency)
    sudo sed -i '/\[output:VNC-1\]/,+2d' "$WAYFIRE_CONFIG" || true
    sudo bash -c "cat >> $WAYFIRE_CONFIG <<EOF

[output:VNC-1]
mode = $VIRTUAL_RES
position = 0,0
EOF"
fi

# 5. Polkit Rules & Audio Autostart
echo -e "${BLUE}[5/6] Applying Polkit Rules & Audio Bridge...${NC}"
sudo mkdir -p /etc/polkit-1/localauthority/50-local.d/
sudo bash -c "cat > /etc/polkit-1/localauthority/50-local.d/rdp-manage.pkla <<EOF
[Allow Audio and Power for xrdp]
Identity=unix-user:*
Action=org.freedesktop.color-manager.*;org.freedesktop.login1.*;org.debian.pkla.libvirt.manage
ResultAny=yes
EOF"

mkdir -p ~/.config/autostart
# We remove the official one if it exists to avoid double-loading or conflicts
# then create our own that ensures pipewire is ready first.
rm -f ~/.config/autostart/pipewire-xrdp.desktop

cat > ~/.config/autostart/pipewire-bridge.desktop <<EOF
[Desktop Entry]
Type=Application
Name=PipeWire RDP Bridge
Exec=/usr/local/bin/gentle-pw-start.sh
EOF

sudo bash -c "cat > /usr/local/bin/gentle-pw-start.sh <<EOF
#!/bin/bash
# Wait for session to stabilize
sleep 3
# Ensure PipeWire services are running
systemctl --user start pipewire pipewire-pulse || true
# Explicitly load the xrdp pipewire module using official script
/usr/local/libexec/pipewire-module-xrdp/load_pw_modules.sh || true
# Fallback: Manual load if sink is still missing
if ! pactl list modules | grep -q xrdp; then
    # Try common module name
    pactl load-module libpipewire-module-xrdp || true
fi
# Force the default sink to RDP (xrdp-sink)
pactl set-default-sink xrdp-sink || true
# Force Real-Time priority for the current RDP-PipeWire session
renice -n -10 -p \$(pgrep -u \$USER pipewire) || true
EOF"
sudo chmod +x /usr/local/bin/gentle-pw-start.sh

# 6. Advanced Performance & Network Turbo
echo -e "${BLUE}[6/6] Finalizing Services & Network Turbo...${NC}"
# xrdp settings
sudo sed -i 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini
sudo sed -i 's/use_fastpath=both/use_fastpath=both/g' /etc/xrdp/xrdp.ini
sudo sed -i 's/^#tcp_send_buffer_bytes=32768/tcp_send_buffer_bytes=4194304/g' /etc/xrdp/xrdp.ini

# Clean up redundant session types (Xvnc, vnc-any, etc.) to force Xorg
# We keep [Xorg] and remove everything from [Xvnc] onwards
sudo sed -i '/^\[Xvnc\]/,$d' /etc/xrdp/xrdp.ini

# Re-add common [Xorg] entry just in case it was missing or messily handled
if ! grep -q "\[Xorg\]" /etc/xrdp/xrdp.ini; then
    sudo bash -c "cat >> /etc/xrdp/xrdp.ini <<EOF

[Xorg]
name=Xorg
lib=libxorgxrdp.so
username=ask
password=ask
ip=127.0.0.1
port=-1
code=20
EOF"
fi

# Clean up duplicate composition flags if they exist
sudo sed -i '/allow_desktop_composition=false/d' /etc/xrdp/xrdp.ini
sudo sed -i 's/allow_multimon=true/allow_multimon=true\nallow_desktop_composition=false/g' /etc/xrdp/xrdp.ini

# System network tweak
sudo sysctl -w net.core.wmem_max=8388608

sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon
sudo systemctl enable xrdp
sudo systemctl restart xrdp

echo -e "${GREEN}Deployment v1.5 (VNC-Killer / Homeless Tech) Complete!${NC}"
echo -e "${BLUE}REBOOT REQUIRED to apply B3 login mode and kernel tweaks.${NC}"
echo -e "${BLUE}Connect using rdp_launcher.py --tunnel to bypass firewalls.${NC}"
echo -e "${BLUE}Don't forget to visit: https://www.youtube.com/@HomelessTechnology${NC}"
