#!/usr/bin/env bash
set -e

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ ############### Iniciando script do Minecraft Bedrock RCON" ############### ]

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_ZIP="$SERVER_DIR/server.zip"

mkdir -p "$SERVER_DIR"

# Se existir o zip, extrai e apaga para atualizar o servidor
if [ -f "$SERVER_ZIP" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Arquivo encontrado. Extraindo para atualização..."
  unzip -o "$SERVER_ZIP" -d "$SERVER_DIR" | while IFS= read -r line; do
    echo -ne "[$(date '+%Y-%m-%d %H:%M:%S')] Extraindo arquivos...\r"
  done
  chmod +x "$SERVER_BIN"
  rm "$SERVER_ZIP"
  echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] Extração concluída! Arquivo removido."
fi

# Verifica se o servidor está disponível
if [ ! -f "$SERVER_BIN" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Arquivo não encontrado. Coloque server.zip para extrair."
  exit 1
fi

cd "$SERVER_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando servidor Minecraft..."

# Inicia com screen e log visível no Add-on
screen -dmS mc bash -c "./bedrock_server | tee /proc/1/fd/1"

# Aguarda o servidor subir
sleep 10

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando RCON personalizado..."
python3 /rcon_server.py &

# Espera ambos processos
wait -n
exit $?
