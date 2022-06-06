#!/bin/bash

set -x

apt-get update && apt-get install docker.io -y

export ES_IP=`dig ${es_endpoint} +short`

cat <<EOT >> fluentd_docker.conf
${file("fluentd_docker.conf")}
EOT

docker run --name fluentd -it -p 24224:24224 -v $(pwd)/fluentd_docker.conf:/fluentd/etc/fluentd_docker.conf -e FLUENTD_CONF=fluentd_docker.conf -d phunguyen19/fluentd-es7

docker run --log-driver=fluentd --name random-microservice -d chentex/random-logger:latest

docker run --log-driver=fluentd --name another-random-microservice -d chentex/random-logger:latest
