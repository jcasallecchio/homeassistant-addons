#!/usr/bin/env bash

set -e

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-1.21.92.1.zip"

# Cria diretório se não existir
mkdir -p "$SERVER_DIR"

# Baixa e extrai o servidor se não estiver presente
if [ ! -f "$SERVER_BIN" ]; then
  curl -sSL -o "$SERVER_DIR/server.zip" "$SERVER_URL"
  unzip -o "$SERVER_DIR/server.zip" -d "$SERVER_DIR"
  chmod +x "$SERVER_BIN"
  rm "$SERVER_DIR/server.zip"
fi

cd "$SERVER_DIR"

# Inicia o servidor em uma sessão do screen
screen -dmS mc ./bedrock_server

# Aguarda o servidor iniciar
sleep 10

# Inicia o RCON personalizado
python3 /rcon_server.py &

wait -n
exit $?
