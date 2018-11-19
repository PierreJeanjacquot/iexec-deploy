#!/bin/bash
GIT_LOGIN=jeremyjams
GIT_TOKEN=

git clone https://"$GIT_LOGIN":"$GIT_TOKEN"@github.com/iExecBlockchainComputing/PoCo-dev.git

nohup ./mine.sh > deployed.txt &

sleep 2

cd PoCo-dev && git checkout ABILegacy && npm install && ./node_modules/.bin/truffle migrate --chain development && cd ..

pkill -INT parity

sleep 10

#remove poco sources from image for now
rm -R PoCo-dev