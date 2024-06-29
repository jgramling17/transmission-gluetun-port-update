FROM alpine:3.18

RUN apk add --no-cache curl && \
    apk add --no-cache jq

ENV TRANSMISSION_RPC_HOST=127.0.0.1 \
    TRANSMISSION_RPC_PORT=9091 \
    TRANSMISSION_RPC_USERNAME=admin \
    CENSORED_TRANSMISSION_RPC_PASSWORD=adminadmin \
    GLUETUN_CONTROL_HOST=127.0.0.1\
    GLUETUN_CONTROL_PORT=8000 \
    INITIAL_DELAY_SEC=10 \
    CHECK_INTERVAL_SEC=60 \
    ERROR_INTERVAL_SEC=5 \
    ERROR_INTERVAL_COUNT=5

COPY port-update.sh /port-update.sh

CMD ["/bin/sh", "/port-update.sh"]

