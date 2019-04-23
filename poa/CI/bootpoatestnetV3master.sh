#!/bin/sh

SCRIPT_DIR=`dirname $0`

help()  {

  echo "bootpoatestnetV3.sh OPTIONS
Usage:
REQUIRED:
        --gitlogin : login for private repo
        --gittoken : token for private repa
OPTIONAL:
        --stepDuration : delay between 2 blocks. Default: 2 sec
        --wallets : nb wallet create. Default: 10
        --eth     : eth amount (in wei) given to wallets Default: 10 ETH
        --rlc     : rlc amount (in nRLC) given to wallets Default: RLC ETH
        -h | --help
  "

}


isInteger() {
  if test ${1} -eq ${1} 2>/dev/null; then
    return 0
  fi
  return 1
}

#### MAIN

#default value
STEP_DURATION=2
NETWORK_ID_HOME=0x11
NETWORK_ID_FOREIGN=0x12
PASSWORD_LENGTH=24
NB_WALLETS=3
ETH_AMOUNT=10000000000000000000
RLC_AMOUNT=1000000000000000
GIT_LOGIN=""
GIT_TOKEN=""
TEST_IP=""
PARITY_DOCKER_VERSION=stable
REPO_WALLETS_TAG="master"
REPO_POCO_TAG="master"
REPO_PARITY_DEPLOY_TAG="master"
REPO_POA_BRIDGE_CONTRACTS="master"
REPO_TOKEN_BRIDGE="master"
REPO_BRIDGE_UI="master"
REPO_BRIDGE_MONITOR="master"
PASSWORD=""


ARGS="$@"

if [ $# -lt 2 ]
then
  echo "2 REQUIRED arguments needed"
  help
  exit 1
fi

while [ "$1" != "" ]; do
  case $1 in
    --wallets )               shift
      NB_WALLETS=$1
      ;;
    --stepDuration )          shift
      STEP_DURATION=$1
      ;;
    --eth )                   shift
      ETH_AMOUNT=$1
      ;;
    --rlc )                   shift
      RLC_AMOUNT=$1
      ;;
    --gitlogin )              shift
      GIT_LOGIN=$1
      ;;
    --gittoken )              shift
      GIT_TOKEN=$1
      ;;
    --test-ip )              shift
      TEST_IP=$1
      ;;
    --repo-wallet-tag )       shift
      REPO_WALLETS_TAG=$1
      ;;
    --repo-poco-tag )       shift
      REPO_POCO_TAG=$1
      ;;
    --repo-parity-deploy-tag )       shift
      REPO_PARITY_DEPLOY_TAG=$1
      ;;
    --repo-poa-bridge-contracts-tag )       shift
      REPO_POA_BRIDGE_CONTRACTS=$1
      ;;
    --repo-token-bridge-tag )       shift
      REPO_TOKEN_BRIDGE=$1
      ;;
    --repo-bridge-ui-tag )       shift
      REPO_BRIDGE_UI=$1
      ;;
    --repo-bridge-monitor-tag )       shift
      REPO_BRIDGE_MONITOR=$1
      ;;
    --password )       shift
      PASSWORD=$1
      ;;
    -h | --help )           help
      exit
      ;;
  esac
  shift
done

#overwrite env by .env
if [ -f ${SCRIPT_DIR}/.env ]
then
  export $(egrep -v '^#' ${SCRIPT_DIR}/.env | xargs)
fi


#check mandatory
if [ -z $GIT_LOGIN ] ; then
  echo "--gitlogin  arg is mandatory"
  help
  exit 1
fi

if [ -z $GIT_TOKEN ] ; then
  echo "--gittoken  arg is mandatory"
  help
  exit 1
fi

if [ -z $TEST_IP ] ; then
  echo "--test-ip  arg is mandatory"
  help
  exit 1
fi

if [ -z $PASSWORD ] ; then
  echo "--password arg is mandatory"
  help
  exit 1
fi



#check ${NB_WALLETS} integer
isInteger ${NB_WALLETS}
if [ $? -eq 1 ]
then
  echo "NB_WALLETS ${NB_WALLETS} must be an integer."
  exit 1
fi

isInteger ${STEP_DURATION}
if [ $? -eq 1 ]
then
  echo "STEP_DURATION ${STEP_DURATION} must be an integer."
  exit 1
fi


