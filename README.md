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
- `host`: domain name for Grafana installation
- `lets_encrypt`: boolean, if set to true traefik will request a valid Let's Encrypt certificate
- `http2https`: boolean, if set to true traefik will redirct HTTP request to HTTPS

Example:

    api-cli run module/grafana1/configure-module --data '{"host": "grafana.nethserver.org", "http2https": true, "lets_encrypt": false}'

The above command will:
- start and configure the grafana instance
- setup traefik route with HTTPS redirect and Let's Encrypt certificate
- setup local Loki and Prometheus instances
- setup default dashboards for node exporter and Loki

Send a test HTTP request to the grafana backend service:


### Monitor local node

To monitor the node execute:
```
add-module ghcr.io/nethserver/node_exporter:latest
add-module ghcr.io/nethserver/prometheus:latest
add-module ghcr.io/nethserver/grafana:latest
api-cli run module/grafana1/configure-module --data '{"host": "grafana.nethserver.org", "http2https": true, "lets_encrypt": false}'
``` 

At the end, access `https://grafana.nethserver.org/` to see a fully-functional Grafana installation monitoring the local node.

### Bundled dashboards

The module contains some dashboards ready to be used.
To add new dashboard just drop the exported JSON inside `imageroot/etc/dashboards` directory.

## Uninstall

To uninstall the instance:

    remove-module --no-preserve grafana1

## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/grafana:latest

The tests are made using [Robot Framework](https://robotframework.org/)

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org](https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
