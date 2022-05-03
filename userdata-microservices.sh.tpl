#!/bin/bash

set -x

apt-get update && apt-get install docker.io -y

docker run --name random-microservice -d chentex/random-logger:latest

docker run --name another-random-microservice -d chentex/random-logger:latest