echo "git clone ..."
git clone -b $REPO_WALLETS_TAG  https://"$GIT_LOGIN":"$GIT_TOKEN"@github.com/iExecBlockchainComputing/wallets.git
git clone -b $REPO_POCO_TAG https://github.com/iExecBlockchainComputing/PoCo.git

git clone -b $REPO_PARITY_DEPLOY_TAG https://github.com/iExecBlockchainComputing/parity-deploy.git


##create docker network
docker network create parity-deploy_default

CURRENT_DIR=$(pwd)

#install ethkey
#git clone https://github.com/paritytech/parity-ethereum.git
#cd parity-ethereum
#cargo build -p ethkey-cli --release
#./target/release/ethkey --help
#sudo cp ./target/release/ethkey /usr/local/bin
#which ethkey

cd $CURRENT_DIR
cp -rf parity-deploy parity-deploy-home-chain
cp -rf parity-deploy parity-deploy-foreign-chain

echo "generate parity-deploy-home-chain"
cd parity-deploy-home-chain
echo "generate pwd"
./config/utils/pwdgen.sh -n 1 -l ${PASSWORD_LENGTH}
if [ $? -eq 1 ]
then
  echo "pwdgen.sh  script failed"
  exit 1
fi

echo "call parity-deploy script"

echo "target PARITY VERSION :$PARITY_DOCKER_VERSION"

./parity-deploy.sh --config aura --name HOME-CHAIN --nodes 1 --entrypoint "/bin/parity" --release $PARITY_DOCKER_VERSION --expose


sed -i 's/0x00Ea169ce7e0992960D3BdE6F5D539C955316432/0xabcd1339Ec7e762e639f4887E2bFe5EE8023E23E/g' deployment/chain/spec.json
sed -i "s/\"stepDuration\": \"2\"/\"stepDuration\": \"`echo $STEP_DURATION`\"/g" deployment/chain/spec.json
sed -i "s/\"networkID\" : \"0x11\"/\"networkID\" : \"`echo $NETWORK_ID_HOME`\"/g" deployment/chain/spec.json

#sed -i "s/stable/$PARITY_DOCKER_VERSION/g" docker-compose.yml
sed -i "s/host1/host-home-chain/g" docker-compose.yml


sed -i "s/d \/home\/parity\/data/d \/home\/parity\/data --force-sealing --logging sync=info,snapshot=debug,txqueue=trace,tx=trace,tx_filter=trace,rpc=trace/g" docker-compose.yml


sed -i "s/host1/host-home-chain/g" deployment/chain/reserved_peers
#cat ${SCRIPT_DIR}/parity-deploy-network.conf >> docker-compose.yml
echo "docker-compose up -d ..."
docker-compose up -d


cd $CURRENT_DIR
cd parity-deploy-foreign-chain
echo "generate parity-deploy-foreign-chain"
echo "generate pwd"
./config/utils/pwdgen.sh -n 1 -l ${PASSWORD_LENGTH}
if [ $? -eq 1 ]
then
  echo "pwdgen.sh  script failed"
  exit 1
fi

echo "call parity-deploy script"
echo "target PARITY VERSION :$PARITY_DOCKER_VERSION"
./parity-deploy.sh --config aura --name FOREIGN-CHAIN --nodes 1 --entrypoint "/bin/parity" --release $PARITY_DOCKER_VERSION  --expose


sed -i 's/0x00Ea169ce7e0992960D3BdE6F5D539C955316432/0xabcd1339Ec7e762e639f4887E2bFe5EE8023E23E/g' deployment/chain/spec.json
sed -i "s/\"stepDuration\": \"2\"/\"stepDuration\": \"`echo $STEP_DURATION`\"/g" deployment/chain/spec.json
sed -i "s/\"networkID\" : \"0x11\"/\"networkID\" : \"`echo $NETWORK_ID_FOREIGN`\"/g" deployment/chain/spec.json




#sed -i "s/stable/$PARITY_DOCKER_VERSION/g" docker-compose.yml
echo "change redirect port"
sed -i "s/- 8080/- 9080/g" docker-compose.yml
sed -i "s/- 8180/- 9180/g" docker-compose.yml
sed -i "s/- 8545/- 9545/g" docker-compose.yml
sed -i "s/- 8546/- 9546/g" docker-compose.yml
sed -i "s/- 30303/- 40303/g" docker-compose.yml
sed -i "s/host1/host-foreign-chain/g" docker-compose.yml
sed -i "s/d \/home\/parity\/data/d \/home\/parity\/data --force-sealing --logging sync=info,snapshot=debug,txqueue=trace,tx=trace,tx_filter=trace,rpc=trace/g" docker-compose.yml

