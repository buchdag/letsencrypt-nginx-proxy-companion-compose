#!/bin/bash

set -e

test_domain="le1.wtf"
boulder_ip="10.77.77.1"

# shellcheck source=test-functions.sh
source ${TRAVIS_BUILD_DIR}/tests/test-functions.sh

echo "Testing compose file $1"

cp -f "$1" ./

letsencrypt_container_name=$(yq read docker-compose.yaml services.letsencrypt.container_name)

yq write --inplace docker-compose.yaml \
  services.letsencrypt.environment[+] \
  DEBUG=true

yq write --inplace docker-compose.yaml \
  services.letsencrypt.environment[+] \
  ACME_CA_URI=http://${boulder_ip}:4000/directory

yq write --inplace docker-compose.yaml \
  services.letsencrypt.environment[+] \
  ACME_TOS_HASH=b16e15764b8bc06c5c3f9f19bc8b99fa48e7894aa5a6ccdad65da49bbf564793

yq write --inplace docker-compose.yaml \
  services.letsencrypt.extra_hosts[+] \
  "boulder:${boulder_ip}"

yq read docker-compose.yaml

docker-compose -p nginx-proxy up -d

docker run --rm --detach \
  --name webapp-test \
  --network nginx-proxy \
  --env "VIRTUAL_HOST=$test_domain" \
  --env "VIRTUAL_PORT=80" \
  --env "LETSENCRYPT_HOST=$test_domain" \
  --env "LETSENCRYPT_EMAIL=foo@bar.com" \
  nginx:alpine

wait_for_cert $test_domain $letsencrypt_container_name

created_cert="$(docker exec $letsencrypt_container_name openssl x509 -in /etc/nginx/certs/$test_domain/cert.pem -text -noout)"

if grep -q "$test_domain" <<< "$created_cert"; then
  echo "$test_domain is on certificate."
else
  echo "$test_domain did not appear on certificate."
  exit 1
fi

wait_for_conn $test_domain

served_cert="$(echo \
  | openssl s_client -showcerts -servername $test_domain -connect $test_domain:443 2>/dev/null \
  | openssl x509 -inform pem -text -noout)"

if [ "$created_cert" != "$served_cert" ]; then
  echo "Nginx served an incorrect certificate for $test_domain."
  diff -u <"$(echo "$created_cert")" <"$(echo "$served_cert")"
  exit 1
else
  echo "The correct certificate for $test_domain was served by Nginx."
fi
