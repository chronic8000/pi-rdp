# Raspberry Pi Raspian Homeless Tech Remote Desktop Suite v1.0

Building for the "VNC-Killer" experience, this suite provides an ultimate RDP environment for your Raspberry Pi 5.

Support: [YouTube @HomelessTechnology](https://www.youtube.com/@HomelessTechnology)

---

## 🚀 Features (Why it's better than VNC)

- **Native Two-Way Audio**: Hear Pi audio & use your laptop Mic on the Pi via PipeWire.
- **Bi-directional Clipboard**: Seamless copy-paste of text and images.
- **Drive Redirection**: Your local drives (C:, etc.) appear as folders on the Pi via FUSE.
- **Printer & Serial Redirection**: Print from the Pi to your local home printer.
- **Network Turbo**: Optimized TCP buffers for zero-lag 1080p/60fps streaming.
- **Future-Proof**: Supports both Labwc and Wayfire compositors.

## 🛠️ Installation

1. **On your Raspberry Pi 5**, run the following command:
   ```bash
   wget https://raw.githubusercontent.com/chronic8000/pi-rdp/main/deploy_rdp_server.sh
   chmod +x deploy_rdp_server.sh
   ./deploy_rdp_server.sh
   ```
2. **Accept the Disclaimer**: Read through the liability terms and press `y` to accept.
3. **Reboot**: A reboot is required to apply auto-login and network turbo tweaks.

## 🖥️ Usage

### From Windows (Native Client)
1. Ensure your Pi is on the same network.
2. Open "Remote Desktop Connection" (mstsc).
3. Connect to `raspberrypi.local` (or your Pi's hostname).

### Using the Homeless Tech Launcher (Recommended)
We provide an optimized Python launcher that handles latency checks and secure SSH tunneling.

```bash
python rdp_launcher.py [YOUR_PI_HOSTNAME].local --tunnel --user pi
```

## 🗑️ Uninstallation

To revert the changes made by this suite:
```bash
chmod +x uninstall_rdp_server.sh
./uninstall_rdp_server.sh
```

## 📜 Disclaimer
This script is provided "AS-IS" without warranty. Homeless Technology does not manufacture the underlying tools (xrdp, PipeWire, etc.). Use at your own risk. For support on specific tools, please contact their respective authors.

---
Visit [Homeless Technology on YouTube](https://www.youtube.com/@HomelessTechnology) for more Raspberry Pi 5 and tech guides!
