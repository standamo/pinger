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

# $1 = OBJID; $2 = metric, $3 = unit_of_meas
function send_config_message {
    OBJID=$1
    METRIC=$2
    UNITS=$3
    MESSAGE='{"name": "'${OBJID}-${METRIC}'", "unique_id": "'${OBJID}-${METRIC}'", "stat_t": "'${MQTT_TOPIC}-${OBJID}/state'", '
    MESSAGE=${MESSAGE}'"val_tpl": "{{ value_json.'${METRIC}' | is_defined }}", "unit_of_meas": "'${UNITS}'", '
    MESSAGE=${MESSAGE}'"device": { "name": "pinger-'${OBJID}'", "identifiers": "pinger-'${OBJID}'", "via_device": "Pinger"}, '
    MESSAGE=${MESSAGE}'}'
    bashio::log.debug "Topic: ${MQTT_TOPIC}-${OBJID}-C/config   Message: ${MESSAGE}"
    "${MQTT_BIN}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${MQTT_TOPIC}-${OBJID}-${METRIC}/config" -m "${MESSAGE}"
}

bashio::log.info "Starting measurement loop"
while ((1)); do
    for TGTHOST in ${HOSTS}; do
        OBJID=${TGTHOST//./_}
        # config messages sent all the time because of possible mqtt restart
        send_config_message ${OBJID} "ping_count" "count"
        send_config_message ${OBJID} "pct_loss" "%"
        send_config_message ${OBJID} "min_ping" "msec"
        send_config_message ${OBJID} "max_ping" "msec"
        send_config_message ${OBJID} "avg_ping" "msec"
        OUT=`/bin/ping -c ${PING_COUNT} -i 1 -q "${TGTHOST}"`
        PCT=${OUT%%%*}
        PCT=${PCT##* }
        MAM=${OUT##*= }
        MAM=${MAM%% *}
        IFS=/ read MIN AVG MAX <<< "${MAM}"
        MESSAGE='{ "name": "pinger-'${OBJID}'", "ping_count": '${PING_COUNT}', "pct_loss": '${PCT}', "min_ping": '${MIN}', "avg_ping": '${AVG}', "max_ping": '${MAX}' }'
        bashio::log.debug "Topic: ${MQTT_TOPIC}-${OBJID}/state   Message: ${MESSAGE}"
        "${MQTT_BIN}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${MQTT_TOPIC}-${OBJID}/state" -m "${MESSAGE}"
        done
    sleep $INTERVAL
done
bashio::log.info "Pinger exited"