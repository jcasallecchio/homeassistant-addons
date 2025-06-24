FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    unzip curl screen psmisc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install flask waitress

COPY rcon_server.py /rcon_server.py
COPY run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /share/minecraftRCON

CMD ["/run.sh"]
