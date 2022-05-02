#!/bin/bash
sudo apt-get -y update
sudo apt-get -y install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
curl https://gist.githubusercontent.com/phunguyen19/054555e406df14067bb5d70300691bc6/raw/7c4d62254506827cb132c005ba8ab706ef51693f/docker-compose.yml > ~/docker-compose.yml
cd ~
sudo docker compose up -d