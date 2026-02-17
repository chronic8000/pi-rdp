# RPi 5 RDP Wrapper - The "VNC Killer" (v1.5)

Tired of lagging, no-audio VNC on your Pi 5? This is a one-script solution for a high-performance RDP suite that fixes audio, network bottlenecks, and Wayland compatibility.

Support: [Homeless Technology on YouTube](https://www.youtube.com/@HomelessTechnology)

---

## ⚡ Why This Is Better Than VNC
- **Crystal Clear Audio**: Two-way audio support (Mic + Speakers) powered by PipeWire.
- **Bi-directional Clipboard**: Copy-paste text and images between Pi and laptop like it's local.
- **Native Drive Mapping**: Windows drives appear on your Pi for easy file transfers.
- **Network Turbo**: Optimized 4MB TCP buffers for smooth 1080p/60fps playback.
- **Zero-Conf Networking**: Connect via `raspberrypi.local` or your custom hostname.
- **Hardware Future-Proof**: Optimized for Labwc and Wayfire on RPi 5.

## 🛠️ Installation (On your Pi)

Run this on your Raspberry Pi 5 terminal to start the install:

```bash
wget https://raw.githubusercontent.com/chronic8000/pi-rdp/main/deploy_rdp_server.sh
chmod +x deploy_rdp_server.sh
./deploy_rdp_server.sh
```
*Note: A reboot is required after the script finished to apply the auto-login and network tweaks.*

## 🖥️ Usage (From your Computer)

While you can use standard `mstsc` (Remote Desktop Connection), we've included a **robust Python launcher** that handles SSH tunneling and latency checks automatically.

```bash
python rdp_launcher.py user@hostname.local --tunnel
```

## 🔊 Getting Sound Working
If you don't hear audio immediately:
1. **Wait 5 seconds**: The bridge takes a moment to initialize after the desktop loads.
2. **Select Sink**: Right-click the volume icon on the Pi taskbar and pick **xrdp-sink**.
3. **Optimized playback**: We've tweaked PipeWire quantum settings for the smoothest playback possible over RDP.

## 🗑️ Reverting / Uninstallation
Need to nuke the settings and go back to stock?
```bash
chmod +x uninstall_rdp_server.sh
./uninstall_rdp_server.sh
```

## 📜 Disclaimer
This comes from **Homeless Technology** "as-is". We don't maintain the underlying open-source tools (xrdp, PipeWire, etc.), but we've brought them together to make them work properly on the RPi 5. Use it at your own risk.

---
Follow the journey: [YouTube @HomelessTechnology](https://www.youtube.com/@HomelessTechnology)
