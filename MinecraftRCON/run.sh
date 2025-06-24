#!/usr/bin/env bash

set -e

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-1.21.92.1.zip"
SERVER_ZIP="$SERVER_DIR/server.zip"

echo "🟢 Iniciando script de inicialização do Minecraft Bedrock RCON"
mkdir -p "$SERVER_DIR"

# Baixa o servidor somente se não estiver presente
if [ ! -f "$SERVER_BIN" ]; then
  if [ ! -f "$SERVER_ZIP" ]; then
    echo "⏬ Baixando servidor Bedrock..."
    curl -L --progress-bar -o "$SERVER_ZIP" "$SERVER_URL" || {
      echo "❌ Erro ao baixar o servidor. Verifique a URL ou sua conexão."
      exit 1
    }
  else
    echo "📦 Arquivo server.zip já está presente. Pulando download."
  fi

  echo "📂 Extraindo arquivos..."
  unzip -o "$SERVER_ZIP" -d "$SERVER_DIR"
  chmod +x "$SERVER_BIN"
  rm "$SERVER_ZIP"
else
  echo "✅ Servidor já instalado em $SERVER_BIN"
fi

cd "$SERVER_DIR"

# Limpa o console do Add-on (funciona apenas no terminal real)
clear || true

echo "🟢 Iniciando servidor Minecraft em background..."
screen -dmS mc ./bedrock_server

echo "⏳ Aguardando o servidor subir..."
sleep 10

echo "🟢 Iniciando servidor RCON customizado..."
python3 /rcon_server.py &

wait -n
exit $?
