#!/usr/bin/env bash
set -e

# Garante que o diretório de dados persista entre reinicializações
mkdir -p /share/minecraftRCON
cd /share/minecraftRCON

# Garante permissão de execução no binário (caso necessário)
chmod +x /bedrock/bedrock_server

# Inicia o servidor Bedrock como usuário não-root, com stdin monitorado para envio de 'stop'
/usr/local/bin/entrypoint-demoter --match /share/minecraftRCON --debug --stdin-on-term stop /opt/bedrock-entry.sh &

# Aguarda o servidor subir antes de iniciar o RCON
sleep 10

# Inicia o servidor RCON em background
python3 /rcon_server.py &

# Espera qualquer processo terminar (para manter o container vivo enquanto Bedrock ou RCON estiverem rodando)
wait -n
exit $?
