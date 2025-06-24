#!/usr/bin/env bash

set -e

echo "* Iniciando script de inicialização do Minecraft Bedrock RCON"

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-1.21.92.1.zip"
SERVER_ZIP="$SERVER_DIR/server.zip"

# Cria diretório se não existir
mkdir -p "$SERVER_DIR"

# Baixa e extrai o servidor se não estiver presente
if [ ! -f "$SERVER_BIN" ]; then
  echo "* Baixando servidor Bedrock com wget..."
  wget -O "$SERVER_ZIP" "$SERVER_URL" || {
    echo "* Erro ao baixar o servidor. Verifique a URL ou sua conexão."
    exit 1
  }

  echo "* Extraindo arquivos..."
  unzip -o "$SERVER_ZIP" -d "$SERVER_DIR"
  chmod +x "$SERVER_BIN"
  rm "$SERVER_ZIP"
fi

cd "$SERVER_DIR"

echo "* Iniciando servidor em sessão screen"
screen -dmS mc ./bedrock_server

# Aguarda o servidor iniciar
sleep 10

echo "* Iniciando RCON personalizado"
python3 /rcon_server.py &

wait -n
exit $?
