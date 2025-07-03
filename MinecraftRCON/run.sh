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
LAST_VERSION_FILE="$SERVER_DIR/lastversion.txt"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
BACKUP_TARGET="$BACKUP_DIR/backup-$TIMESTAMP"

mkdir -p "$SERVER_DIR" "$BACKUP_DIR"
cd "$SERVER_DIR"

# Verifica versão salva
if [[ ! -s "$LAST_VERSION_FILE" ]]; then
  log $YELLOW "Arquivo lastversion.txt não encontrado ou vazio, buscando última versão via fallback..."
  LATEST_VERSION=$(curl -fsSL "https://mc-bds-helper.vercel.app/api/latest" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?')
  if [[ -z "$LATEST_VERSION" ]]; then
    log $RED "Erro ao buscar versão via fallback, abortando."
    exit 1
  fi
  echo "$LATEST_VERSION" > "$LAST_VERSION_FILE"
else
  LATEST_VERSION=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?' "$LAST_VERSION_FILE")
  log $YELLOW "Versão salva em lastversion.txt: $LATEST_VERSION"
fi

# Verifica versão instalada
INSTALLED_VERSION=$("$SERVER_BIN" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "local")

if [[ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]]; then
  log $YELLOW "Versão atual instalada: $INSTALLED_VERSION"
  log $YELLOW "Versão instalada diferente da última ($LATEST_VERSION), atualizando..."

  log $YELLOW "Criando backup seletivo em $BACKUP_TARGET..."
  mkdir -p "$BACKUP_TARGET"
  for item in worlds behavior_packs resource_packs structures server.properties permissions.json allowlist.json; do
    if [ -e "$item" ]; then
      log $YELLOW "Salvando $item..."
      cp -r "$item" "$BACKUP_TARGET/"
    fi
  done

  log $YELLOW "Removendo backups antigos, mantendo os 2 mais recentes..."
  ls -1dt "$BACKUP_DIR"/backup-* 2>/dev/null | tail -n +3 | xargs -r rm -rf

  log $YELLOW "Baixando servidor Bedrock versão $LATEST_VERSION..."
  DOWNLOAD_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-$LATEST_VERSION.zip"
  curl -fsSL -o "$SERVER_ZIP" "$DOWNLOAD_URL"

  log $YELLOW "Extraindo arquivos do servidor..."
  total=$(unzip -l "$SERVER_ZIP" | grep -E '^[ ]+[0-9]' | wc -l)
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

  log $YELLOW "Atualização concluída para a versão $LATEST_VERSION."
  echo "$LATEST_VERSION" > "$LAST_VERSION_FILE"

  log $YELLOW "Restaurando arquivos do backup..."
  for item in worlds behavior_packs resource_packs structures server.properties permissions.json allowlist.json; do
    if [ -e "$BACKUP_TARGET/$item" ]; then
      log $YELLOW "Restaurando $item..."
      rm -rf "$item"
      cp -r "$BACKUP_TARGET/$item" "$item"
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

log $YELLOW "Iniciando servidor Minecraft..."
screen -dmS mc bash -c "./bedrock_server | tee /proc/1/fd/1"

sleep 10

log $YELLOW "Iniciando RCON personalizado..."
python3 /rcon_server.py &

log $GREEN "Servidor Minecraft Bedrock e RCON online."

wait
