#!/usr/bin/env bash
set -e

# Cores ANSI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}[ ############### Iniciando Minecraft Bedrock RCON ############### ]"

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_ZIP="$SERVER_DIR/server.zip"
BACKUP_DIR="$SERVER_DIR/backups"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
BACKUP_TARGET="$BACKUP_DIR/backup-$TIMESTAMP"

mkdir -p "$SERVER_DIR"
mkdir -p "$BACKUP_DIR"

# Se existir o zip, extrai e apaga para atualizar o servidor
if [ -f "$SERVER_ZIP" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Backup de segurança antes da atualização..."

  mkdir -p "$BACKUP_TARGET"

  for item in worlds behavior_packs resource_packs structures server.properties permissions.json allowlist.json; do
    if [ -e "$SERVER_DIR/$item" ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Salvando $item..."
      cp -r "$SERVER_DIR/$item" "$BACKUP_TARGET/"
    fi
  done

  total=$(unzip -l "$SERVER_ZIP" | grep -E '^[ ]+[0-9]' | wc -l)
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Arquivo server.zip encontrado, iniciando extração..."
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Extraindo arquivos... Total: $total"
  
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

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Extração concluída! Restaurando arquivos do backup..."

  for item in worlds behavior_packs resource_packs structures server.properties permissions.json allowlist.json; do
    if [ -e "$BACKUP_TARGET/$item" ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restaurando $item..."
      rm -rf "$SERVER_DIR/$item"
      cp -r "$BACKUP_TARGET/$item" "$SERVER_DIR/"
    fi
  done

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Removendo $SERVER_ZIP"
  chmod +x "$SERVER_BIN"
  rm "$SERVER_ZIP"
fi

if [ ! -f "$SERVER_BIN" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}Arquivo não encontrado. Coloque server.zip para extrair."
  exit 1
fi

cd "$SERVER_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Iniciando servidor Minecraft..."

screen -dmS mc bash -c "./bedrock_server | tee /proc/1/fd/1"

sleep 10

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Iniciando RCON personalizado..."
python3 /rcon_server.py &

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}Minecraft Bedrock RCON Server Online..."

wait
exit $?
