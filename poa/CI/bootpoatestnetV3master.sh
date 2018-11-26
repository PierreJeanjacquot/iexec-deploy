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
PASSWORD_LENGTH=24
NB_WALLETS=10
ETH_AMOUNT=10000000000000000000
RLC_AMOUNT=10000000000
GIT_LOGIN=""
GIT_TOKEN=""
PARITY_DOCKER_VERSION=stable
REPO_WALLETS_TAG="master"
REPO_POCO_TAG="master"
REPO_PARITY_DEPLOY_TAG="master"
REPO_POA_BRIDGE_CONTRACTS="master"
REPO_TOKEN_BRIDGE="master"
REPO_BRIDGE_UI="master"


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
git clone -b $REPO_POCO_TAG https://"$GIT_LOGIN":"$GIT_TOKEN"@github.com/iExecBlockchainComputing/PoCo-dev.git

git clone -b $REPO_PARITY_DEPLOY_TAG https://github.com/iExecBlockchainComputing/parity-deploy.git

CURRENT_DIR=$(pwd)
cp -rf parity-deploy parity-deploy-home-chain
cp -rf parity-deploy parity-deploy-foreign-chain

cd $CURRENT_DIR
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

./parity-deploy.sh --config aura --name HOME-CHAIN --nodes 1 --expose parity --unsafe-expose


sed -i 's/0x00Ea169ce7e0992960D3BdE6F5D539C955316432/0x000a9c787a972f70f0903890e266f41c795c4dca/g' deployment/chain/spec.json
sed -i "s/\"stepDuration\": \"2\"/\"stepDuration\": \"`echo $STEP_DURATION`\"/g" deployment/chain/spec.json


echo "target PARITY VERSION :$PARITY_DOCKER_VERSION"
sed -i "s/stable/$PARITY_DOCKER_VERSION/g" docker-compose.yml
sed -i "s/host1/host-home-chain/g" docker-compose.yml
sed -i "s/host1/host-home-chain/g" deployment/chain/reserved_peers


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

./parity-deploy.sh --config aura --name FOREIGN-CHAIN --nodes 1  --expose  parity --unsafe-expose


sed -i 's/0x00Ea169ce7e0992960D3BdE6F5D539C955316432/0x000a9c787a972f70f0903890e266f41c795c4dca/g' deployment/chain/spec.json
sed -i "s/\"stepDuration\": \"2\"/\"stepDuration\": \"`echo $STEP_DURATION`\"/g" deployment/chain/spec.json


echo "target PARITY VERSION :$PARITY_DOCKER_VERSION"
sed -i "s/stable/$PARITY_DOCKER_VERSION/g" docker-compose.yml
echo "change redirect port"
sed -i "s/- 8080/- 9080/g" docker-compose.yml
sed -i "s/- 8180/- 9180/g" docker-compose.yml
sed -i "s/- 8545/- 9545/g" docker-compose.yml
sed -i "s/- 8546/- 9546/g" docker-compose.yml
sed -i "s/- 30303/- 40303/g" docker-compose.yml
sed -i "s/host1/host-foreign-chain/g" docker-compose.yml
sed -i "s/host1/host-foreign-chain/g" deployment/chain/reserved_peers
sed -i "s/30303/40303/g" deployment/chain/reserved_peers


echo "docker-compose up -d ..."
docker-compose up -d


cd $CURRENT_DIR
cd PoCo-dev
#git checkout ABILegacy
npm i
npm install truffle-hdwallet-provider@web3-one
#npm install truffle@beta

#copy existing truffle.js
cp truffle.js truffle.ori

