#!/bin/bash

set -e

wait_for_cert() {
  local i=0
  echo "Waiting for the ${2:?} container to generate the certificate for ${1:?}."
  until docker exec ${2:?} [ -f /etc/nginx/certs/${1:?}/cert.pem ]; do
    if [ $i -gt 240 ]; then
      echo "Certificate for ${1:?} was not generated under four minutes, timing out."
      exit 1
    fi
    i=$((i + 2))
    sleep 2
  done
  echo "Certificate for ${1:?} has been generated."
}

wait_for_conn() {
  local i=0
  echo "Waiting for a successful connection to http://${1:?}"
  until curl -k https://${1:?} > /dev/null 2>&1; do
    if [ $i -gt 60 ]; then
      echo "Could not connect to ${1:?} using https under one minute, timing out."
      exit 1
    fi
    i=$((i + 2))
    sleep 2
  done
  echo "Connection to ${1:?} using https was successfull."
}
