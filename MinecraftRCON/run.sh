#!/usr/bin/env bash
set -eo pipefail

# --- Configurações ---
SERVER_DIR="/share/minecraftRCON"
BACKUP_DIR="$SERVER_DIR/backups"
LAST_VERSION_FILE="$SERVER_DIR/lastversion.txt"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_ZIP="$SERVER_DIR/server.zip"
PACKAGE_BACKUP_KEEP=${PACKAGE_BACKUP_KEEP:-2}

# Cores para log
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

log() {
  local color="$1"; shift
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${color}$*${RESET}"
}

log $GREEN "[ ############### Iniciando Minecraft Bedrock RCON ############### ]"

mkdir -p "$SERVER_DIR" "$BACKUP_DIR"
cd "$SERVER_DIR"

# --- Função para buscar versão via fallback ---
lookupVersionFallback() {
  log $YELLOW "Buscando última versão via fallback..."
  DOWNLOAD_URL=$(curl -fsSL "https://mc-bds-helper.vercel.app/api/latest")
  if [[ $DOWNLOAD_URL =~ .*/bedrock-server-([0-9.]+)\.zip ]]; then
    VERSION="${BASH_REMATCH[1]}"
  else
    log $RED "Falha ao extrair versão do fallback."
    exit 1
  fi
}

# --- Detecta versão atual salva ---
if [[ ! -f "$LAST_VERSION_FILE" || -s "$LAST_VERSION_FILE" == false ]]; then
  log $YELLOW "Arquivo lastversion.txt não encontrado ou vazio, buscando última versão..."
  lookupVersionFallback
  echo "$VERSION" > "$LAST_VERSION_FILE"
else
  VERSION=$(<"$LAST_VERSION_FILE")
  if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log $YELLOW "Conteúdo de lastversion.txt inválido, usando fallback..."
    lookupVersionFallback
    echo "$VERSION" > "$LAST_VERSION_FILE"
  else
    DOWNLOAD_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-$VERSION.zip"
  fi
fi

log $GREEN "Versão atual configurada: $VERSION"
log $GREEN "URL para download: $DOWNLOAD_URL"

# --- Verifica se precisa atualizar ---
NEED_UPDATE=true
if [[ -f "$SERVER_BIN" ]]; then
  CURRENT_INSTALLED=$("$SERVER_BIN" 2>&1 | grep -oP "Version:\s+\K[\d\.]+")
  if [[ "$CURRENT_INSTALLED" == "$VERSION" ]]; then
    log $GREEN "Servidor já está na versão $VERSION, não será atualizado."
    NEED_UPDATE=false
  else
    log $YELLOW "Versão instalada ($CURRENT_INSTALLED) diferente da última ($VERSION), atualizando..."
  fi
fi

# --- Função de backup seletivo ---
do_backup() {
  local timestamp backup_target
  timestamp=$(date '+%Y%m%d-%H%M%S')
  backup_target="$BACKUP_DIR/backup-$timestamp"

  log $YELLOW "Criando backup seletivo em $backup_target..."
  mkdir -p "$backup_target"

  for item in worlds behavior_packs resource_packs structures server.properties permissions.json allowlist.json; do
    if [[ -e "$SERVER_DIR/$item" ]]; then
      log $YELLOW "Salvando $item..."
      cp -r "$SERVER_DIR/$item" "$backup_target/"
    fi
  done

  # Limpa backups antigos mantendo os mais recentes
  log $YELLOW "Removendo backups antigos, mantendo os $PACKAGE_BACKUP_KEEP mais recentes..."
  cd "$BACKUP_DIR"
  ls -1td backup-* | tail -n +$((PACKAGE_BACKUP_KEEP+1)) | xargs -r rm -rf
  cd - >/dev/null
}

# --- Atualização se necessário ---
if $NEED_UPDATE; then
  do_backup

  log $YELLOW "Baixando servidor Bedrock versão $VERSION..."
  curl -fsSL -o "$SERVER_ZIP" -A "itzg/minecraft-bedrock-server" "$DOWNLOAD_URL"

  total=$(unzip -l "$SERVER_ZIP" | grep -E '^[ ]+[0-9]' | wc -l)
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

  chmod +x "$SERVER_BIN"
  rm "$SERVER_ZIP"
  echo "$VERSION" > "$LAST_VERSION_FILE"

  log $GREEN "Atualização concluída para a versão $VERSION."
fi

# --- Inicializa o servidor ---
log $YELLOW "Iniciando servidor Minecraft Bedrock..."
screen -dmS mc bash -c "./bedrock_server | tee /proc/1/fd/1"

sleep 10

log $YELLOW "Iniciando RCON personalizado..."
python3 /rcon_server.py &

log $GREEN "Servidor Minecraft Bedrock e RCON online."

wait