ADMIN_PRIVATE_KEY=$(cat ../wallets/scheduler/wallet.json | grep privateKey | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g' | cut  -c3-)
ADMIN_ADDRESS=$(cat ../wallets/scheduler/wallet.json | grep address | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g')


sed "s/__PRIVATE_KEY__/\"${ADMIN_PRIVATE_KEY}\"/g" ${SCRIPT_DIR}/truffleV3.tmpl > truffle.js


echo "launch truffle migrate"
./node_modules/.bin/truffle --version
rm -rf build
./node_modules/.bin/truffle migrate --network localHomeChain

if [ $? -eq 0 ]
then
  echo "truffle migrate success!"
else
  echo "truffle migrate FAILED !"
  exit 1
fi

IexecHubAddress=$(cat build/contracts/IexecHub.json | grep '"address":' | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g')
RlcAddress=$(cat build/contracts/IexecHub.json | grep '"address":' | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g')

if [ -z $IexecHubAddress ]
then
  "IexecHubAddress is not set"
  exit 1
fi
echo "IexecHubAddress is $IexecHubAddress"

./node_modules/.bin/truffle migrate --network localForeignChain

if [ $? -eq 0 ]
then
  echo "truffle migrate success!"
else
  echo "truffle migrate FAILED !"
  exit 1
fi


cd $CURRENT_DIR
cd wallets

# set the right IexecHub find in PoCo-dev/build/contracts/IexecClerk.json contract address
sed -i "s/0x60E25C038D70A15364DAc11A042DB1dD7A2cccBC/${IexecHubAddress}/g" scheduler/chain.json
#sed -i 's/1337/17/g' admin/chain.json

iexec --version

# richman used in topUpWallets
./topUpWallets --from=1 --to=${NB_WALLETS} --minETH=${ETH_AMOUNT} --maxETH=${ETH_AMOUNT} --chain=dev --minRLC=${RLC_AMOUNT}

echo "POA test FOREIGN-CHAIN chain and HOME-CHAIN chain is installed and up "



############################################
#deploy poa smart contract  bridges on network
############################################
cd $CURRENT_DIR
echo "deploy smart contract poa bridges on network"

git clone -b $REPO_POA_BRIDGE_CONTRACTS https://github.com/poanetwork/poa-bridge-contracts.git
cd poa-bridge-contracts

# attach docker to parity-deploy network
cat ${SCRIPT_DIR}/parity-deploy-network.conf >> docker-compose.yml

cp -rf ${SCRIPT_DIR}/poa-bridge-contracts-dev.env ${SCRIPT_DIR}/poa-bridge-contracts-dev.env.ori
sed -i "s/__ADMIN_WALLET_PRIVATEKEY__/${ADMIN_PRIVATE_KEY}/g" ${SCRIPT_DIR}/poa-bridge-contracts-dev.env
sed -i "s/__ADMIN_WALLET__/${ADMIN_ADDRESS}/g" ${SCRIPT_DIR}/poa-bridge-contracts-dev.env
sed -i "s/__ERC20_TOKEN_ADDRESS__/${RlcAddress}/g" ${SCRIPT_DIR}/poa-bridge-contracts-dev.env

cp ${SCRIPT_DIR}/poa-bridge-contracts-dev.env deploy/.env
rm -f bridgeDeploy.log
./deploy.sh  | tee bridgeDeploy.log

############################################
# start poa bridge js
############################################
cd $CURRENT_DIR
git clone -b $REPO_TOKEN_BRIDGE https://github.com/poanetwork/token-bridge.git
cd token-bridge

# attach docker to parity-deploy network
cat ${SCRIPT_DIR}/parity-deploy-network.conf >> docker-compose.yml

cp -rf ${SCRIPT_DIR}/token-bridge-dev.env ${SCRIPT_DIR}/token-bridge-dev.ori

sed -i "s/__ADMIN_WALLET_PRIVATEKEY__/${ADMIN_PRIVATE_KEY}/g" ${SCRIPT_DIR}/token-bridge-dev.env
sed -i "s/__ADMIN_WALLET__/${ADMIN_ADDRESS}/g" ${SCRIPT_DIR}/token-bridge-dev.env
sed -i "s/__ERC20_TOKEN_ADDRESS__/${RlcAddress}/g" ${SCRIPT_DIR}/token-bridge-dev.env

cp ${SCRIPT_DIR}/token-bridge-dev.env .env

docker-compose up -d --build


docker-compose run -d bridge npm run watcher:signature-request
docker-compose run -d bridge npm run watcher:collected-signatures
docker-compose run -d bridge npm run watcher:affirmation-request
docker-compose run -d bridge npm run sender:home
docker-compose run -d bridge npm run sender:foreign


############################################
#deploy poa bridge UI
############################################

cd $CURRENT_DIR
git clone -b $REPO_BRIDGE_UI https://github.com/poanetwork/bridge-ui.git
cd bridge-ui
git submodule update --init --recursive --remote
npm install
cp ${SCRIPT_DIR}/bridge-ui-dev.env .env
npm run start


exit 0
