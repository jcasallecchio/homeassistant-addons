#!/usr/bin/with-contenv bashio

# ulimit -n 1048576
ulimit -n 524288

echo ">>> [DEBUG] run.sh executado"

until [ -e /var/run/avahi-daemon/socket ]; do
  sleep 1s
done

bashio::log.info "Preparing directories"
if [ ! -d /config/cups ]; then cp -v -R /etc/cups /config; fi
rm -v -fR /etc/cups

ln -v -s /config/cups /etc/cups

bashio::log.info "Starting CUPS server as CMD from S6"

cupsd -f
