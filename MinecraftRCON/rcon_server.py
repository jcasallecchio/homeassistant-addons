from flask import Flask, request, jsonify
import os
import subprocess
import time
from waitress import serve

app = Flask(__name__)

# Caminhos de log
SERVER_LOG = "/share/minecraftRCON/server.log"
COMMAND_LOG = "/share/minecraftRCON/rcon_commands.log"

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
        # Envia o comando via screen
        os.system(f"screen -S mc -X stuff '{cmd}\r'")

        # Log do comando enviado
        timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
        log_entry = f"[{timestamp}] Comando enviado: {cmd}\n"
        with open(COMMAND_LOG, "a") as f:
            f.write(log_entry)

        # Espera um momento para o servidor responder no log
        time.sleep(1.5)

        response_lines = []
        if os.path.exists(SERVER_LOG):
            with open(SERVER_LOG, "r") as f:
                lines = f.readlines()[-30:]  # últimas 30 linhas

                # Filtra por resposta típica do comando "list"
                for line in lines:
                    if "There are" in line or "players online" in line:
                        response_lines.append(line.strip())

        response_text = "\n".join(response_lines) if response_lines else "Sem resposta detectada."

        return jsonify({
            "status": "ok",
            "message": f"Command sent: {cmd}",
            "response": response_text
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    print("[RCON] Servidor RCON iniciado na porta 19133")
    serve(app, host="0.0.0.0", port=19133)
