#!/bin/sh

GIT_LOGIN=""
GIT_TOKEN=""
TEST_IP=""

SCRIPT_DIR=`dirname $0`


IEXEC_SDK=next
#overwrite env by .env
if [ -f ${SCRIPT_DIR}/.env ]
then
  export $(egrep -v '^#' ${SCRIPT_DIR}/.env | xargs)
fi

sudo npm -g install iexec@$IEXEC_SDK
iexec --version

#clean up
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)
docker network rm $(docker network ls | grep "bridge" | awk '/ / { print $1 }')


sudo rm -rf iexec-deploy
sudo rm -rf PoCo-dev
sudo rm -rf PoCo-dev-home-chain
sudo rm -rf PoCo-dev-foreign-chain
sudo rm -rf wallets
sudo rm -rf parity-deploy
sudo rm -rf parity-deploy-home-chain
sudo rm -rf parity-deploy-foreign-chain
sudo rm -rf poa-bridge-contracts
sudo rm -rf token-bridge
sudo rm -rf bridge-ui
sudo rm -rf bridge-monitor


sudo rm -rf /home/ubuntu/iexec-deploy
sudo rm -rf /home/ubuntu/PoCo-dev
sudo rm -rf /home/ubuntu/PoCo-dev-home-chain
sudo rm -rf /home/ubuntu/PoCo-dev-foreign-chain
sudo rm -rf /home/ubuntu/wallets
sudo rm -rf /home/ubuntu/parity-deploy
sudo rm -rf /home/ubuntu/parity-deploy-home-chain
sudo rm -rf /home/ubuntu/parity-deploy-foreign-chain
sudo rm -rf /home/ubuntu/poa-bridge-contracts
sudo rm -rf /home/ubuntu/token-bridge
sudo rm -rf /home/ubuntu/bridge-ui
sudo rm -rf /home/ubuntu/bridge_data/
sudo rm -rf /home/ubuntu/parity-ethereum
sudo rm -rf /home/ubuntu/bridge-monitor


npm
git clone https://github.com/iExecBlockchainComputing/iexec-deploy.git
mv iexec-deploy /home/ubuntu/
chown -R ubuntu:ubuntu /home/ubuntu/iexec-deploy
chmod 755 /home/ubuntu/iexec-deploy/poa/CI/bootpoatestnetV3master.sh
sudo -i -u ubuntu /home/ubuntu/iexec-deploy/poa/CI/bootpoatestnetV3master.sh --gitlogin ${GIT_LOGIN} --gittoken ${GIT_TOKEN} --test-ip ${TEST_IP}
BOOTSTRAP_RESULT=$?
if [ $BOOTSTRAP_RESULT -eq 0 ]; then
    echo "SUCCESS ! start OK endpoint"
    #docker stop $(docker ps -a -q)
    sudo docker run -d -v /home/ubuntu/iexec-deploy/poa/CI/CI-OK:/var/www:ro -p 9999:8080 trinitronx/python-simplehttpserver
else
    echo "FAILED ! start KO endpoint"
    #docker stop $(docker ps -a -q)
    sudo docker run -d -v /home/ubuntu/iexec-deploy/poa/CI/CI-KO:/var/www:ro -p 9999:8080 trinitronx/python-simplehttpserver
fi