sed -i "s/host1/host-foreign-chain/g" deployment/chain/reserved_peers
sed -i "s/30303/40303/g" deployment/chain/reserved_peers

#cat ${SCRIPT_DIR}/parity-deploy-network.conf >> docker-compose.yml
echo "docker-compose up -d ..."
docker-compose up -d




#ADMIN_PRIVATE_KEY=$(cat ../wallets/wallets/wallet-abc.json | grep privateKey | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g' | cut  -c3-)
iexec init --password $PASSWORD --force
ADMIN_PRIVATE_KEY=$(iexec wallet show --show-private-key --keystoredir /home/ubuntu/wallets/wallets --wallet-file wallet-abc.json --password $PASSWORD --raw | jq '.wallet.privateKey' | sed 's/\"//g')

ADMIN_ADDRESS=$(cat ../wallets/wallets/wallet-abc.json | grep address | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g')

echo "ADMIN_PRIVATE_KEY is $ADMIN_PRIVATE_KEY"
echo "ADMIN_ADDRESS is $ADMIN_ADDRESS"

cd $CURRENT_DIR
cp -rf PoCo PoCo-home-chain
cd PoCo-home-chain
#sed -i "s/\^5.0.0-beta.2/5.0.0-beta.2/g" package.json
#git checkout ABILegacy
#npm install truffle-hdwallet-provider@1.0.0-web3one.3
npm i

#npm install truffle@beta

#copy existing truffle.js
cp truffle.js truffle.ori


sed "s/__PRIVATE_KEY__/\"${ADMIN_PRIVATE_KEY}\"/g" ${SCRIPT_DIR}/truffleV3.tmpl > truffle.js


echo "launch truffle migrate"
./node_modules/.bin/truffle --version
rm -rf build
rm -rf truffle.log
./node_modules/.bin/truffle migrate --network localHomeChain | tee -a "truffle.log" 

if [ $? -eq 0 ]
then
  echo "truffle migrate success!"
else
  echo "truffle migrate FAILED !"
  exit 1
fi

echo "get RLC contract from truffle.log "
cat truffle.log | grep "RLC deployed at address:"

IexecHubAddress=$(cat build/contracts/IexecHub.json | grep '"address":' | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g')
#RlcAddress=$(cat build/contracts/RLC.json | grep '"address":' | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g')
echo "get RLC contract from truffle.log "
RlcAddress=$(cat truffle.log | grep "RLC deployed at address:" | cut -d ":" -f2 | sed 's/ //g')
echo "RlcAddress $RlcAddress"

if [ -z $IexecHubAddress ]
then
  "IexecHubAddress is not set"
  exit 1
fi
echo "IexecHubAddress is $IexecHubAddress"

cd $CURRENT_DIR
cp -rf PoCo PoCo-foreign-chain
cd PoCo-foreign-chain
#sed -i "s/\^5.0.0-beta.2/5.0.0-beta.2/g" package.json
#git checkout ABILegacy
npm i
#npm install truffle-hdwallet-provider@1.0.0-web3one.3
#npm install truffle@beta



#copy existing truffle.js
cp truffle.js truffle.ori


sed "s/__PRIVATE_KEY__/\"${ADMIN_PRIVATE_KEY}\"/g" ${SCRIPT_DIR}/truffleV3.tmpl > truffle.js


echo "launch truffle migrate"
./node_modules/.bin/truffle --version
rm -rf build
rm -rf truffle.log
./node_modules/.bin/truffle migrate --network localForeignChain | tee -a "truffle.log" 

if [ $? -eq 0 ]
then
  echo "truffle migrate success!"
else
  echo "truffle migrate FAILED !"
  exit 1
fi


IexecHubAddress=$(cat build/contracts/IexecHub.json | grep '"address":' | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g')
#RlcAddress=$(cat build/contracts/RLC.json | grep '"address":' | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g')
echo "get RLC contract from truffle.log "
RlcAddress=$(cat truffle.log | grep "RLC deployed at address:" | cut -d ":" -f2 | sed 's/ //g')
echo "RlcAddress $RlcAddress"

if [ -z $IexecHubAddress ]
then
  "IexecHubAddress is not set"
  exit 1
fi
echo "IexecHubAddress is $IexecHubAddress"



cd $CURRENT_DIR
cd wallets

# set the right IexecHub find in PoCo-dev/build/contracts/IexecClerk.json contract address
sed -i "s/0x60E25C038D70A15364DAc11A042DB1dD7A2cccBC/${IexecHubAddress}/g" chain.json


iexec --version
#workaround iexec-sdk :
mkdir -p ~/.ethereum/keystore
#end of workaround

#* in network id
sed -i "s/\"17\"/\"*\"/g" chain.json

# richman used in topUpWallets on homechain
./topUpWallets --base=admin --from=1 --to=${NB_WALLETS} --minETH=${ETH_AMOUNT} --maxETH=${ETH_AMOUNT} --chain=dev --minRLC=${RLC_AMOUNT}

sed -i "s/8545/9545/g" chain.json


# richman used in topUpWallets on foreinchain
./topUpWallets --base=admin  --from=1 --to=${NB_WALLETS} --minETH=${ETH_AMOUNT} --maxETH=${ETH_AMOUNT} --chain=dev --minRLC=${RLC_AMOUNT}


echo "POA test FOREIGN-CHAIN chain and HOME-CHAIN chain is installed and up "

############################################
#deploy poa smart contract  bridges on network
############################################
cd $CURRENT_DIR
echo "deploy smart contract poa bridges on network"

git clone -b $REPO_POA_BRIDGE_CONTRACTS https://github.com/iExecBlockchainComputing/poa-bridge-contracts.git
cd poa-bridge-contracts

# attach docker to parity-deploy network
#cat ${SCRIPT_DIR}/parity-deploy-network.conf >> docker-compose.yml

cp -rf ${SCRIPT_DIR}/poa-bridge-contracts-dev.env ${SCRIPT_DIR}/poa-bridge-contracts-dev.env.ori
sed -i "s/__ADMIN_WALLET_PRIVATEKEY__/${ADMIN_PRIVATE_KEY}/g" ${SCRIPT_DIR}/poa-bridge-contracts-dev.env
sed -i "s/__ADMIN_WALLET__/${ADMIN_ADDRESS}/g" ${SCRIPT_DIR}/poa-bridge-contracts-dev.env
sed -i "s/__ERC20_TOKEN_ADDRESS__/${RlcAddress}/g" ${SCRIPT_DIR}/poa-bridge-contracts-dev.env
sed -i "s/__HOME_RPC_URL__/http:\/\/${TEST_IP}:8545/g" ${SCRIPT_DIR}/poa-bridge-contracts-dev.env
sed -i "s/__FOREIGN_RPC_URL__/http:\/\/${TEST_IP}:9545/g" ${SCRIPT_DIR}/poa-bridge-contracts-dev.env



cp ${SCRIPT_DIR}/poa-bridge-contracts-dev.env deploy/.env
rm -f bridgeDeploy.log
./deploy.sh  | tee bridgeDeploy.log


HOME_BRIDGE_ADDRESS=$(cat bridgeDeploy.log | grep "address" | grep -v function | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g'| awk 'NR == 1')
HOME_ERC_677=$(cat bridgeDeploy.log | grep "address" | grep -v function | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g'| awk 'NR == 2')
FOREIGN_BRIDGE_ADDRESS=$(cat bridgeDeploy.log | grep "address" | grep -v function | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g'| awk 'NR == 3')
HOME_START_BLOCK=$(cat bridgeDeploy.log | grep "deployedBlockNumber" | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g'| awk 'NR == 1')
FOREIGN_START_BLOCK=$(cat bridgeDeploy.log | grep "deployedBlockNumber" | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g'| awk 'NR == 2')





############################################
# start poa bridge js
############################################
cd $CURRENT_DIR
git clone -b $REPO_TOKEN_BRIDGE https://github.com/iExecBlockchainComputing/token-bridge.git
cd token-bridge

# attach docker to parity-deploy network
#cat ${SCRIPT_DIR}/parity-deploy-network.conf >> docker-compose.yml

cp -rf ${SCRIPT_DIR}/token-bridge-dev.env ${SCRIPT_DIR}/token-bridge-dev.ori

sed -i "s/__ADMIN_WALLET_PRIVATEKEY__/${ADMIN_PRIVATE_KEY}/g" ${SCRIPT_DIR}/token-bridge-dev.env
sed -i "s/__ADMIN_WALLET__/${ADMIN_ADDRESS}/g" ${SCRIPT_DIR}/token-bridge-dev.env
sed -i "s/__ERC20_TOKEN_ADDRESS__/${RlcAddress}/g" ${SCRIPT_DIR}/token-bridge-dev.env
sed -i "s/__HOME_BRIDGE_ADDRESS__/${HOME_BRIDGE_ADDRESS}/g" ${SCRIPT_DIR}/token-bridge-dev.env
sed -i "s/__FOREIGN_BRIDGE_ADDRESS__/${FOREIGN_BRIDGE_ADDRESS}/g" ${SCRIPT_DIR}/token-bridge-dev.env
sed -i "s/__HOME_START_BLOCK__/${HOME_START_BLOCK}/g" ${SCRIPT_DIR}/token-bridge-dev.env
sed -i "s/__FOREIGN_START_BLOCK__/${FOREIGN_START_BLOCK}/g" ${SCRIPT_DIR}/token-bridge-dev.env
sed -i "s/__HOME_RPC_URL__/http:\/\/${TEST_IP}:8545/g" ${SCRIPT_DIR}/token-bridge-dev.env
sed -i "s/__FOREIGN_RPC_URL__/http:\/\/${TEST_IP}:9545/g" ${SCRIPT_DIR}/token-bridge-dev.env


cp ${SCRIPT_DIR}/token-bridge-dev.env .env


docker-compose up -d rabbit  
docker-compose up -d redis
# wait rabbit connection to be ready
sleep 30
docker-compose up -d --build

#docker-compose run -d bridge npm run watcher:signature-request
#docker-compose run -d bridge npm run watcher:collected-signatures
#docker-compose run -d bridge npm run watcher:affirmation-request
#docker-compose run -d bridge npm run sender:home
#docker-compose run -d bridge npm run sender:foreign



############################################
#deploy poa bridge UI
############################################

cd $CURRENT_DIR
git clone -b $REPO_BRIDGE_UI https://github.com/iExecBlockchainComputing/bridge-ui.git
cd bridge-ui
git submodule update --init --recursive --remote
npm install

sed -i "s/__HOME_BRIDGE_ADDRESS__/${HOME_BRIDGE_ADDRESS}/g" ${SCRIPT_DIR}/bridge-ui-dev.env
sed -i "s/__FOREIGN_BRIDGE_ADDRESS__/${FOREIGN_BRIDGE_ADDRESS}/g" ${SCRIPT_DIR}/bridge-ui-dev.env
sed -i "s/__REACT_APP_FOREIGN_HTTP_PARITY_URL__/http:\/\/$TEST_IP:9545/g" ${SCRIPT_DIR}/bridge-ui-dev.env
sed -i "s/__REACT_APP_HOME_HTTP_PARITY_URL__/http:\/\/$TEST_IP:8545/g" ${SCRIPT_DIR}/bridge-ui-dev.env

cp ${SCRIPT_DIR}/bridge-ui-dev.env .env


############################################
# deploy bridge monitor
############################################

#cd $CURRENT_DIR
#git clone -b $REPO_BRIDGE_MONITOR https://github.com/poanetwork/bridge-monitor.git
#cd bridge-monitor

#npm i

#sed -i "s/__HOME_BRIDGE_ADDRESS__/${HOME_BRIDGE_ADDRESS}/g" ${SCRIPT_DIR}/bridge-monitor-dev.env
#sed -i "s/__FOREIGN_BRIDGE_ADDRESS__/${FOREIGN_BRIDGE_ADDRESS}/g" ${SCRIPT_DIR}/bridge-monitor-dev.env
#sed -i "s/__FOREIGN_RPC_URL__/http:\/\/$TEST_IP:9545/g" ${SCRIPT_DIR}/bridge-monitor-dev.env
#sed -i "s/__HOME_RPC_URL__/http:\/\/$TEST_IP:8545/g" ${SCRIPT_DIR}/bridge-monitor-dev.env

#cp ${SCRIPT_DIR}/bridge-monitor-dev.env .env

# check balances of contracts and validators
#node checkWorker.js
# check unprocessed events
#node checkWorker2.js
# check stuck transfers called by transfer, not transferAndCall
# only applicable for bridge-rust-v1-native-to-erc
#node checkWorker3.js
# run web interface
#node index.js

#clean

cd $CURRENT_DIR
rm -rf parity-ethereum
rm -rf PoCo
rm -rf parity-deploy
exit 0
