FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    libssl-dev libcurl4 libstdc++6 libz-dev \
    python3 python3-pip unzip curl screen psmisc && \
    pip3 install flask pexpect waitress && \
    apt-get clean

COPY . /bedrock
WORKDIR /bedrock

RUN chmod +x bedrock_server

COPY rcon_server.py /rcon_server.py
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
