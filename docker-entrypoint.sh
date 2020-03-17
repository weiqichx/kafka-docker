#!/bin/bash

set -e

# Allow the container to be started with `--user`
if [[ "$1" = 'kafka-server-start.sh' && "$(id -u)" = '0' ]]; then
    chown -R kafka "$KAFKA_DATA_DIR" "$KAFKA_LOG_DIR" "$KAFKA_CONF_DIR"
    exec gosu kafka "$0" "$@"
fi

# Generate the config only if it doesn't exist
if [[ ! -f "$KAFKA_CONF_DIR/server.properties" ]]; then
    CONFIG="$KAFKA_CONF_DIR/server.properties"
	{
        echo "broker.id=$BROKER_ID"

        echo "num.network.threads=$NUM_NETWORK_THREADS"
        echo "num.io.threads=$NUM_IO_THREADS"
        echo "socket.send.buffer.bytes=$SOCKET_SEND_BUFFER_BYTES"
        echo "socket.receive.buffer.bytes=$SOCKET_RECEIVE_BUFFER_BYTES"
        echo "socket.request.max.bytes=$SOCKET_REQUEST_MAX_BYTES"

        echo "log.dirs=$KAFKA_DATA_DIR"
        echo "num.partitions=1"
        echo "num.recovery.threads.per.data.dir=1"

        echo "offsets.topic.replication.factor=1"
        echo "transaction.state.log.replication.factor=1"
        echo "transaction.state.log.min.isr=1"

        echo "log.retention.hours=$LOG_RETENTION_HOURS"
        echo "log.segment.bytes=$LOG_SEGMENT_BYTES"
        echo "log.retention.check.interval.ms=$LOG_RETENTION_CHECK_INTERVAL_MS"

        echo "zookeeper.connect=$ZOO_CONNECT"
        echo "zookeeper.connection.timeout.ms=$ZOO_CONNECTION_TIMEOUT_MS"

        echo "group.initial.rebalance.delay.ms=0"
    } >> "$CONFIG"
fi

exec "$@"
