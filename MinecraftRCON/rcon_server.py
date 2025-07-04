from flask import Flask, request, jsonify
import os
import subprocess
from waitress import serve
from datetime import datetime

app = Flask(__name__)

LOG_FILE = "/share/minecraftRCON/rcon_commands.log"  # caminho para log

def log_command(ip, command, status):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"[{timestamp}] IP: {ip} | CMD: {command} | STATUS: {status}\n"
    with open(LOG_FILE, "a") as f:
        f.write(log_line)

def screen_exists(session_name="mc"):
    try:
        output = subprocess.check_output(["screen", "-ls"]).decode()
        return f"\t{session_name}" in output or f".{session_name}" in output
    except Exception:
        return False

@app.route("/rcon", methods=["POST"])
def rcon():
    data = request.get_json()
    cmd = data.get("command", "").strip()
    client_ip = request.remote_addr

    if not cmd:
        log_command(client_ip, "EMPTY_COMMAND", "ERROR: Missing command")
        return jsonify({"status": "error", "message": "Missing command"}), 400

    if not screen_exists("mc"):
        log_command(client_ip, cmd, "ERROR: No active screen")
        return jsonify({"status": "error", "message": "No active screen session named 'mc'"}), 500

    try:
        os.system(f"screen -S mc -X stuff '{cmd}\r'")
        log_command(client_ip, cmd, "OK")
        return jsonify({"status": "ok", "message": f"Command sent: {cmd}"})
    except Exception as e:
        log_command(client_ip, cmd, f"ERROR: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    print("[RCON] Servidor RCON iniciado na porta 19133")
    serve(app, host="0.0.0.0", port=19133)
