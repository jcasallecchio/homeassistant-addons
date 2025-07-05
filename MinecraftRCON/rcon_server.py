from flask import Flask, request, jsonify
import os
import subprocess
import time
from waitress import serve

app = Flask(__name__)

LOG_FILE = "/share/minecraftRCON/server.log"
LOG_OUTPUT = "/share/minecraftRCON/rcon_commands.log"

# Lista de comandos que geralmente NÃO têm resposta no server.log
SILENT_COMMANDS = [
    "give", "tp", "teleport", "gamemode", "setworldspawn", "spawnpoint",
    "effect", "clear", "title", "say", "tell", "whitelist", "op", "deop"
]

def log_action(msg):
    """Grava em log de arquivo e também imprime no console do addon"""
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    full_line = f"[{timestamp}] {msg}"
    print(full_line)
    with open(LOG_OUTPUT, "a") as log:
        log.write(full_line + "\n")

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

    # Envia o comando via screen
    try:
        os.system(f"screen -S mc -X stuff '{cmd}\r'")
        log_action(f"Comando enviado: {cmd}")
    except Exception as e:
        log_action(f"Erro ao enviar comando: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

    # Verifica se é comando silencioso
    if any(cmd.lower().startswith(s) for s in SILENT_COMMANDS):
        return jsonify({
            "status": "ok",
            "message": f"Command sent: {cmd}",
            "response": "No output expected from this command."
        })

    # Espera um pouco para o log ser atualizado
    time.sleep(1)

    # Lê as últimas linhas do server.log
    response_lines = []
    try:
        with open(LOG_FILE, "r") as f:
            lines = f.readlines()[-100:]
            for line in reversed(lines):
                if "INFO" in line and not line.strip().endswith("]:"):
                    response_lines.append(line.strip())
                    break
    except Exception as e:
        log_action(f"Erro ao ler server.log: {e}")
        return jsonify({"status": "error", "message": "Command sent, but failed to read server.log"}), 500

    response_text = response_lines[0] if response_lines else "No response found in server.log"

    return jsonify({
        "status": "ok",
        "message": f"Command sent: {cmd}",
        "response": response_text
    })

if __name__ == "__main__":
    log_action("Servidor RCON iniciado na porta 19133")
    serve(app, host="0.0.0.0", port=19133)
