FROM debian:bullseye-slim

# Instala dependências
RUN apt-get update && apt-get install -y \
    libssl-dev libcurl4 libstdc++6 libz-dev \
    python3 python3-pip unzip curl wget screen psmisc && \
    pip3 install flask pexpect && \
    apt-get clean

# Copia arquivos
COPY . /bedrock
WORKDIR /bedrock

# Permissões
RUN chmod +x bedrock_server || true
COPY rcon_server.py /rcon_server.py
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Comando inicial
CMD [ "/run.sh" ]
