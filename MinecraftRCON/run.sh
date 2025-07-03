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

mkdir -p "$SERVER_DIR"
mkdir -p "$BACKUP_DIR"

SECONDS=0

fetch_latest_version_fallback() {
  # Apenas retorna a versão, sem log para não poluir output
  curl -fsSL "https://mc-bds-helper.vercel.app/api/latest" || true
}

# Obtém a última versão, criando arquivo se não existir ou estiver vazio
if [[ ! -s "$LAST_VERSION_FILE" ]]; then
  log $YELLOW "Arquivo lastversion.txt não encontrado ou vazio, buscando última versão via fallback..."
  LATEST_VERSION=$(fetch_latest_version_fallback)
  if [[ -z "$LATEST_VERSION" ]]; then
    log $RED "Erro ao buscar versão via fallback, abortando."
    exit 1
  fi
  echo "$LATEST_VERSION" > "$LAST_VERSION_FILE"
else
  LATEST_VERSION=$(cat "$LAST_VERSION_FILE")
  log $YELLOW "Versão salva em lastversion.txt: $LATEST_VERSION"
fi

# Para efeito de exemplo, detecta se o servidor está instalado verificando se o binário existe
if [[ -f "$SERVER_BIN" ]]; then
  INSTALLED_VERSION="local"
else
  INSTALLED_VERSION=""
fi

log $YELLOW "Versão atual instalada: $INSTALLED_VERSION"

if [[ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]]; then
  log $YELLOW "Versão instalada diferente da última ($LATEST_VERSION), atualizando..."

  # Faz backup seletivo antes
  log $YELLOW "Criando backup seletivo em $BACKUP_TARGET..."
  mkdir -p "$BACKUP_TARGET"
  for item in worlds behavior_packs resource_packs structures server.properties permissions.json allowlist.json; do
    if [ -e "$SERVER_DIR/$item" ]; then
      log $YELLOW "Salvando $item..."
      cp -r "$SERVER_DIR/$item" "$BACKUP_TARGET/"
    fi
  done

  # Remove backups antigos, mantendo os 2 mais recentes
  log $YELLOW "Removendo backups antigos, mantendo os 2 mais recentes..."
  (cd "$BACKUP_DIR" && ls -1dt backup-* | tail -n +3 | xargs -r rm -rf)

  # Baixa o zip do servidor
  DOWNLOAD_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${LATEST_VERSION}.zip"
  log $YELLOW "Baixando servidor Bedrock versão $LATEST_VERSION..."
  curl -o "$SERVER_ZIP" -fsSL "$DOWNLOAD_URL"

  # Extrai mostrando progresso percentual, suprimindo detalhes inflating/creating
  total=$(unzip -l "$SERVER_ZIP" | grep -E '^[ ]+[0-9]' | wc -l)
  log $YELLOW "Arquivo server.zip encontrado, iniciando extração..."
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

  # Restaura arquivos importantes do backup
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

  # Atualiza lastversion.txt para garantir
  echo "$LATEST_VERSION" > "$LAST_VERSION_FILE"
else
  log $YELLOW "Versão instalada já está atualizada: $INSTALLED_VERSION"
fi

if [ ! -f "$SERVER_BIN" ]; then
  log $RED "Arquivo $SERVER_BIN não encontrado. Coloque server.zip para extrair."
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
