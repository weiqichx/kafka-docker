FROM openjdk:8-jre-slim

ENV KAFKA_CONF_DIR=/config \
    KAFKA_DATA_DIR=/data \
    KAFKA_LOG_DIR=/logs \
    KAFKA_HEAP_OPTS="-Xmx1G -Xms1G" \
    BROKER_ID=0 \
    NUM_NETWORK_THREADS=3 \
    NUM_IO_THREADS=8 \
    SOCKET_SEND_BUFFER_BYTES=102400 \
    SOCKET_RECEIVE_BUFFER_BYTES=102400 \
    SOCKET_REQUEST_MAX_BYTES=104857600 \
    LOG_RETENTION_HOURS=168 \
    LOG_SEGMENT_BYTES=1073741824 \
    LOG_RETENTION_CHECK_INTERVAL_MS=300000 \
    ZOO_CONNECT=localhost:2181 \
    ZOO_CONNECTION_TIMEOUT_MS=6000

# Add a user with an explicit UID/GID and create necessary directories
RUN set -eux; \
    groupadd -r kafka --gid=900; \
    useradd -r -g kafka --uid=900 kafka; \
    mkdir -p "$KAFKA_DATA_DIR" "$KAFKA_CONF_DIR" "$KAFKA_LOG_DIR"; \
    chown kafka:kafka "$KAFKA_DATA_DIR" "$KAFKA_CONF_DIR" "$KAFKA_LOG_DIR"

# Install required packges
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        dirmngr \
        gosu \
        gnupg \
        netcat \
        wget; \
	rm -rf /var/lib/apt/lists/*; \
# Verify that gosu binary works
    gosu nobody true

ARG GPG_KEY=63F2B2B8D10CCC7A0CE88A72E9F87164989E9B3F
ARG SHORT_DISTRO_NAME=2.3.1
ARG DISTRO_NAME=kafka_2.11-2.3.1

# Download Apache Kafka, verify its PGP signature, untar and clean up
RUN set -eux; \
    ddist() { \
        local f="$1"; shift; \
        local distFile="$1"; shift; \
        local success=; \
        local distUrl=; \
        for distUrl in \
            'https://www.apache.org/dyn/closer.cgi?action=download&filename=' \
            https://www-us.apache.org/dist/ \
            https://www.apache.org/dist/ \
            https://archive.apache.org/dist/ \
        ; do \
            if wget -q -O "$f" "$distUrl$distFile" && [ -s "$f" ]; then \
                success=1; \
                break; \
            fi; \
        done; \
        [ -n "$success" ]; \
    }; \
    ddist "$DISTRO_NAME.tgz" "kafka/$SHORT_DISTRO_NAME/$DISTRO_NAME.tgz"; \
    ddist "$DISTRO_NAME.tgz.asc" "kafka/$SHORT_DISTRO_NAME/$DISTRO_NAME.tgz.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" || \
    gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEY" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$GPG_KEY"; \
    gpg --batch --verify "$DISTRO_NAME.tgz.asc" "$DISTRO_NAME.tgz"; \
    tar -zxf "$DISTRO_NAME.tgz"; \
    mv "$DISTRO_NAME/config/"* "$KAFKA_CONF_DIR"; \
    mv "$KAFKA_CONF_DIR/server.properties" "$KAFKA_CONF_DIR/server.properties.bak"; \
    rm -rf "$GNUPGHOME" "$DISTRO_NAME.tgz" "$DISTRO_NAME.tgz.asc"; \
    chown -R kafka:kafka "/$DISTRO_NAME"

WORKDIR $DISTRO_NAME
VOLUME ["$KAFKA_DATA_DIR", "$KAFKA_LOG_DIR"]

EXPOSE 9091 9092

ENV PATH=$PATH:/$DISTRO_NAME/bin \
    LOG_DIR=$KAFKA_LOG_DIR \
    KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:$KAFKA_CONF_DIR/log4j.properties"

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["kafka-run-class.sh", "-name", "kafkaServer", "-loggc", "kafka.Kafka", "/config/server.properties"]