#!/bin/bash

# Raspberry Pi Raspian Homeless Tech Remote Desktop Suite - Uninstaller
# Support: https://www.youtube.com/@HomelessTechnology

set -e

# --- Colors ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}Starting Uninstallation of Homeless Tech RDP Suite...${NC}"

# 1. Disable and Stop Services
echo -e "${BLUE}Stopping and disabling xrdp...${NC}"
sudo systemctl stop xrdp || true
sudo systemctl disable xrdp || true

# 2. Remove PipeWire Autostart Bridge
echo -e "${BLUE}Removing PipeWire autostart bridge...${NC}"
rm -f ~/.config/autostart/pipewire-bridge.desktop
sudo rm -f /usr/local/bin/gentle-pw-start.sh

# 3. Clean up Wayland Configurations (Labwc & Wayfire)
echo -e "${BLUE}Cleaning up Wayland configurations...${NC}"
rm -f ~/.config/labwc/autostart

WAYFIRE_CONFIG="/etc/wayfire/wayfire.ini"
if [ -f "$WAYFIRE_CONFIG" ]; then
    sudo sed -i '/\[output:VNC-1\]/,+2d' "$WAYFIRE_CONFIG" || true
fi

# 4. Remove Polkit Rules
echo -e "${BLUE}Removing Polkit rules...${NC}"
sudo rm -f /etc/polkit-1/localauthority/50-local.d/rdp-manage.pkla

# 5. Revert xrdp.ini changes (optional, but cleaner)
echo -e "${BLUE}Reverting xrdp.ini settings...${NC}"
sudo sed -i 's/max_bpp=24/max_bpp=32/g' /etc/xrdp/xrdp.ini || true
sudo sed -i '/allow_desktop_composition=false/d' /etc/xrdp/xrdp.ini || true

# 6. Revert auto-login (optional - user might want to keep it)
echo -e "${BLUE}Note: Desktop auto-login (B3 mode) was not reverted automatically.${NC}"
echo -e "${BLUE}Use 'sudo raspi-config' if you wish to re-enable auto-login.${NC}"

echo -e "${GREEN}Uninstallation Complete!${NC}"
echo -e "${BLUE}Underlying packages (xrdp, pipewire, etc.) were NOT removed to prevent breaking other dependencies.${NC}"
echo -e "${BLUE}If you wish to remove them, use: sudo apt purge xrdp pipewire-audio-client-libraries${NC}"
