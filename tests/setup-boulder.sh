#!/bin/bash

set -e

acme_endpoint="http://boulder:4001/directory"

setup_boulder() {
  # Per the boulder README:
  nginx_proxy_ip="$(ifconfig nginx-proxy | grep "inet addr:" | cut -d: -f2 | awk '{ print $1}')"

  export GOPATH=${TRAVIS_BUILD_DIR}/go
  [[ ! -d $GOPATH/src/github.com/letsencrypt/boulder ]] \
    && git clone https://github.com/letsencrypt/boulder \
      $GOPATH/src/github.com/letsencrypt/boulder
  cd $GOPATH/src/github.com/letsencrypt/boulder
  git checkout release-2020-03-03
  sed --in-place 's/ 5002/ 80/g' test/config/va.json
  sed --in-place 's/ 5001/ 443/g' test/config/va.json
  docker-compose build --pull
  docker-compose run -d \
    --use-aliases \
    --name boulder \
    -e FAKE_DNS=$nginx_proxy_ip \
    --service-ports \
    boulder
  cd -
}

wait_for_boulder() {
  i=0
  until docker exec boulder bash -c "curl ${acme_endpoint:?} >/dev/null 2>&1"; do
    if [ $i -gt 300 ]; then
      echo "Boulder has not started for 5 minutes, timing out."
      exit 1
    fi
    i=$((i + 5))
    echo "$acme_endpoint : connection refused, Boulder isn't ready yet. Waiting."
    sleep 5
  done
}

setup_boulder
wait_for_boulder
