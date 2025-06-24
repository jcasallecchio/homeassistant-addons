#!/usr/bin/env bash

MINECRAFT_DIR="/share/minecraftRCON"

# Cria a pasta de instalação, se não existir
mkdir -p "${MINECRAFT_DIR}"

# Faz download e extrai o Bedrock Server se ainda não existir
if [ ! -f "${MINECRAFT_DIR}/bedrock_server" ]; then
    echo "Baixando Minecraft Bedrock Server..."
    curl -sL -o /tmp/bedrock-server.zip "https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-1.21.92.1.zip"
    unzip -o /tmp/bedrock-server.zip -d "${MINECRAFT_DIR}"
    chmod +x "${MINECRAFT_DIR}/bedrock_server"
fi

# Entra no diretório do servidor
cd "${MINECRAFT_DIR}"

# Inicia o servidor no screen
screen -dmS mc ./bedrock_server

# Aguarda servidor iniciar
sleep 10

# Inicia servidor RCON
python3 /rcon_server.py &

wait -n
exit $?
