#!/bin/sh

GIT_LOGIN=""
GIT_TOKEN=""

#clean up
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)

cd

rm -rf iexec-deploy

git clone https://github.com/iExecBlockchainComputing/iexec-deploy.git
cd iexec-deploy/poa/test/
chmod +x bootpoatestnetV3.sh
sudo -u ubuntu 'bootpoatestnetV3.sh --name homechain --nodes 1 --gitlogin ${GIT_LOGIN} --gittoken ${GIT_TOKEN}'
