#!/bin/sh

SCRIPT_DIR=`dirname $0`

help()  {

  echo "bootpoatestnetV3.sh OPTIONS
Usage:
REQUIRED:
        --name    : blockchainName
        --nodes   : number_of_nodes
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
CHAIN_NAME=""
CHAIN_NODES=""
STEP_DURATION=2
PASSWORD_LENGTH=24
NB_WALLETS=10
ETH_AMOUNT=10000000000000000000
RLC_AMOUNT=10000000000
GIT_LOGIN=""
GIT_TOKEN=""
REPO_WALLETS_TAG="master"


ARGS="$@"

if [ $# -lt 2 ]
then
  echo "2 REQUIRED arguments needed"
  help
  exit 1
fi

while [ "$1" != "" ]; do
  case $1 in
    --name )          shift
      CHAIN_NAME=$1
      ;;
    --nodes )          shift
      CHAIN_NODES=$1
      ;;
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
    -h | --help )           help
      exit
      ;;
  esac
  shift
done

#overwrite env by .env
if [ -f .env ] 
then
  cat .env
  echo "REPO_WALLETS_TAG=$REPO_WALLETS_TAG"
  export $(egrep -v '^#' .env | xargs)
  echo "REPO_WALLETS_TAG=$REPO_WALLETS_TAG"
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

if [ -z $CHAIN_NAME ] ; then
  echo "--name  arg is mandatory"
  help
  exit 1
fi

if [ -z $CHAIN_NODES ] ; then
  echo "--nodes  arg is mandatory"
  help
  exit 1
fi

#check ${CHAIN_NODES} integer
isInteger ${CHAIN_NODES}
if [ $? -eq 1 ]
then
  echo "CHAIN_NODES ${CHAIN_NODES} must be an integer."
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
git clone https://"$GIT_LOGIN":"$GIT_TOKEN"@github.com/iExecBlockchainComputing/PoCo-dev.git

git clone https://github.com/paritytech/parity-deploy.git
cd parity-deploy
echo "generate pwd"

./config/utils/pwdgen.sh -n ${CHAIN_NODES} -l ${PASSWORD_LENGTH}
if [ $? -eq 1 ]
then
  echo "pwdgen.sh  script failed"
  exit 1
fi

echo "call parity-deploy script"

./parity-deploy.sh --config aura --name ${CHAIN_NAME} --nodes ${CHAIN_NODES} --ethstats --expose


sed -i 's/0x00Ea169ce7e0992960D3BdE6F5D539C955316432/0xabcd1339Ec7e762e639f4887E2bFe5EE8023E23E/g' deployment/chain/spec.json
sed -i "s/\"stepDuration\": \"2\"/\"stepDuration\": \"`echo $STEP_DURATION`\"/g" deployment/chain/spec.json



echo "docker-compose up -d ..."
docker-compose up -d

cd -



cd PoCo-dev
#git checkout ABILegacy
npm i
npm install truffle-hdwallet-provider@web3-one
#npm install truffle@beta

#copy existing truffle.js
cp truffle.js truffle.ori

PKEY=$(cat ../wallets/admin/wallet.json | grep privateKey | cut -d ":" -f2 | cut -d "," -f1)

sed "s/__PRIVATE_KEY__/${PKEY}/g" ${SCRIPT_DIR}/truffleV3.tmpl > truffle.js
#remove 0x of privatekey
sed -i 's/0x//' truffle.js

echo "launch truffle migrate"
./node_modules/.bin/truffle --version
rm -rf build
./node_modules/.bin/truffle migrate --network localPOAWithHDwallet

if [ $? -eq 0 ]
then
  echo "truffle migrate success!"
else
  echo "truffle migrate FAILED !"
  exit 1
fi

IexecHubAddress=$(cat build/contracts/IexecHub.json | grep '"address":' | cut -d ":" -f2 | cut -d "," -f1 | sed 's/\"//g' | sed 's/ //g')

if [ -z $IexecHubAddress ]
then
  "IexecHubAddress is not set"
  exit 1
fi
echo "IexecHubAddress is $IexecHubAddress"

cd -

cd wallets

# set the right IexecHub find in PoCo-dev/build/contracts/IexecClerk.json contract address
sed -i "s/0xc4e4a08bf4c6fd11028b714038846006e27d7be8/${IexecHubAddress}/g" admin/chain.json
sed -i 's/1337/17/g' admin/chain.json

iexec --version

rm -rf richman
mkdir richman
cp -rf admin/* richman
# richman used in topUpWallets
./topUpWallets --from=1 --to=${NB_WALLETS} --minETH=${ETH_AMOUNT} --maxETH=${ETH_AMOUNT} --chain=dev --minRLC=${RLC_AMOUNT}

echo "POA test chain ${CHAIN_NAME} is installed and up "
exit 0
