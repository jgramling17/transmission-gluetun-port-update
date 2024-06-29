# Transmission Gluetun port update

Docker container to automatically update transmission's listening port from Gluetun.

# Credit

This a forked repo, the original deserves all the credit. The original used qBittorrent while this repo uses transmission.

Original:
https://codeberg.org/TechnoSam/qbittorrent-gluetun-port-update

## Setup

Connect your transmission container and this container to Gluetun. If you are using docker-compose for everything, this means `network-mode: service:gluetun`. Refer to the Gluetun Wiki for more information.

Here is an example docker-compose.yml:

```yml
version: "3"
services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    ports:
      - 20144:8000     # Gluetun Control server
      - 9091:9091      # transmission WebUI
    volumes:
      - ./gluetun-data:/gluetun
    environment:
      # See https://github.com/qdm12/gluetun-wiki/tree/main/setup#setup
      - VPN_SERVICE_PROVIDER=ivpn
      - VPN_TYPE=openvpn
      - OPENVPN_USER=
      - OPENVPN_PASSWORD=
      - VPN_PORT_FORWARDING=on
    restart: "unless-stopped"
  transmission:
    image: lscr.io/linuxserver/transmission:latest
    container_name: transmission
    network_mode: service:gluetun
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=
      - USER= #REQUIRED!
      - PASS= #REQUIRED!
    volumes:
      - /path/to/transmission/data:/config
      - /path/to/downloads:/downloads
      - /path/to/watch/folder:/watch
    restart: "unless-stopped"
  transmission-port-update:
    image: jgramling17/transmission-gluetun-port-update:latest
    container_name: transmission_port_update
    network_mode: service:gluetun
    environment:
      - TRANSMISSION_RPC_PORT=9091
      - TRANSMISSION_RPC_USERNAME=
      - TRANSMISSION_RPC_PASSWORD=
    restart: "unless-stopped"
```

### Environment Variables

| Variable                     | Default      | Example                        | Description                                                                                                                                                                |
|------------------------------|--------------|--------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `TRANSMISSION_RPC_HOST`     | `127.0.0.1`  | `192.168.1.10`                 | IP Address where the transmission WebUI is hosted. This should probably never change.                                                                                       |
| `TRANSMISSION_RPC_PORT`     | `9091`       | `9091`                         | Port the transmission WebUI is running on. This is configurable in the transmission container. Note that this is the port *inside* the container, not the one forwarded out. |
| `TRANSMISSION_RPC_USERNAME` | `admin`      | `RicardoMilos`                    | Username to log into the transmission WebUI.                                                                                                                                |
| `TRANSMISSION_RPC_PASSWORD` | `adminadmin` | `correct-horse-battery-staple` | Password to log into the transmission WebUI.                                                                                                                                |
| `GLUETUN_CONTROL_HOST`       | `127.0.0.1`  | `192.168.1.11`                 | IP Address where the Gluetun control server is hosted. This should probably never change.                                                                                  |
| `GLUETUN_CONTROL_PORT`       | `8000`       | `6921`                         | Port the Gluetun control server is running on. Note that this is the port *inside* the container, not the one forwarded out.                                               |
| `INITIAL_DELAY_SEC`          | `10`         | `30`                           | Time in seconds to wait before making the first attempt to update the port.                                                                                                |
| `CHECK_INTERVAL_SEC`         | `60`         | `600`                          | Time in seconds to wait before checking each subsequent time.                                                                                                              |
| `ERROR_INTERVAL_SEC`         | `5`          | `3`                            | Time in seconds to wait before checking again if an error occurred.                                                                                                        |
| `ERROR_INTERVAL_COUNT`       | `5`          | `10`                           | Number of times an error can be encountered before waiting `CHECK_INTERVAL_SECONDS` instead. This will prevent a permanent error state from blowing up logs.               |
