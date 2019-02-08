#!/bin/bash

DEPOSIT=10
CHAIN=kovan
MINETHEREUM=0.2
SCHEDULER_DOMAIN=xx
SCHEDULER_IP=xx
WORKER_DOCKER_IMAGE_VERSION=latest
WORKER_POOLNAME=xx
WORKER_HOSTNAME=xx
WORKER_LOGIN=xx
WORKER_PASSWORD=xx
WORKER_LOGGERLEVEL=xx
WORKER_SHAREDPACKAGES=xx
WORKER_SHAREDAPPS=xx
WORKER_TMPDIR=xx
WORKER_SANDBOX_ENABLED=xx
BLOCKCHAINETHENABLED=xx
WORKERWALLETPATH=xx
WORKERWALLETPASSWORD=xx

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
  docker run --user root -e DEBUG=$DEBUG --interactive --tty --rm -v $(pwd):/iexec-project -w /iexec-project iexechub/iexec-sdk "$@"
}

# Function which checks exit status and stops execution
function checkExitStatus() {
  if [ $1 -eq 0 ]; then
    message "OK" ""
  else
    message "ERROR" "$2"
  fi
}

# Determine OS platform
message "INFO" "Detecting OS platform..."
UNAME=$(uname | tr "[:upper:]" "[:lower:]")

# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
  # If available, use LSB to identify distribution
  if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
      DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
  # Otherwise, use release info file
  else
      DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1 | head -n 1)
  fi
fi

# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" == "" ] && DISTRO=$UNAME

# Check if OS platform is supported
if [ "$DISTRO" != "Ubuntu" ] && [ "$DISTRO" != "darwin" ] && [ "$DISTRO" != "centos" ]; then
  message "ERROR" "Only Ubuntu OS and MacOS platform is supported for now. Your platform is: $DISTRO" 
else
  message "OK" "Detected supported OS platform [$DISTRO] ..."
fi

# Check if docker is installed
message "INFO" "Checking if docker is installed..."
which docker >/dev/null 2>/dev/null
if [ $? -eq 0 ]
then
    (docker --version | grep "Docker version")>/dev/null  2>/dev/null
    if [ $? -eq 0 ]
    then
        message "OK" "Docker is installed."
    else
        message "ERROR" "Docker is not installed at your system. Please install it." 
    fi
else
    message "ERROR" "Docker is not installed at your system. Please install it." 
fi

# Checking connection and changing docker mirror if necessary
message "INFO" "Checking connection [trying to contact google.com] ..."

if ping -c 1 google.com &> /dev/null; then
  message "OK" "Connection is ok."
