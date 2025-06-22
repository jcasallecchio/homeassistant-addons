ARG BUILD_FROM
FROM itzg/minecraft-bedrock-server

# Instala dependências mínimas necessárias para rodar o servidor RCON
RUN apt-get update && apt-get install -y python3 python3-pip screen psmisc
RUN pip3 install flask
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Pasta de dados persistente
VOLUME [ "/share" ]

# Copia scripts para o contêiner
COPY run.sh /run.sh
COPY rcon_server.py /rcon_server.py

# Permissões
RUN chmod +x /run.sh

# Define o entrypoint principal
ENTRYPOINT [ "/run.sh" ]

### LABELS
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="jdeath (https://github.com/jcasallecchio)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="jcasallecchio (https://github.com/jcasallecchio)" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/jcasallecchio" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
