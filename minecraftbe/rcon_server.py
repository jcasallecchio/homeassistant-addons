from flask import Flask, request, jsonify
import os

app = Flask(__name__)

@app.route("/rcon", methods=["POST"])
def rcon():
    data = request.get_json()
    cmd = data.get("command", "").strip()
    if not cmd:
        return jsonify({"status": "error", "message": "Missing command"}), 400
    try:
        os.system(f"screen -S mc -X stuff '{cmd}\r'")
        return jsonify({"status": "ok", "message": "Command sent"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=19133)
