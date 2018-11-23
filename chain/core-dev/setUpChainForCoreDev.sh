#!/bin/bash
GIT_LOGIN=jeremyjams
GIT_TOKEN=

git clone https://"$GIT_LOGIN":"$GIT_TOKEN"@github.com/iExecBlockchainComputing/wallets.git

nohup ./mine.sh > log.txt &

sleep 4

cd wallets

 ./deployAppAndPool 
 ./topUpWallets --from=1 --to=2 --minETH=0 --maxETH=0 --minRLC=1000 --chain=dev
 ./deposit --from=1 --to=2 --rlc=1000 --chain=dev

sleep 10

pkill -INT parity

sleep 15


rm -R wallets
