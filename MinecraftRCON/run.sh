#!/usr/bin/env bash
set -e

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando script de inicialização do Minecraft Bedrock RCON"

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_ZIP="$SERVER_DIR/server.zip"

mkdir -p "$SERVER_DIR"

# Se existir o zip, extrai e apaga para atualizar o servidor
if [ -f "$SERVER_ZIP" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Arquivo $SERVER_ZIP encontrado. Extraindo para atualizar o servidor..."
  unzip -o "$SERVER_ZIP" -d "$SERVER_DIR"
  chmod +x "$SERVER_BIN"
  rm "$SERVER_ZIP"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Extração concluída e $SERVER_ZIP removido."
fi

# Verifica se o servidor está disponível
if [ ! -f "$SERVER_BIN" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Arquivo $SERVER_BIN não encontrado. Coloque server.zip para extrair."
  exit 1
fi

cd "$SERVER_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando servidor Minecraft..."

# Inicia o servidor no primeiro plano, com logs visíveis no container
"$SERVER_BIN" &

# Aguarda o servidor subir
sleep 10

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando RCON personalizado..."
python3 /rcon_server.py &

# Espera ambos processos
wait -n
exit $?
