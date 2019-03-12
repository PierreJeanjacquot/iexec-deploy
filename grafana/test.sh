#!/bin/bash
MINETHEREUM=0.25
DEPOSIT=10
HUBCONTRACT=0x759b25b358b9f9c18812a69c0a9cf8b5a11c2e2d

# Function that prints messages
function message() {
  echo "[$1] $2"
  if [ "$1" == "ERROR" ]; then
    read -p "Press [Enter] to exit..."
    exit 1
  fi
}

# Launch iexec sdk function
function iexec {
  # docker run --user root -e DEBUG=$DEBUG --interactive --tty --rm -v $(pwd):/iexec-project -w /iexec-project iexechub/iexec-sdk "$@"
  docker run -e DEBUG=$DEBUG --interactive --tty --rm -v /tmp:/tmp -v $(pwd):/iexec-project -v /home/$(whoami)/.ethereum/keystore:/home/node/.ethereum/keystore -w /iexec-project iexechub/iexec-sdk:next "$@"
}

# Function which checks exit status and stops execution
function checkExitStatus() {
  if [ $1 -eq 0 ]; then
    message "OK" ""
  else
    message "ERROR" "$2"
  fi
}


WALLET_SELECTED=0
for file in ~/.ethereum/keystore/*; do

	if [[ -f $file ]]; then
		echo "Found wallet in $file"
		WALLET_ADDR=$(cat $file | jq .address | sed "s/\"//g")

        while [ "$answerwalletuse" != "yes" ] && [ "$answerwalletuse" != "no" ]; do
            read -p "Do you want to use wallet 0x$WALLET_ADDR? [yes/no] " answerwalletuse
        done

        if [ "$answerwalletuse" == "yes" ]; then
        	read -p "Please provide the password of wallet $WALLET_ADDR: " WORKERWALLETPASSWORD  
        	WALLET_FILE=$file
        	WALLET_SELECTED=1

            rm -fr /tmp/iexec
            mkdir /tmp/iexec
            cd /tmp/iexec

            iexec init --skip-wallet --force >/dev/null
            checkExitStatus $? "Can't init iexec sdk."

            iexec wallet show --wallet-address $WALLET_ADDR --password "$WORKERWALLETPASSWORD"
            checkExitStatus $? "Invalid wallet password."
        	break;
        fi

        unset answerwalletuse
    fi
done


if [ "$WALLET_SELECTED" == 0 ]; then

	echo "No wallet was selected..."
	while [ "$answerwalletcreate" != "yes" ] && [ "$answerwalletcreate" != "no" ]; do
        read -p "Do you want to create a wallet? [yes/no] " answerwalletcreate
    done

    if [ "$answerwalletcreate" == "yes" ]; then
    	
        # Get wallet password
        read -p "Please provide a password to create an encrypted wallet: " WORKERWALLETPASSWORD    
        rm -fr /tmp/iexec
    	mkdir /tmp/iexec
    	cd /tmp/iexec

    	IEXEC_INIT_RESULT=$(iexec init --force --raw --password "$WORKERWALLETPASSWORD")
        checkExitStatus $? "Can't create a wallet. Failed init."

    	WALLET_ADDR=$(echo $IEXEC_INIT_RESULT | jq .walletAddress | sed "s/\"//g")
    	WALLET_FILE=$(echo $IEXEC_INIT_RESULT | jq .walletFile | sed "s/\"//g")

    	echo "A wallet with address $WALLET_ADDR was created in $WALLET_FILE."

        echo "[INFO] Please fill your wallet with minimum $MINETHEREUM ETH and $DEPOSIT nRLC. Then relaunch the script."
        exit 1

    else
    	echo "You cannot launch a worker without a wallet. Exiting..."
    	exit 1
    fi
fi

echo "The wallet $WALLET_ADDR with password $WORKERWALLETPASSWORD and path $WALLET_FILE will be used..."

echo "Checking wallet balances..."

iexec init --force --skip-wallet
checkExitStatus $? "Can't init iexec sdk."

cat chain.json | jq -r '.chains.kovan += {"hub":"0x759b25b358b9f9c18812a69c0a9cf8b5a11c2e2d"}' | tee chain.json
checkExitStatus $? "Can't place hub address."

WALLETINFO=$(iexec wallet show --raw --wallet-address $WALLET_ADDR --password "$WORKERWALLETPASSWORD")
checkExitStatus $? "Can't get wallet info."

ACCOUNTINFO=$(iexec account show --raw --wallet-address $WALLET_ADDR --password "$WORKERWALLETPASSWORD")
checkExitStatus $? "Can't get account info."

ETHEREUM=$(echo $WALLETINFO | jq .balance.ETH | sed "s/\"//g")
NRLC=$(echo $WALLETINFO | jq .balance.nRLC | sed "s/\"//g")
STAKE=$(echo $ACCOUNTINFO | jq .balance.stake | sed "s/\"//g")

echo "ETHEREUM BALANCE: $ETHEREUM"
echo "STAKE AMOUNT: $STAKE"

# Checking minimum ethereum
if [ $(echo $ETHEREUM'<'$MINETHEREUM | bc -l) -ne 0 ]; then
  message "ERROR" "You need to have $MINETHEREUM ETH to launch iExec worker. But you only have $ETHEREUM ETH."
fi

TODEPOSIT=$(($DEPOSIT - $STAKE))

if [ $NRLC -lt $TODEPOSIT ]; then
  message "ERROR" "You need to have $TODEPOSIT nRLC to make a deposit. But you have only $NRLC nRLC."
fi

# Checking deposit
if [ $STAKE -lt $DEPOSIT ]; then

  # Ask for deposit agreement
  while [ "$answer" != "yes" ] && [ "$answer" != "no" ]; do
    read -p "To participate you need to deposit $TODEPOSIT nRLC. Do you agree? [yes/no] " answer
  done

  if [ "$answer" == "no" ]; then
    message "ERROR" "You can't participate without deposit."
  fi

  # Deposit
  iexec account deposit $TODEPOSIT --wallet-address $WALLET_ADDR --password "$WORKERWALLETPASSWORD"
  checkExitStatus $? "Failed to depoit."
else
  message "OK" "You don't need to stake. Your stake is $STAKE."
fi
