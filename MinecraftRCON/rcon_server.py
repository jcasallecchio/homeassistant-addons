from flask import Flask, request, jsonify
import os
import subprocess

app = Flask(__name__)

@app.route("/rcon", methods=["POST"])
def rcon():
    data = request.get_json()
    cmd = data.get("command", "").strip()

    if not cmd:
        return jsonify({"status": "error", "message": "Missing command"}), 400

    try:
        # Encontra o PID do processo do servidor
        pid = subprocess.check_output(["pgrep", "-f", "bedrock_server"]).decode().strip()
        stdin_path = f"/proc/{pid}/fd/0"

        # Escreve diretamente no stdin
        with open(stdin_path, "w") as f:
            f.write(cmd + "\n")

        return jsonify({"status": "ok", "message": f"Command '{cmd}' sent to server"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=19133)
