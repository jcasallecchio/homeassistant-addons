#!/usr/bin/env bash
set -e

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-1.21.92.1.zip"

mkdir -p "$SERVER_DIR"

if [ ! -f "$SERVER_BIN" ]; then
  echo "⏬ Baixando servidor Bedrock (usar HTTP/1.1)..."
  curl --http1.1 -sSL -o "$SERVER_DIR/server.zip" "$SERVER_URL"
  unzip -o "$SERVER_DIR/server.zip" -d "$SERVER_DIR"
  chmod +x "$SERVER_BIN"
  rm "$SERVER_DIR/server.zip"
fi

cd "$SERVER_DIR"
screen -dmS mc ./bedrock_server
sleep 10
python3 /rcon_server.py &
wait -n
exit $?
