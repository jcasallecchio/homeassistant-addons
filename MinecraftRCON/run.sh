#!/usr/bin/env bash
set -e

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando script do Minecraft Bedrock RCON"

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_ZIP="$SERVER_DIR/server.zip"

mkdir -p "$SERVER_DIR"

# Se existir o zip, extrai e apaga para atualizar o servidor
if [ -f "$SERVER_ZIP" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Arquivo encontrado. Contando arquivos..."
  total=$(unzip -l "$SERVER_ZIP" | grep -E '^[ ]+[0-9]' | wc -l)
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Total de arquivos a extrair: $total"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando extração..."

  count=0
  last_percent=0
  unzip -o "$SERVER_ZIP" -d "$SERVER_DIR" | while read -r line; do
    if echo "$line" | grep -q "inflating:"; then
      count=$((count + 1))
      percent=$((count * 100 / total))
      if [ "$percent" -ne "$last_percent" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Extraindo arquivos... $percent%"
        last_percent=$percent
      fi
    fi
  done
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Extração concluída! Removendo $SERVER_ZIP"
  chmod +x "$SERVER_BIN"
  rm "$SERVER_ZIP"
fi

# Verifica se o servidor está disponível
if [ ! -f "$SERVER_BIN" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Arquivo não encontrado. Coloque server.zip para extrair."
  exit 1
fi

cd "$SERVER_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando servidor Minecraft..."

"$SERVER_BIN" &

sleep 10

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando RCON personalizado..."
python3 /rcon_server.py &

wait -n
exit $?
