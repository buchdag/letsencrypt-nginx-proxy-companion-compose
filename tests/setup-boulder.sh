#!/bin/bash

set -e

SERVER="http://10.77.77.1:4000/directory"

setup_boulder() {
  # Per the boulder README:
  nginx_proxy_ip=$(ifconfig nginx-proxy | grep "inet addr:" | cut -d: -f2 | awk '{ print $1}')

  export GOPATH=${HOME?}/go
  git clone --depth=1 https://github.com/letsencrypt/boulder \
    $GOPATH/src/github.com/letsencrypt/boulder
  cd $GOPATH/src/github.com/letsencrypt/boulder
  sed --in-place 's/ 5002/ 80/g' test/config/va.json
  sed --in-place 's/ 5001/ 443/g' test/config/va.json
  docker-compose build --pull
  docker-compose run \
    --use-aliases \
    -e FAKE_DNS=$nginx_proxy_ip \
    --service-ports \
    boulder &
  cd -
}

wait_for_boulder() {
  i=0
  until curl ${SERVER?} >/dev/null 2>&1; do
    if [ $i -gt 300 ]; then
      echo "Boulder has not started for 5 minutes, timing out."
      exit 1
    fi
    i=$((i + 5))
    echo "$SERVER : connection refused. Waiting."
    sleep 5
  done
}

setup_boulder
wait_for_boulder
