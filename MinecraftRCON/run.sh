#!/usr/bin/env bash
set -e

echo -e "\n\n================= 🎮 INICIANDO ADD-ON =================\n"

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-1.21.92.1.zip"

mkdir -p "$SERVER_DIR"

if [ ! -f "$SERVER_BIN" ]; then
  echo "⏬ Baixando servidor Bedrock (usar HTTP/1.1)..."
  curl --http1.1 -L --progress-bar -o "$SERVER_DIR/server.zip" "$SERVER_URL"
  
  echo "📂 Extraindo arquivos..."
  unzip -o "$SERVER_DIR/server.zip" -d "$SERVER_DIR"

  echo "🔒 Tornando servidor executável..."
  chmod +x "$SERVER_BIN"

  echo "🧹 Limpando arquivo zip..."
  rm "$SERVER_DIR/server.zip"
else
  echo "✅ Servidor já está presente em $SERVER_BIN"
fi

cd "$SERVER_DIR"

echo "🚀 Iniciando servidor em screen..."
screen -dmS mc ./bedrock_server

echo "🕒 Aguardando servidor iniciar..."
sleep 10

echo "🔌 Iniciando servidor RCON Flask..."
python3 /rcon_server.py &

wait -n
exit $?
