[![Build Status](https://travis-ci.org/buchdag/letsencrypt-nginx-proxy-companion-compose.svg?branch=master)](https://travis-ci.org/buchdag/letsencrypt-nginx-proxy-companion-compose)

## letsencrypt_nginx_proxy_companion with docker-compose

This repository contains reference docker-compose files for a variety of [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) with [letsencrypt-nginx-proxy-companion](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion) setups :

```
.
├── 2-containers
│   ├── compose-v2
│   └── compose-v3
│       ├── environment
│       └── labels
└── 3-containers
    ├── compose-v2
    │   ├── environment
    │   └── labels
    └── compose-v3
        ├── environment
        └── labels
```

### Before your start

Be sure to be familiar with the [basic, non compose use of this container with nginx-proxy](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion/blob/master/README.md).

All the docker-compose file assume the existence of a docker network called `nginx-proxy`. You'll have to create it with `docker network create nginx-proxy` before you can use any of the example file.

For **letsencrypt-nginx-proxy-companion** to work properly, it needs to know the id of the nginx-proxy container, or the id of both the nginx and docker-gen containers in a three container setup.

If you start your stack using the `docker run` commands from the examples, the letsencrypt container will automatically find the id of the nginx (or nginx-proxy) container through the volume it gets with the `--volumes_from` option.

This options also exists in compose file version 2, but not on compose file version 3, meaning that if you use a version 3 file, it needs to use one the two ways to make the letsencrypt container aware of the nginx/nginx-proxy container id. Those two methodes are:

* adding the label `com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy`to the  nginx/nginx-proxy container.
* assigning a fixed name to the nginx/nginx-proxy container with `container_name:` and setting the environment variable `NGINX_PROXY_CONTAINER` to this name on the letsencrypt container.

On a three container setup, the letsencrypt container has no automated way to get the id of the docker-gen container, so in this setup, you'll need to use one of those two methods (wether you use a compose file version 2 or 3):

* adding the label `com.github.jrcs.letsencrypt_nginx_proxy_companion.docker_gen`to the  docker-gen container.
* assigning a fixed name to the docker-gen container with `container_name:` and setting the environment variable `NGINX_DOCKER_GEN_CONTAINER` to this name on the letsencrypt container.

The docker-compose files on `environment` subfolders use the environment variable method.

The docker-compose files on `labels` subfolders use the label method.

The advantage the `labels` method has over the `environment` method is enabling the use of the letsencrypt-nginx-proxy-docker-companion in Swarm Mode or in Docker Cloud, where containers names are dynamic. Howhever if you intend to do so, as upstream docker-gen lacks the ability to identify containers from labels, you'll need both to use the three container setup and to replace jwilder/docker-gen with a fork that has this ability like [herlderco/docker-gen](https://github.com/helderco/docker-gen). Be advised that for now, this works to a very limited extent [(everything has to be on the same node)](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion/pull/231#issuecomment-330624331).

As for the rest of the subfolders:

* `2-containers` are setup using nginx-proxy + letsencrypt_nginx_proxy_companion
* `3-containers` are setup using nginx + docker-gen + letsencrypt_nginx_proxy_companion
* `compose-v2` are compose file version 2 making use of `volumes_from:`
* `compose-v3` are compose file version 3

The simplest, most straightforward setup is [two containers using compose file version 2](2-containers/compose-v2/docker-compose.yaml).

### Usage

1. get the `docker-compose.yaml` corresponding to the setup you want to start from.
2. if you use a three containers setup, don't forget to get the `nginx.tmpl` file and put next to the `docker-compose.yaml` file.
3. create the required docker network with `docker network create nginx-proxy`.
4. launch the stack in detached mode with `docker-compose up -d`

Once your `nginx-proxy` stack is up and running you can launch proxyed containers from the command line (don't forget to connect them to the nginx-proxy network):

```
docker run -d \
    --name example-webapp \
    --network nginx-proxy \
    --expose 80 \
    -e "VIRTUAL_HOST=subdomain.yourdomain.tld" \
    -e "VIRTUAL_PORT=80" \
    -e "LETSENCRYPT_HOST=subdomain.yourdomain.tld" \
    -e "LETSENCRYPT_EMAIL=mail@yourdomain.tld" \
    nginx
```

Or with a compose file:

```
version: '3'

services:
  web:
    image: nginx:alpine
    container_name: example-webapp
    expose:
      - "80"
    environment:
      - VIRTUAL_HOST=subdomain.yourdomain.tld
      - VIRTUAL_PORT=80
      - LETSENCRYPT_HOST=subdomain.yourdomain.tld
      - LETSENCRYPT_EMAIL=mail@yourdomain.tld
    restart: always

networks:
  default:
    external:
      name: nginx-proxy
```

In both case `--expose` (or `expose:`) and the `VIRTUAL_PORT` environment variable probably won't be required, but they are an added precaution toward a working setup if you use them correctly.

In any case all those compose files are mostly there to serve as "known working" base examples of a nginx-proxy + letsencrypt stack the way I use it, in a variety of setup. Do not hesitate to tinker and customise them to fit your particular need.
