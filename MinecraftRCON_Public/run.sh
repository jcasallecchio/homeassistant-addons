#!/usr/bin/env bash
set -e

# Cores ANSI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sem cor

echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}[ ##### Iniciando Minecraft Bedrock RCON (Público) ##### ]${NC}"

SERVER_DIR="/share/minecraftRCON_Public"
SERVER_BIN="$SERVER_DIR/bedrock_server"
SERVER_ZIP="$SERVER_DIR/server.zip"

mkdir -p "$SERVER_DIR"

# Se existir o zip, extrai e apaga para atualizar o servidor
if [ -f "$SERVER_ZIP" ]; then
  total=$(unzip -l "$SERVER_ZIP" | grep -E '^[ ]+[0-9]' | wc -l)
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Extraindo $total arquivos..."

  count=0
  last_percent=0
  unzip -o "$SERVER_ZIP" -d "$SERVER_DIR" | while read -r line; do
    if echo "$line" | grep -q "inflating:"; then
      count=$((count + 1))
      percent=$((count * 100 / total))
      if [ "$percent" -ne "$last_percent" ]; then
        echo -ne "\r[$(date '+%Y-%m-%d %H:%M:%S')] Extraindo arquivos... $percent%"
        last_percent=$percent
      fi
    fi
  done
  echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Extração concluída! Removendo $SERVER_ZIP${NC}"
  chmod +x "$SERVER_BIN"
  rm "$SERVER_ZIP"
fi

if [ ! -f "$SERVER_BIN" ]; then
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}Arquivo não encontrado. Coloque server.zip em $SERVER_DIR para extrair.${NC}"
  exit 1
fi

cd "$SERVER_DIR"
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Iniciando servidor Minecraft (Público)...${NC}"

# Nome da sessão do screen alterado para evitar conflito com outro addon
screen -dmS mc_public bash -c "./bedrock_server | tee /proc/1/fd/1"

sleep 10

echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}Iniciando RCON personalizado (Público)...${NC}"
python3 /rcon_server.py &

echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN} Minecraft Bedrock RCON Server Público Online...${NC}"

wait
exit $?
