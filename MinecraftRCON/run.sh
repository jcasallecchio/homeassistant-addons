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

log $GREEN "[ ######### Iniciando Minecraft Bedrock RCON ######### ]"

mkdir -p "$SERVER_DIR" "$BACKUP_DIR"

if ! isTrue "$EULA"; then
  log $RED "EULA não aceita. Configure EULA=true para continuar."
  exit 1
fi

# --- Função para buscar versão e URL de download ---
DOWNLOAD_LINKS_URL="https://net-secondary.web.minecraft-services.net/api/v1.0/download/links"

replace_version_in_url() {
  local url="$1" new_ver="$2"
  echo "$url" | sed -E "s/(bedrock-server-)[^/]+(\.zip)/\1${new_ver}\2/"
}

lookupVersion() {
  local platform="$1"
  local customVersion="$2"
  local download_url

  if ! download_url=$(curl -fsSL "${DOWNLOAD_LINKS_URL}" | \
    jq --arg platform "$platform" -r '
      try(fromjson) catch({}) |
      .result.links // [] |
      map(select(.downloadType == $platform)) |
      if length > 0 then
        .[0].downloadUrl
      else
        empty
      end
    '); then
    log $YELLOW "API falhou, tentando fallback..."
    if [[ "$platform" == "serverBedrockLinux" ]]; then
      download_url=$(curl -fsSL "https://mc-bds-helper.vercel.app/api/latest")
    elif [[ "$platform" == "serverBedrockPreviewLinux" ]]; then
      download_url=$(curl -fsSL "https://mc-bds-helper.vercel.app/api/preview")
    else
      log $RED "Plataforma inválida: $platform"
      exit 2
    fi
  fi

  if [[ -n "$customVersion" ]]; then
    download_url=$(replace_version_in_url "$download_url" "$customVersion")
  fi

  if [[ $download_url =~ .*/bedrock-server-(.*)\.zip ]]; then
    VERSION="${BASH_REMATCH[1]}"
  else
    log $RED "Falha ao extrair versão do URL: $download_url"
    exit 2
  fi

  DOWNLOAD_URL="$download_url"
}

# --- Define versão atual ---
CURRENT_VERSION=""
if [[ -f "$LAST_VERSION_FILE" ]]; then
  CURRENT_VERSION=$(<"$LAST_VERSION_FILE")
fi

# Se não existe ou vazio, baixa a última versão
if [[ -z "$CURRENT_VERSION" ]]; then
  log $YELLOW "Arquivo lastversion.txt não encontrado ou vazio, buscando última versão..."
  lookupVersion serverBedrockLinux
  echo "$VERSION" > "$LAST_VERSION_FILE"
else
  VERSION="$CURRENT_VERSION"
  lookupVersion serverBedrockLinux "$VERSION"
fi

log $GREEN "Versão atual configurada: $VERSION"
log $GREEN "URL para download: $DOWNLOAD_URL"

# --- Função para fazer backup seletivo ---
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

  # Limpa backups antigos mantendo apenas os mais recentes
  log $YELLOW "Removendo backups antigos, mantendo os $PACKAGE_BACKUP_KEEP mais recentes..."
  cd "$BACKUP_DIR"
  ls -1td backup-* | tail -n +$((PACKAGE_BACKUP_KEEP+1)) | xargs -r rm -rf
  cd - >/dev/null
}

# --- Verifica necessidade de download e atualização ---
NEED_UPDATE=true
if [[ -f "$SERVER_BIN" ]]; then
  # Tenta extrair versão do nome do binário atual
  if [[ $(basename "$SERVER_BIN") =~ bedrock_server-(.*) ]]; then
    INSTALLED_VERSION="${BASH_REMATCH[1]}"
  else
    INSTALLED_VERSION=""
  fi

  if [[ "$INSTALLED_VERSION" == "$VERSION" ]]; then
    log $GREEN "Servidor já está na versão $VERSION, não será atualizado."
    NEED_UPDATE=false
  else
    log $YELLOW "Versão instalada ($INSTALLED_VERSION) diferente da última ($VERSION), atualizando..."
  fi
fi

if $NEED_UPDATE; then
  do_backup

  # Baixa o zip
  TMP_ZIP="$SERVER_DIR/server.zip"
  log $YELLOW "Baixando servidor Bedrock versão $VERSION..."
  curl -fsSL -o "$TMP_ZIP" -A "itzg/minecraft-bedrock-server" "$DOWNLOAD_URL"

  # Remove arquivos antigos, preserva mundos e packs
  for keep in worlds behavior_packs resource_packs structures server.properties permissions.json allowlist.json; do
    rm -rf "$SERVER_DIR/$keep"
  done

  # Extrai o zip
  log $YELLOW "Extraindo arquivos do servidor..."
  unzip -o "$TMP_ZIP" -d "$SERVER_DIR"
  rm "$TMP_ZIP"

  chmod +x "$SERVER_BIN"

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

