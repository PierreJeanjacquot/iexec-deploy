#!/bin/sh

GIT_LOGIN=""
GIT_TOKEN=""

sudo npm -g install iexec@next
iexec --version

#clean up
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)


sudo rm -rf iexec-deploy
sudo rm -rf PoCo-dev
sudo rm -rf wallets
sudo rm -rf parity-deploy


git clone https://github.com/iExecBlockchainComputing/iexec-deploy.git
chmod +x ~/iexec-deploy/poa/test/bootpoatestnetV3.sh
sudo -i -u ubuntu ~/iexec-deploy/poa/test/bootpoatestnetV3.sh --name CI-TESTNET-CHECK --nodes 2 --gitlogin ${GIT_LOGIN} --gittoken ${GIT_TOKEN}
BOOTSTRAP_RESULT=$?
if [ $BOOTSTRAP_RESULT -eq 0 ]; then
    echo "SUCCESS ! start OK endpoint"
    sudo docker run -d -v ~/iexec-deploy/poa/test/CI-OK:/var/www:ro -p 9999:8080 trinitronx/python-simplehttpserver
else
    echo "FAILED ! start KO endpoint"
    sudo docker run -d -v ~/iexec-deploy/poa/test/CI-KO:/var/www:ro -p 9999:8080 trinitronx/python-simplehttpserver
fi
