#!/usr/bin/with-contenv bashio

MQTT_BIN=$(bashio::config 'MQTT_BIN')
MQTT_HOST=$(bashio::config 'MQTT_HOST')
MQTT_USERNAME=$(bashio::config 'MQTT_USERNAME')
MQTT_PASSWORD=$(bashio::config 'MQTT_PASSWORD')
MQTT_PORT=$(bashio::config 'MQTT_PORT')
MQTT_TOPIC=$(bashio::config 'MQTT_TOPIC')
HOSTS=$(bashio::config 'HOSTS')
INTERVAL=$(bashio::config 'INTERVAL')
PING_COUNT=$(bashio::config 'PING_COUNT')
LOG_LEVEL=$(bashio::config 'LOG_LEVEL')

bashio::log.level "${LOG_LEVEL}"
bashio::log.info "Pinger starting"
bashio::log.debug "MQTT_BIN=${MQTT_BIN}"
bashio::log.debug "MQTT_HOST=${MQTT_HOST}"
bashio::log.debug "MQTT_USERNAME=${MQTT_USERNAME}"
bashio::log.debug "MQTT_PASSWORD=${MQTT_PASSWORD}"
bashio::log.debug "MQTT_PORT=${MQTT_PORT}"
bashio::log.debug "MQTT_TOPIC=${MQTT_TOPIC}"
bashio::log.debug "INTERVAL=${INTERVAL}"
bashio::log.debug "PING_COUNT=${PING_COUNT}"
bashio::log.debug "LOG_LEVEL=${LOG_LEVEL}"
bashio::log.debug "HOSTS=${HOSTS}"
while ((1)); do
    out=`/bin/ping -c ${PING_COUNT} -i 1 -q "${HOSTS}"`
    pct=${out%%%*}
    pct=${pct##* }
    mam=${out##*= }
    mam=${mam%% *}
    IFS=/ read min avg max <<< "${mam}"
    bashio::log.debug "ping: ${TARGET} : loss=${pct}% : min/avg/max=${min}/${avg}/${max} msec"
    "${MQTT_BIN}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${MQTT_TOPIC}/downstream/${counter}" -m "$message"
    sleep $INTERVAL
done
bashio::log.info "Pinger exited"