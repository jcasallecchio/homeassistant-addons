#!/usr/bin/env bash
set -e

# Cores ANSI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

log() {
  local color="$1"
  shift
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${color}$*${RESET}"
}

log $GREEN "[ ############### Iniciando Minecraft Bedrock RCON ############### ]"

SERVER_DIR="/share/minecraftRCON"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_ZIP="$SERVER_DIR/server.zip"
BACKUP_DIR="$SERVER_DIR/backups"
VERSION_FILE="$SERVER_DIR/version.txt"
LAST_VERSION_FILE="$SERVER_DIR/lastversion.txt"
LATEST_URL="https://www.minecraft.net/en-us/download/server/bedrock"

mkdir -p "$SERVER_DIR"
mkdir -p "$BACKUP_DIR"

SECONDS=0

# Detectar última versão online
LATEST_VERSION=$(curl -s "$LATEST_URL" | grep -oP 'bedrock-server-\K([0-9\.]+)(?=\.zip)' | head -1)

if [ ! -s "$LAST_VERSION_FILE" ]; then
  log $YELLOW "Arquivo lastversion.txt não encontrado ou vazio. Criando e definindo última versão: $LATEST_VERSION"
  echo "$LATEST_VERSION" > "$LAST_VERSION_FILE"
fi

LAST_VERSION=$(cat "$LAST_VERSION_FILE")

# Detectar versão instalada
if [ -s "$VERSION_FILE" ]; then
  INSTALLED_VERSION=$(cat "$VERSION_FILE")
else
  INSTALLED_VERSION="none"
fi

# Se versão instalada for diferente da última → baixar
if [ "$INSTALLED_VERSION" != "$LAST_VERSION" ]; then
  ZIP_URL="https://minecraft.azureedge.net/bin-linux/bedrock-server-$LAST_VERSION.zip"
  log $YELLOW "Baixando Minecraft Bedrock versão $LAST_VERSION..."
  curl -s -o "$SERVER_ZIP" "$ZIP_URL"

  if [ $? -eq 0 ] && [ -s "$SERVER_ZIP" ]; then
    echo "$LAST_VERSION" > "$VERSION_FILE"
    log $GREEN "Download concluído com sucesso."
  else
    log $RED "Erro no download de $ZIP_URL"
    rm -f "$SERVER_ZIP"
    exit 1
  fi
else
  log $GREEN "Servidor já está na versão $INSTALLED_VERSION."
fi

# Se existir o zip, extrai e apaga para atualizar o servidor
if [ -f "$SERVER_ZIP" ]; then
  log $YELLOW "Backup de segurança antes da atualização..."
  TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
  BACKUP_TARGET="$BACKUP_DIR/backup-$TIMESTAMP"
  mkdir -p "$BACKUP_TARGET"

  for item in worlds behavior_packs resource_packs structures server.properties permissions.json allowlist.json; do
    if [ -e "$SERVER_DIR/$item" ]; then
      log $YELLOW "Salvando $item..."
      cp -r "$SERVER_DIR/$item" "$BACKUP_TARGET/"
    fi
  done

  total=$(unzip -l "$SERVER_ZIP" | grep -E '^[ ]+[0-9]' | wc -l)
  log $YELLOW "Arquivo server.zip encontrado, iniciando extração..."
  log $YELLOW "Extraindo arquivos... Total: $total"

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

  log $YELLOW "Extração concluída em ${SECONDS}s! Restaurando arquivos do backup..."

  for item in worlds behavior_packs resource_packs structures server.properties permissions.json allowlist.json; do
    if [ -e "$BACKUP_TARGET/$item" ]; then
      log $YELLOW "Restaurando $item..."
      rm -rf "$SERVER_DIR/$item"
      cp -r "$BACKUP_TARGET/$item" "$SERVER_DIR/"
    fi
  done

  log $YELLOW "Removendo $SERVER_ZIP"
  chmod +x "$SERVER_BIN"
  rm "$SERVER_ZIP"
fi

if [ ! -f "$SERVER_BIN" ]; then
  log $RED "Arquivo não encontrado. Coloque server.zip para extrair."
  exit 1
fi

cd "$SERVER_DIR"
log $YELLOW "Iniciando servidor Minecraft..."

screen -dmS mc bash -c "./bedrock_server | tee /proc/1/fd/1"

sleep 10

log $YELLOW "Iniciando RCON personalizado..."
python3 /rcon_server.py &

log $GREEN "Minecraft Bedrock RCON Server Online..."

wait
exit $?
