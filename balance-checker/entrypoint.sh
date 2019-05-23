#!/bin/sh
KEYSTOREPATH="/wallets"
IEXEC_SDK_DIR="/iexec"

post_to_slack(){

  SLACK_MESSAGE="\`\`\`$1\`\`\`"

  case "$2" in
    INFO)
      SLACK_ICON=':slack:'
      ;;
    WARNING)
      SLACK_ICON=':warning:'
      ;;
    ERROR)
      SLACK_ICON=':bangbang:'
      ;;
    *)
      SLACK_ICON=':slack:'
      ;;
  esac

  curl -sS -X POST --data "payload={\"text\": \"${SLACK_ICON} ${SLACK_MESSAGE}\"}" ${SLACK_URL}

}

cd $IEXEC_SDK_DIR

SDK_VERSION=$(iexec --version)

echo "[INFO] iExec SDK version $SDK_VERSION"
while true; do
  for file in $(find $KEYSTOREPATH -type f -not -name "*.password"); do
    echo "[INFO] Checking \"$file\" wallet."
    if [ ! -f $file.password ]; then
      echo "[ERROR] Please add \"$file.password\" file with wallet password."
      continue
    fi

    WALLET_SHOW=$(iexec wallet show --chain $CHAIN --keystoredir $KEYSTOREPATH --wallet-file $(basename $file) --password "$(cat $file.password)" --raw 2>&1)
    ACCOUNT_SHOW=$(iexec account show --chain $CHAIN --keystoredir $KEYSTOREPATH --wallet-file $(basename $file) --password "$(cat $file.password)" --raw 2>&1)

    if [ "$(echo $WALLET_SHOW | jq .error)" != "null" ]; then
      echo "[ERROR] $(echo $WALLET_SHOW | jq .error)"
      continue
    fi

    if [ "$(echo $ACCOUNT_SHOW | jq .error)" != "null" ]; then
      echo "[ERROR] $(echo $ACCOUNT_SHOW | jq .error)"
      continue
    fi

    ETH_BALANCE=$(echo $WALLET_SHOW | jq .balance.ETH | sed 's/\"//g')
    NRLC_BALANCE=$(echo $WALLET_SHOW | jq .balance.nRLC | sed 's/\"//g')
    STAKE=$(echo $ACCOUNT_SHOW | jq .balance.stake | sed 's/\"//g')
    ADDRESS=$(echo $WALLET_SHOW | jq .wallet.address | sed 's/\"//g')

    echo "[INFO] ETH BALANCE $ETH_BALANCE | NRLC BALANCE $NRLC_BALANCE | STAKE $STAKE"

    if [ $(echo "$ETH_BALANCE < $MIN_ETH" | bc -l) -eq 1 ]; then
      echo "[ALERT] [$file] [$ADDRESS] [CHAIN: $CHAIN] The wallets ETH BALANCE is $ETH_BALANCE ETH but must be $MIN_ETH ETH."
      post_to_slack "[$file] [$ADDRESS] [CHAIN: $CHAIN] The wallets ETH BALANCE is $ETH_BALANCE ETH but must be $MIN_ETH ETH." "WARNING"
      continue
    fi

    if [ $(echo "$NRLC_BALANCE < $MIN_NRLC" | bc -l) -eq 1 ]; then
      echo "[ALERT] [$file] [$ADDRESS] [CHAIN: $CHAIN] The wallets NRLC BALANCE is $NRLC_BALANCE nRLC but must be $MIN_NRLC nRLC."
      post_to_slack "[$file] [$ADDRESS] [CHAIN: $CHAIN] The wallets NRLC BALANCE is $NRLC_BALANCE nRLC but must be $MIN_NRLC nRLC." "WARNING"
      continue
    fi

    if [ "$(echo $file | grep no-stake)" = "" ]; then
      if [ $(echo "$STAKE < $MIN_STAKE" | bc -l) -eq 1 ]; then
        echo "[ALERT] [$file] [$ADDRESS] [CHAIN: $CHAIN] The wallets STAKE is $STAKE nRLC but must be $MIN_STAKE nRLC."
        post_to_slack "[$file] [$ADDRESS] [CHAIN: $CHAIN] The wallets STAKE is $STAKE nRLC but must be $MIN_STAKE nRLC." "WARNING"
        continue
      fi
    fi

  done
  echo "[INFO] Sleeping for $CHECK_PERIOD seconds before the next check."
  sleep $CHECK_PERIOD
done
