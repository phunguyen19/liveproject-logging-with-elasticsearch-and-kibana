#!/bin/bash
sudo apt-get -y update
sudo apt-get -y install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
curl https://gist.githubusercontent.com/phunguyen19/b53b738ee03ee06bd9326adc6340d782/raw/f94fe01e61cb9e6bca6f83f920d9bc58efb51e17/docker-compose.yml > ~/docker-compose.yml
cd ~
sudo docker compose up -d