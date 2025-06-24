#!/usr/bin/env bash
set -e

echo "🟢 Iniciando script de inicialização do Minecraft Bedrock RCON"

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_ZIP="$SERVER_DIR/server.zip"

mkdir -p "$SERVER_DIR"

# Verifica se o servidor já foi extraído
if [ ! -f "$SERVER_BIN" ]; then
  if [ -f "$SERVER_ZIP" ]; then
    echo "📂 Extraindo servidor a partir de $SERVER_ZIP..."
    unzip -o "$SERVER_ZIP" -d "$SERVER_DIR"
    chmod +x "$SERVER_BIN"
    echo "✅ Extração concluída."
  else
    echo "❌ Arquivo $SERVER_ZIP não encontrado. Coloque-o na pasta antes de iniciar o add-on."
    exit 1
  fi
fi

cd "$SERVER_DIR"
echo "🚀 Iniciando servidor Minecraft..."
screen -dmS mc ./bedrock_server

sleep 10

echo "🔌 Iniciando RCON personalizado..."
python3 /rcon_server.py &

wait -n
exit $?
