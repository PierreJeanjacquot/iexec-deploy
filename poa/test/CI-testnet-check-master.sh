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

sudo rm -rf /home/ubuntu/iexec-deploy
sudo rm -rf /home/ubuntu/PoCo-dev
sudo rm -rf /home/ubuntu/wallets
sudo rm -rf /home/ubuntu/parity-deploy


git clone https://github.com/iExecBlockchainComputing/iexec-deploy.git
mv iexec-deploy /home/ubuntu/
chown -R ubuntu:ubuntu /home/ubuntu/iexec-deploy
chmod 755 /home/ubuntu/iexec-deploy/poa/test/bootpoatestnetV3master.sh
sudo -i -u ubuntu /home/ubuntu/iexec-deploy/poa/test/bootpoatestnetV3master.sh --name CI-TESTNET-CHECK --nodes 2 --gitlogin ${GIT_LOGIN} --gittoken ${GIT_TOKEN}
BOOTSTRAP_RESULT=$?
if [ $BOOTSTRAP_RESULT -eq 0 ]; then
    echo "SUCCESS ! start OK endpoint"
    docker stop $(docker ps -a -q)
    sudo docker run -d -v /home/ubuntu/iexec-deploy/poa/test/CI-OK:/var/www:ro -p 9999:8080 trinitronx/python-simplehttpserver
else
    echo "FAILED ! start KO endpoint"
    docker stop $(docker ps -a -q)
    sudo docker run -d -v /home/ubuntu/iexec-deploy/poa/test/CI-KO:/var/www:ro -p 9999:8080 trinitronx/python-simplehttpserver
fi
