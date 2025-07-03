#!/usr/bin/env bash
set -eo pipefail

# --- Configurações ---
SERVER_DIR="/share/minecraftRCON"
BACKUP_DIR="$SERVER_DIR/backups"
LAST_VERSION_FILE="$SERVER_DIR/lastversion.txt"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_ZIP="$SERVER_DIR/server.zip"
DEBUG=${DEBUG:-false}
EULA=${EULA:-true}
PACKAGE_BACKUP_KEEP=${PACKAGE_BACKUP_KEEP:-2}

# Cores para log
INTRO='\033[0;42m\033[1;37m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'


log() {
  local color="$1"; shift
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${color}$*${RESET}"
}

isTrue() {
  [[ "${1,,}" =~ ^(true|on|1)$ ]]
}

if isTrue "$DEBUG"; then
  set -x
fi

log $INTRO "[ .......... Iniciando Minecraft Bedrock RCON .......... ]"

mkdir -p "$SERVER_DIR" "$BACKUP_DIR"

if ! isTrue "$EULA"; then
  log $RED "EULA não aceita. Configure EULA=true para continuar."
  exit 1
fi

# --- Função para buscar versão e URL de download ---
replace_version_in_url() {
  local url="$1" new_ver="$2"
  echo "$url" | sed -E "s/(bedrock-server-)[^/]+(\.zip)/\1${new_ver}\2/"
}

lookupVersion() {
  local platform="$1"
  local customVersion="$2"
  local download_url

  log $YELLOW "Buscando última versão via fallback..."
  if [[ "$platform" == "serverBedrockLinux" ]]; then
    download_url=$(curl -fsSL "https://mc-bds-helper.vercel.app/api/latest")
  elif [[ "$platform" == "serverBedrockPreviewLinux" ]]; then
    download_url=$(curl -fsSL "https://mc-bds-helper.vercel.app/api/preview")
  else
    log $RED "Plataforma inválida: $platform"
    exit 2
  fi

  if [[ -n "$customVersion" ]]; then
    download_url=$(replace_version_in_url "$download_url" "$customVersion")
  fi

  if [[ $download_url =~ .*/bedrock-server-([0-9.]+)\.zip ]]; then
    VERSION="${BASH_REMATCH[1]}"
  else
    log $RED "Falha ao extrair versão do URL: $download_url"
    exit 2
  fi

  DOWNLOAD_URL="$download_url"
}

# --- Verifica versão instalada (se houver) ---
INSTALLED_VERSION=""
if [[ -f "$LAST_VERSION_FILE" ]]; then
  INSTALLED_VERSION=$(<"$LAST_VERSION_FILE")
fi

# --- Busca última versão disponível online ---
lookupVersion serverBedrockLinux
log $GREEN "Versão disponível online: $VERSION"
log $GREEN "Versão instalada localmente: ${INSTALLED_VERSION:-nenhuma}"

# --- Decide se precisa atualizar ---
NEED_UPDATE=true
if [[ "$VERSION" == "$INSTALLED_VERSION" ]] && [[ -f "$SERVER_BIN" ]]; then
  log $GREEN "Servidor já está na última versão, não será atualizado!"
  NEED_UPDATE=false
else
  log $YELLOW "Versão instalada ($INSTALLED_VERSION) diferente da disponível ($VERSION), atualizando..."
  log $GREEN "URL para download: $DOWNLOAD_URL"
fi

# --- Backup e restauração ---
BACKUP_TARGET=""

do_backup() {
  local timestamp
  timestamp=$(date '+%Y%m%d-%H%M%S')
  BACKUP_TARGET="$BACKUP_DIR/backup-$timestamp"

  log $YELLOW "Criando backup seletivo em $BACKUP_TARGET..."
  mkdir -p "$BACKUP_TARGET"

  for item in worlds behavior_packs resource_packs structures server.properties permissions.json allowlist.json; do
    if [[ -e "$SERVER_DIR/$item" ]]; then
      log $YELLOW "Salvando $item..."
      cp -r "$SERVER_DIR/$item" "$BACKUP_TARGET/"
    fi
  done

  log $YELLOW "Removendo backups antigos, mantendo os $PACKAGE_BACKUP_KEEP mais recentes..."
  find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup-*" | sort -r | tail -n +$((PACKAGE_BACKUP_KEEP + 1)) | xargs -r rm -rf
}

# --- Executa atualização se necessário ---
if $NEED_UPDATE; then
  do_backup

  TMP_ZIP="$SERVER_DIR/server.zip"
  log $YELLOW "Baixando servidor Bedrock versão $VERSION..."
  curl -fsSL -o "$TMP_ZIP" -A "itzg/minecraft-bedrock-server" "$DOWNLOAD_URL"

  total=$(unzip -l "$TMP_ZIP" | grep -E '^[ ]+[0-9]' | wc -l)
  log $YELLOW "Arquivo server.zip encontrado, iniciando extração..."
  log $YELLOW "Extraindo arquivos... Total: $total"

  count=0
  last_percent=0
  unzip -o "$TMP_ZIP" -d "$SERVER_DIR" | while read -r line; do
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
    if [[ -e "$BACKUP_TARGET/$item" ]]; then
      log $YELLOW "Restaurando $item..."
      rm -rf "$SERVER_DIR/$item"
      cp -r "$BACKUP_TARGET/$item" "$SERVER_DIR/"
    fi
  done

  log $YELLOW "Removendo $TMP_ZIP"
  chmod +x "$SERVER_BIN"
  rm "$TMP_ZIP"

  echo "$VERSION" > "$LAST_VERSION_FILE"

  log $GREEN "Atualização concluída para a versão $VERSION."
fi

# --- Inicia servidor ---
cd "$SERVER_DIR"

log $YELLOW "Iniciando servidor Minecraft Bedrock..."
screen -dmS mc bash -c "./bedrock_server | tee /proc/1/fd/1"

sleep 10

log $YELLOW "Iniciando RCON personalizado..."
python3 /rcon_server.py &

log $GREEN "Servidor Minecraft Bedrock e RCON online."

wait
