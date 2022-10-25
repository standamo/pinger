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
bashio::log.info "Sending discovery messages"
for TGTHOST in ${HOSTS}; do
    OBJID=${TGTHOST//./_}
    MESSAGE="{'name': 'ping_count', 'state_topic': '${MQTT_TOPIC}-${OBJID}/state', 'value_template': '{{ value_json.ping_count }}'}"
    bashio::log.debug "Topic: ${MQTT_TOPIC}-${OBJID}-C/config   Message: ${MESSAGE}"
    "${MQTT_BIN}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${MQTT_TOPIC}-${OBJID}-C/config" -m "${MESSAGE}"
    MESSAGE="{'name': 'pct_loss', 'state_topic': '${MQTT_TOPIC}-${OBJID}/state', 'unit_of_measurement': '%', 'value_template': '{{ value_json.pct_loss }}'}"
    "${MQTT_BIN}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${MQTT_TOPIC}-${OBJID}-L/config" -m "${MESSAGE}"
    MESSAGE="{'name': 'min_ping', 'state_topic': '${MQTT_TOPIC}-${OBJID}/state', 'unit_of_measurement': 'ms', 'value_template': '{{ value_json.min_ping }}'}"
    "${MQTT_BIN}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${MQTT_TOPIC}-${OBJID}-m/config" -m "${MESSAGE}"
    MESSAGE="{'name': 'max_ping', 'state_topic': '${MQTT_TOPIC}-${OBJID}/state', 'unit_of_measurement': 'ms', 'value_template': '{{ value_json.max_ping }}'}"
    "${MQTT_BIN}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${MQTT_TOPIC}-${OBJID}-M/config" -m "${MESSAGE}"
    MESSAGE="{'name': 'avg_ping', 'state_topic': '${MQTT_TOPIC}-${OBJID}/state', 'unit_of_measurement': 'ms', 'value_template': '{{ value_json.avg_ping }}'}"
    "${MQTT_BIN}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${MQTT_TOPIC}-${OBJID}-A/config" -m "${MESSAGE}"
done
bashio::log.info "Starting measurement loop"
while ((1)); do
    for TGTHOST in ${HOSTS}; do
        OUT=`/bin/ping -c ${PING_COUNT} -i 1 -q "${TGTHOST}"`
        OBJID=${TGTHOST//./_}
        PCT=${OUT%%%*}
        PCT=${PCT##* }
        MAM=${OUT##*= }
        MAM=${MAM%% *}
        IFS=/ read MIN AVG MAX <<< "${MAM}"
        MESSAGE="{ 'ping_count': ${PING_COUNT}, 'pct_loss': ${PCT}, 'min_ping': ${MIN}, 'avg_ping': ${MIN}, 'max_ping': ${MIN} }"
        bashio::log.debug "Topic: ${MQTT_TOPIC}-${OBJID}/state   Message: ${MESSAGE}"
        "${MQTT_BIN}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${MQTT_TOPIC}-${OBJID}/state" -m "${MESSAGE}"
        done
    sleep $INTERVAL
done
bashio::log.info "Pinger exited"