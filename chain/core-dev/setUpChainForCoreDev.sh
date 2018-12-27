#!/bin/bash
GIT_LOGIN=jeremyjames
GIT_TOKEN=

git clone https://"$GIT_LOGIN":"$GIT_TOKEN"@github.com/iExecBlockchainComputing/wallets.git

nohup ./mine.sh > log.txt &

sleep 4

cd /wallets

./deployAppAndPool
./topUpWallets --from=1 --to=10 --minETH=0 --maxETH=0 --minRLC=1000 --chain=dev
./deposit --from=1 --to=10 --rlc=1000 --chain=dev

pkill -INT parity

sleep 20


rm -R /wallets
