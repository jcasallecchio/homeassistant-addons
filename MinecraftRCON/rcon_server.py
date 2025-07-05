from flask import Flask, request, jsonify
import os
import subprocess
from waitress import serve
from datetime import datetime
import time

app = Flask(__name__)

LOG_FILE = "/share/minecraftRCON/server.log"
SCREEN_SESSION = "mc"

def screen_exists(session_name=SCREEN_SESSION):
    try:
        output = subprocess.check_output(["screen", "-ls"]).decode()
        return f"\t{session_name}" in output or f".{session_name}" in output
    except Exception:
        return False

def read_log_since(timestamp_str):
    """
    Lê o arquivo de log e retorna as linhas com timestamp maior que timestamp_str.
    Usa comparação lexicográfica da string do timestamp no formato '[YYYY-MM-DD HH:MM:SS:ms'
    """
    lines = []
    try:
        with open(LOG_FILE, "r") as f:
            for line in f:
                if len(line) < 25:
                    continue
                # Extrai o timestamp da linha do log, ex: [2025-07-04 21:13:13:813
                line_timestamp = line[0:25]
                if line_timestamp > timestamp_str:
                    lines.append(line.strip())
    except Exception:
        pass
    return lines

@app.route("/rcon", methods=["POST"])
def rcon():
    data = request.get_json()
    cmd = data.get("command", "").strip()

    if not cmd:
        return jsonify({"status": "error", "message": "Missing command"}), 400

    if not screen_exists(SCREEN_SESSION):
        return jsonify({"status": "error", "message": f"No active screen session named '{SCREEN_SESSION}'"}), 500

    try:
        # Marca o momento antes do comando ser enviado no formato exato do log
        timestamp_before = datetime.now().strftime("[%Y-%m-%d %H:%M:%S:%f")[:-3]  # até milissegundos, sem fechar colchete

        # Envia comando via screen
        os.system(f"screen -S {SCREEN_SESSION} -X stuff '{cmd}\r'")

        # Aguarda a resposta aparecer no log
        timeout = 5  # segundos para aguardar resposta
        interval = 0.2
        elapsed = 0
        response_lines = []

        while elapsed < timeout:
            time.sleep(interval)
            elapsed += interval
            new_lines = read_log_since(timestamp_before)
            if new_lines:
                response_lines = new_lines
                break

        response = '|'.join(line.strip() for line in response_lines if line.strip())

        return jsonify({"status": "ok", "message": f"Command sent: {cmd}", "response": response})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    print(f"[RCON] Servidor RCON iniciado na porta 19133")
    serve(app, host="0.0.0.0", port=19133)
