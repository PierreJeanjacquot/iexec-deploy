#!/bin/bash
GIT_LOGIN=jeremyjams
GIT_TOKEN=

git clone https://"$GIT_LOGIN":"$GIT_TOKEN"@github.com/iExecBlockchainComputing/PoCo-dev.git

nohup ./mine.sh > deployed.txt &

sleep 2

cd PoCo-dev && git checkout 1a0bf1eebb0ada205180505656690ca6a8dc5a0a && npm install && ./node_modules/.bin/truffle migrate --chain development && cd ..

pkill -INT parity

sleep 20

#remove poco sources from image for now
rm -R PoCo-dev
