# ns8-grafana

This is a NS8 module for [Grafana OSS](https://grafana.com/).

## Install

Instantiate the module with:

    add-module ghcr.io/nethserver/grafana:latest 1

The output of the command will return the instance name.
Output example:

    {"module_id": "grafana1", "image_name": "grafana", "image_url": "ghcr.io/nethserver/grafana:latest"}

## Configure

Let's assume that the grafana instance is named `grafana1`.

Default credentials are: 
- user: `admin`
- password: `admin`

The password can be changed after the first login.

Launch `configure-module`, by setting the following parameters:
- `domain`: domain name for Grafana installation

Example:

    api-cli run module/grafana1/configure-module --data '{"domain": "grafana.nethserver.org"}'

The above command will:
- start and configure the grafana instance
- setup traefik route with HTTPS redirect and Let's Encrypt certficate
- setup local Loki and Prometheus instances
- setup default dashboards for node exporter and Loki

Send a test HTTP request to the grafana backend service:


### Monitor local node

To monitor the node execute:
```
add-module ghcr.io/nethserver/node_exporter:latest
add-module ghcr.io/nethserver/prometheus:latest
add-module ghcr.io/nethserver/grafana:latest
api-cli run module/grafana1/configure-module --data '{"domain": "grafana.nethserver.org"}'
``` 

At the end, access `https://grafana.nethserver.org/` to see a fully-functional Grafana installation monitoring the local node.

## Uninstall

To uninstall the instance:

    remove-module --no-preserve grafana1

## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/grafana:latest

The tests are made using [Robot Framework](https://robotframework.org/)