else
  while [ "$answerdocker" != "yes" ] && [ "$answerdocker" != "no" ]; do
    read -p "Are you from China? [yes/no] " answerdocker
  done

  if [ "$answerdocker" == "yes" ]; then
    message "INFO" "Changing docker mirror..."
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <<-'EOF'
{
 "registry-mirrors": ["https://registry.docker-cn.com"]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
  fi
fi

# Checking containers
RUNNINGWORKERS=$(docker ps --format '{{.ID}}' --filter="name=eclipse-worker")
STOPPEDWORKERS=$(docker ps --filter "status=exited" --format '{{.ID}}' --filter="name=$WORKER_POOLNAME-worker")

# If worker is already running we will just attach to it
if [ ! -z "${RUNNINGWORKERS}" ]; then

    message "INFO" "iExec $WORKER_POOLNAME worker is already running at your machine..."

    # Attach to worker container
    while [ "$attachworker" != "yes" ] && [ "$attachworker" != "no" ]; do
      read -p "Do you want to attach to your worker? [yes/no] " attachworker
    done

    if [ "$attachworker" == "yes" ]; then
      message "INFO" "Attaching to worker container."
      docker container attach $(echo $RUNNINGWORKERS)
    fi

else

    # Pulling iexec sdk
    message "INFO" "Pulling iexec sdk..."
    docker pull iexechub/iexec-sdk
    checkExitStatus $? "Failed to pull image. Check docker service state or if user has rights to launch docker commands."

    message "INFO" "Creating necessary directories..."
    mkdir -p ~/.iexec/

    # Checking wallet file
    message "INFO" "Checking wallet presence..."

    # If both encrypted and decrypted wallets are present all is good
    if [ -f ~/.iexec/wallet.json ] && [ ! $(cat ~/.iexec/wallet.json | wc -c) -eq 0 ] && [ -f ~/.iexec/encrypted-wallet.json ] && [ ! $(cat ~/.iexec/encrypted-wallet.json | wc -c) -eq 0 ]; then
      message "OK" "All necessary wallets are present in (~/.iexec/)."
      # Get wallet password
      read -p "Please provide password of your encrypted-wallet: " WORKERWALLETPASSWORD

    # If only decrypted wallet is present
    elif [ -f ~/.iexec/wallet.json ] && [ ! $(cat ~/.iexec/wallet.json | wc -c) -eq 0 ]; then

      message "INFO" "Found ~/.iexec/wallet.json but need to generate encrypted-wallet.json"

      # Get wallet password
      read -p "Please provide a password to encrypt your wallet: " WORKERWALLETPASSWORD

      cd ~/.iexec/
      iexec wallet encrypt --password "$WORKERWALLETPASSWORD"
      checkExitStatus $? "Failed to encrypt wallet. Please check your (~/.iexec/wallet.json) wallet."

      message "OK" "The wallet was successfully encrypted and is stored in ~/.iexec/encrypted-wallet.json"

    # If only encrypted wallet is present
    elif [ -f ~/.iexec/encrypted-wallet.json ] && [ ! $(cat ~/.iexec/encrypted-wallet.json | wc -c) -eq 0 ]; then

      message "INFO" "Found ~/.iexec/encrypted-wallet.json but need to generate a decrypted wallet.json"
      # Get wallet password
      read -p "Please provide password to decrypt your wallet: " WORKERWALLETPASSWORD

      cd ~/.iexec/
      iexec wallet decrypt --password "$WORKERWALLETPASSWORD"
      checkExitStatus $? "Failed to decrypt wallet. Please check your (~/.iexec/encrypted-wallet.json) wallet."

      message "OK" "The wallet was successfully decrypted and is stored in ~/.iexec/wallet.json"

    # If no wallet is present
    else

      message "INFO" "Wallets are not found in (~/.iexec/) or are empty! "
      
      while [ "$answerwalletcreate" != "yes" ] && [ "$answerwalletcreate" != "no" ]; do
        read -p "Do you want to create wallets in (~/.iexec/)? [yes/no] " answerwalletcreate
      done

      if [ "$answerwalletcreate" == "yes" ]; then
        cd ~/.iexec/
        iexec wallet create

        message "INFO" "Creating an encrypted version of wallet."

        # Get wallet password
        read -p "Please provide a password to create an encrypted wallet: " WORKERWALLETPASSWORD    

        iexec wallet encrypt --password "$WORKERWALLETPASSWORD"
        message "OK" "Wallet were created in (~/.iexec/)."
      else
        message "ERROR" "To launch a worker you need to have an ethereum wallet."
      fi
    fi

    message "INFO" "Working with your wallet..."
    # iexec init sdk environment
    cd ~/.iexec/
    rm -f chain.json iexec.json account.json
    mv -f ~/.iexec/wallet.json ~/.iexec/wallet.json.bak
    iexec init
    checkExitStatus $? "Failed to execute iexec init"
    mv -f ~/.iexec/wallet.json.bak ~/.iexec/wallet.json

    iexec account login --force --chain $CHAIN
    checkExitStatus $? "Failed to login."

    iexec wallet show --chain $CHAIN

    # Get wallet and account info
    ETHEREUM=$(iexec wallet show --chain $CHAIN | grep ETH | awk '{print $3}' | sed 's/[^0-9.]*//g')
    STAKE=$(iexec account show --chain $CHAIN | grep stake | awk '{print $3}' | sed 's/[^0-9]*//g')

    # Checking minimum ethereum
    if [ $(echo $ETHEREUM'<'$MINETHEREUM | bc -l) -ne 0 ]; then
      message "ERROR" "You need to have $MINETHEREUM ETH to launch iExec worker. But you only have $ETHEREUM ETH."
    fi

    # Checking deposit
    if [ $STAKE -lt $DEPOSIT ]; then
      TODEPOSIT=$(($DEPOSIT - $STAKE))

      # Ask for deposit agreement
      while [ "$answer" != "yes" ] && [ "$answer" != "no" ]; do
        read -p "To participate you need to deposit $TODEPOSIT nRLC. Do you agree? [yes/no] " answer
      done

      if [ "$answer" == "no" ]; then
        message "ERROR" "You can't participate without deposit."
      fi

      # Deposit
      iexec account deposit $TODEPOSIT --chain $CHAIN
      checkExitStatus $? "Failed to depoit."
    else
      message "OK" "You don't need to stake. Your stake is $STAKE."
    fi


    # If container was stopped
    if [ ! -z "${STOPPEDWORKERS}" ]; then

        message "INFO" "Stopped $WORKER_POOLNAME worker detected."

        # Relaunch worker container
        while [ "$relaunchworker" != "yes" ] && [ "$relaunchworker" != "no" ]; do
          read -p "Do you want to relauch stopped worker? [yes/no] " relaunchworker
        done

        if [ "$relaunchworker" == "yes" ]; then
            message "INFO" "Relaunching stopped worker."
            docker start $(echo $STOPPEDWORKERS)
            message "INFO" "Worker was sucessfully started."
            
            # Attach to worker container
            while [ "$attachworker" != "yes" ] && [ "$attachworker" != "no" ]; do
              read -p "Do you want to attach to your worker? [yes/no] " attachworker
            done

            if [ "$attachworker" == "yes" ]; then
              message "INFO" "Attaching to worker container."
              docker container attach $(echo $STOPPEDWORKERS)
            fi
        fi

    else
        # Get worker name
        while [[ ! "$WORKER_HOSTNAME" =~ ^[-_A-Za-z0-9]+$ ]]; do
          read -p "Enter worker name [only letters, numbers, - and _ symbols]: " WORKER_HOSTNAME
        done

        # Get last version and run worker
        message "INFO" "Creating iExec $WORKER_POOLNAME worker..."
        docker pull iexechub/worker:$WORKER_DOCKER_IMAGE_VERSION
        docker create --name "$WORKER_POOLNAME-worker" \
                 --hostname "$WORKER_HOSTNAME" \
                 --env "SCHEDULER_DOMAIN=$SCHEDULER_DOMAIN" \
                 --env "SCHEDULER_IP=$SCHEDULER_IP" \
                 --env "LOGIN=$WORKER_LOGIN" \
                 --env "PASSWORD=$WORKER_PASSWORD" \
                 --env "LOGGERLEVEL=$WORKER_LOGGERLEVEL" \
                 --env "SHAREDPACKAGES=$WORKER_SHAREDPACKAGES" \
                 --env "SANDBOXENABLED=$WORKER_SANDBOX_ENABLED" \
                 --env "BLOCKCHAINETHENABLED=$BLOCKCHAINETHENABLED" \
                 --env "SHAREDAPPS=$WORKER_SHAREDAPPS" \
                 --env "TMPDIR=$WORKER_TMPDIR" \
                 --env "WALLETPASSWORD=$WORKERWALLETPASSWORD" \
                 -v ~/.iexec/encrypted-wallet.json:/iexec/wallet/wallet_worker.json \
                 -v /var/run/docker.sock:/var/run/docker.sock \
                 -v $WORKER_TMPDIR:$WORKER_TMPDIR \
                 iexechub/worker:$WORKER_DOCKER_IMAGE_VERSION

        message "INFO" "Created worker $WORKER_POOLNAME-worker."

        # Attach to worker container
        while [ "$startworker" != "yes" ] && [ "$startworker" != "no" ]; do
          read -p "Do you want to start worker? [yes/no] " startworker
        done

        if [ "$startworker" == "yes" ]; then
          message "INFO" "Starting worker."
          docker start $WORKER_POOLNAME-worker
          message "INFO" "Worker was successfully started."
        else
          message "INFO" "You can start the worker later with \"docker start $WORKER_POOLNAME-worker\"."
        fi


    fi
fi

read -p "Press [Enter] to exit..."

