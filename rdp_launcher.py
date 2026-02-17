import os
import subprocess
import time
import platform
import socket
import argparse
import tempfile
import atexit

# Raspberry Pi Raspian Homeless Tech Remote Desktop Suite v1.0
# Client-Side Launcher (v1.5 - Ultimate)
# Support: https://www.youtube.com/@HomelessTechnology

def check_latency(host, port=22):
    """Simple latency check."""
    start = time.time()
    try:
        with socket.create_connection((host, port), timeout=2):
            return (time.time() - start) * 1000
    except (socket.timeout, socket.error):
        return None

def wait_for_port(port, timeout=10):
    """Wait for a local port to become active."""
    start_time = time.time()
    while time.time() - start_time < timeout:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(('localhost', port)) == 0:
                return True
        time.sleep(0.5)
    return False

def start_ssh_tunnel(host, user="pi", local_port=3390):
    """Creates an SSH tunnel (Local -> Pi 3389)."""
    # Parse user@host if provided in the host string
    if "@" in host:
        user, host = host.split("@", 1)

    print(f"Opening secure SSH tunnel: localhost:{local_port} -> {host}:3389 as user '{user}'...")
    
    # On Windows, -f (background) is often unsupported or finicky. 
    # We use subprocess.Popen without -f and manage it via the Python process.
    ssh_cmd = ["ssh", "-L", f"{local_port}:localhost:3389", f"{user}@{host}", "-N"]
    
    try:
        # Start SSH. If it needs a password, it will prompt in the current terminal.
        tunnel_proc = subprocess.Popen(ssh_cmd)
        
        print("Waiting for tunnel to establish (you may need to enter your password)...")
        if wait_for_port(local_port):
            print(f"Tunnel established on port {local_port}!")
            return f"localhost:{local_port}", tunnel_proc
        else:
            print("Error: Tunnel timed out. Check your credentials/connection.")
            tunnel_proc.terminate()
            return None, None
    except Exception as e:
        print(f"Error: {e}")
        return None, None

def generate_rdp_content(host):
    """Generates the ULTIMATE RDP configuration."""
    return f"""full address:s:{host}
prompt for credentials:i:1
screen mode id:i:2
session bpp:i:24
compression:i:1
# --- AUDIO ---
audiomode:i:0
audiocapturemode:i:1
# --- REDIRECTION (The VNC Killers) ---
redirectdrives:i:1
drivestoredirect:s:*
redirectprinters:i:1
redirectcomports:i:1
redirectsmartcards:i:1
# --- PERFORMANCE ---
enablecopyax64:i:1
connection type:i:6
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
# --- UX ---
keyboardhook:i:2
autoreconnection enabled:i:1
authentication level:i:2
"""

def launch_rdp(host, user="pi", tunnel=False):
    print(f"################################################################################")
    print(f"#                                                                              #")
    print(f"#      Raspberry Pi Raspian Homeless Tech Remote Desktop Suite v1.0            #")
    print(f"#                https://www.youtube.com/@HomelessTechnology                   #")
    print(f"#                                                                              #")
    print(f"################################################################################")
    
    rdp_target = host
    tunnel_proc = None
    
    if tunnel:
        rdp_target, tunnel_proc = start_ssh_tunnel(host, user=user)
        if not rdp_target: return

    # Use a temporary file for the .rdp config
    with tempfile.NamedTemporaryFile(suffix=".rdp", mode="w", delete=False) as tmp:
        tmp.write(generate_rdp_content(rdp_target))
        tmp_path = tmp.name

    def cleanup():
        try: os.remove(tmp_path)
        except: pass
        if tunnel_proc:
            tunnel_proc.terminate()
    atexit.register(cleanup)

    print(f"Launching ULTIMATE RDP session for {rdp_target}...")
    if platform.system() == "Windows":
        subprocess.Popen(["mstsc", tmp_path])
    elif platform.system() == "Darwin":
        subprocess.Popen(["open", tmp_path])
    else:
        print(f"Please use an RDP client with the generated file: {tmp_path}")
        # Keep file for manual use on Linux
        atexit.unregister(cleanup)
    
    # Stay alive while RDP is running if we have a tunnel
    if tunnel_proc:
        print("Keep this terminal open to maintain the secure tunnel.")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nClosing tunnel and exiting...")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Homeless Tech RDP Launcher v1.5")
    parser.add_argument("host", nargs="?", default="raspberrypi.local")
    parser.add_argument("--user", default="pi")
    parser.add_argument("--tunnel", action="store_true")
    launch_rdp(parser.parse_args().host, user=parser.parse_args().user, tunnel=parser.parse_args().tunnel)
