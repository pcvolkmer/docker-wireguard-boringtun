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

* `DEVICE`: Some `tun` device, defaults to `tun0`
* `SERVER_HOST`: The host name of your server
* `SERVER_PORT`: The port the service should listen at
* `NETWORK`: Some custom /24 network. Defaults to `192.168.42.0`
* `MTU`: MTU to be used. Use default wireguard MTU if not set.
* `CLIENTS`: Number of clients for which configurations are to be created. Do not use more than 240 clients.
* `DISABLE_FORWARD_ALL_TRAFFIC`: Use `true` or `yes` to not add iptables rules and do not forward all traffic.

If a required environment variable is not set, config creation script will end with an error.

### Create config files

Run the service to create required keys and config files in directory `config.d`. It will print out used configuration params.

```
$ docker-compose run wg init

Starting wireguard_wg_1 ... done
Attaching to wireguard_wg_1
wg_1  |  - Writing config to file tun0.conf
wg_1  |  - Using endpoint hostname example.com
wg_1  |  - Using port 51820
wg_1  |  - Using network 192.168.42.0/24
wg_1  |  - Using default MTU
wg_1  |  - Forward all traffic
wg_1  |  - Generating 5 client configs
wireguard_wg_1 exited with code 0
```

To disable traffic forwarding set `DISABLE_FORWARD_ALL_TRAFFIC` to `true` or `yes` or use

```
$ docker-compose run wg init --no-forward
```

### Start the service

Start the service in detached mode.

```
$ docker-compose up -d
```
If creation of config files was skipped, configuration files will be created on first start.

### List server and client configs

```
$ docker-compose run wg ls
```

### Add new client

Stop the service and run

```
$ docker-compose run wg add
```

This will create new client configuration and adds peer configuration to server config file. Restart service.

To add a client with existing public key run

```
$ docker-compose run wg add <given public key>
```

and replace `<given public key>` in command with public key created using `wg genkey`.
The created client config will contain a placeholder for clients secret key in interface config.

```
...
[Interface]
Address = 192.168.42.123/24
ListenPort = 51820
PrivateKey = <place secret key here>
...
```

### Remove client

Stop the service and run

```
$ docker-compose run wg rm 1
```

This will remove client with id '1' (or any other client for different id) configuration. Restart service.

### Show client config

Run command to show client configuration and QR code.

```
$ docker-compose run wg show 1
```

### Remove configuration and create new one from scratch

Stop the service and run the following command to remove existing config files.

```
$ docker-compose run wg purge
```
Reinitialize configureation

```
$ docker-compose run wg init
```

Restart service.

## Client configurations

You will find client configuration files for each client as config file and PNG file containing a QR code with
client configuration in directory `config.d`.