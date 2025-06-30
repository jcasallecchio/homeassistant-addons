from flask import Flask, request, jsonify
import os
import subprocess
from waitress import serve

app = Flask(__name__)

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

    if not cmd:
        return jsonify({"status": "error", "message": "Missing command"}), 400

    if not screen_exists("mc"):
        return jsonify({"status": "error", "message": "No active screen session named 'mc'"}), 500

    try:
        os.system(f"screen -S mc -X stuff '{cmd}\r'")
        return jsonify({"status": "ok", "message": f"Command sent: {cmd}"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    print("[RCON] Servidor RCON iniciado na porta 191188")
    serve(app, host="0.0.0.0", port=19188)
