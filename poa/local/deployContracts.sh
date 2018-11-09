#!/bin/bash
GIT_LOGIN=
GIT_TOKEN=

git clone https://"$GIT_LOGIN":"$GIT_TOKEN"@github.com/iExecBlockchainComputing/PoCo-dev.git

nohup ./mine.sh > deployed.txt &

sleep 2

cd PoCo-dev && git checkout testdocker && npm install && ./node_modules/.bin/truffle migrate --chain development && ./node_modules/.bin/truffle test test/matchOrder.js  --chain development && cd ..

pkill -INT parity

sleep 10

#remove poco sources from image for now
rm -R PoCo-dev
