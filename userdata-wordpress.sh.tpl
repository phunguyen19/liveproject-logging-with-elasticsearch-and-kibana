#!/bin/bash

set -x

apt-get update && apt-get install docker.io -y

docker run --name main-wordpress-site -p 80:80 -d wordpress:latest
