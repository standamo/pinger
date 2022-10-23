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
    for TGTHOST in ${HOSTS}; do
        OUT=`/bin/ping -c ${PING_COUNT} -i 1 -q "${TGTHOST}"`
        PCT=${OUT%%%*}
        PCT=${PCT##* }
        MAM=${OUT##*= }
        MAM=${MAM%% *}
        IFS=/ read MIN AVG MAX <<< "${MAM}"
        bashio::log.debug "ping: ${TGTHOST} : loss=${PCT}% : min/avg/max=${MIN}/${AVG}/${MAX} msec"
        MESSAGE="{ 'pings': ${PING_COUNT}, 'pct_loss': ${PCT}, 'min_ping': ${MIN}, 'avg_ping': ${MIN}, 'max_ping': ${MIN} }"
        "${MQTT_BIN}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${MQTT_TOPIC}/${TGTHOST}" -m "{$MESSAGE}"
        done
    sleep $INTERVAL
done
bashio::log.info "Pinger exited"