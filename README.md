# WireGuard docker image using BoringTun

WireGuard docker setup using BoringTun.

## Overview

This project provides a docker image to create a simple personal WireGuard VPN using BoringTun.

Using BoringTun enables the use of a userspace implementation on hosts that do not provide a WireGuard kernel module.

Required configuration files will be generated on first run using environment variables. Client configurations are
available as config files and QR codes.

## Build

When creating the image, BoringTun is compiled in a docker build stage and later copied into final image.

```
$ docker-compose build
```

## Run

Customize the file `docker-compose`. You can change the following environment variables as needed

* `DEVICE`: Some `tun` device, e.g. `tun0`
* `SERVER_HOST`: The host name of your server
* `SERVER_PORT`: The port the service should listen at
* `NETWORK`: Some custom /24 network. e.g. `192.168.42.0`
* `CLIENTS`: Number of clients for which configurations are to be created. Do not use more than 240 clients.

If no environment variables are set, config creation script will ask you for settings.

### Create config files

Run the service to create required keys and config files in directory `config.d`. It will print out used configuration params.

```
$ docker-compose run wg

Starting wireguard_wg_1 ... done
Attaching to wireguard_wg_1
wg_1  |  - Writing config to file tun0.conf
wg_1  |  - Using endpoint hostname example.com
wg_1  |  - Using port 51820
wg_1  |  - Using network 192.168.42.0/24
wg_1  |  - Generating 5 client configs and client QR codes
wireguard_wg_1 exited with code 0
```

### Run the service

Start the service in detached mode.

```
$ docker-compose up -d
```

### Add new client

Stop the service and run

```
$ docker-compose run wg add-client
```

This will create new client configuration and adds peer configuration to server config file.

### Show client config

Run command to show client configuration and QR code.

```
$ docker-compose run wg show-client 1
```

### Remove client

Stop the service and run

```
$ docker-compose run wg rm-client 1
```

This will remove client with id '1' (or any other client for different id) configuration.

### Remove configuration and create new one from scratch

Remove existing config files or rename device in `docker-compose.yml`. Run command `docker-compose up` again.

## Client configurations

You will find client configuration files for each client as config file and PNG file containing a QR code with
client configuration in directory `config.d`.