trap "echo Caught SIGTERM, exiting; exit 0" TERM

echo "Starting transmission-gluetun-port-update"
echo "Config:"
echo "TRANSMISSION_RPC_HOST=$TRANSMISSION_RPC_HOST"
echo "TRANSMISSION_RPC_PORT=$TRANSMISSION_RPC_PORT"
echo "TRANSMISSION_RPC_USERNAME=$TRANSMISSION_RPC_USERNAME"
CENSORED_TRANSMISSION_RPC_PASSWORD=$(echo $TRANSMISSION_RPC_PASSWORD | sed 's/./*/g')
echo "TRANSMISSION_RPC_PASSWORD=$CENSORED_TRANSMISSION_RPC_PASSWORD"
echo "GLUETUN_CONTROL_HOST=$GLUETUN_CONTROL_HOST"
echo "GLUETUN_CONTROL_PORT=$GLUETUN_CONTROL_PORT"
echo "INITIAL_DELAY_SEC=$INITIAL_DELAY_SEC"
echo "CHECK_INTERVAL_SEC=$CHECK_INTERVAL_SEC"
echo "ERROR_INTERVAL_SEC=$ERROR_INTERVAL_SEC"
echo "ERROR_INTERVAL_COUNT=$ERROR_INTERVAL_COUNT"

transmission_base_url="http://$TRANSMISSION_RPC_HOST:$TRANSMISSION_RPC_PORT/transmission/rpc"
gluetun_base_url="http://$GLUETUN_CONTROL_HOST:$GLUETUN_CONTROL_PORT"

current_port="0"
new_port=$current_port

error_count=0

echo "Waiting $INITIAL_DELAY_SEC seconds for initial delay"
sleep $INITIAL_DELAY_SEC &
wait $!

while :
do
    if [ $error_count -ge $ERROR_INTERVAL_COUNT ]; then
        echo "Reached maximum error count ($error_count), sleeping for $CHECK_INTERVAL_SEC sec"
        sleep $CHECK_INTERVAL_SEC &
        wait $!
        error_count=0
    fi

    echo "Checking port..."
    new_port=$(curl $gluetun_base_url/v1/openvpn/portforwarded 2> /dev/null | jq .port)
    echo "Received: $new_port"

    if [ -z "$new_port" ] || [ "$new_port" = "0" ]; then
        echo "Error: New port is empty or 0"
        error_count=$((error_count+1))
        sleep $ERROR_INTERVAL_SEC &
        wait $!
        continue
    fi

    if [ "$new_port" = "$current_port" ]; then
        echo "New port is the same as current port, nothing to do"
        sleep $CHECK_INTERVAL_SEC &
        wait $!
        continue
    fi

    echo "Updating port..."

    echo "Logging into Transmission WebUI"
    login_data="{\"method\": \"session-get\"}"
    session_response_headers=$(curl -s -u "$TRANSMISSION_RPC_USERNAME:$TRANSMISSION_RPC_PASSWORD" "$transmission_base_url" -I -X POST)
    session_id=$(echo "$session_response_headers" | grep -i '^X-Transmission-Session-Id:' | awk '{print $2}' | tr -d '\r')

    if [ -z "$session_id" ]; then
        echo "Failed to extract X-Transmission-Session-Id header from response headers"
        echo "Headers received:"
        echo "$session_response_headers"
        error_count=$((error_count+1))
        sleep $ERROR_INTERVAL_SEC
        continue
    fi

    echo "Sending new port to Transmission WebUI"
    set_port_data="{\"method\": \"session-set\", \"arguments\": {\"peer-port\": $new_port}}"
    echo "Sending data: $set_port_data"
    response=$(curl -s -u "$TRANSMISSION_RPC_USERNAME:$TRANSMISSION_RPC_PASSWORD" "$transmission_base_url" -H "X-Transmission-Session-Id: $session_id" -H "Content-Type: application/json" -d "$set_port_data")

    if echo "$response" | grep -q '"result":"success"'; then
    echo "Successfully updated port"
        current_port=$new_port
    else
        echo "Failed updating port"
        echo "Response: $response"
        error_count=$((error_count+1))
        sleep $ERROR_INTERVAL_SEC &
        wait $!
        continue
    fi

    sleep $CHECK_INTERVAL_SEC &
    wait $!
done