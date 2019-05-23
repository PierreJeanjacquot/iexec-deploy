#!/bin/sh
KEYSTOREPATH="/wallets"
IEXEC_SDK_DIR="/iexec"

cd $IEXEC_SDK_DIR

SDK_VERSION=$(iexec --version)

echo "[INFO] iExec SDK version $SDK_VERSION"


while true
do
  for value in $POOLS
  do
    for cat in $(seq 0 4)
    do


      echo "[INFO] Searching orders in cat $cat by worker pool $value"
      ORDERBOOK=$(iexec orderbook workerpool $value --category $cat --chain $CHAIN --raw)
      ORDER_HASH=$(echo $ORDERBOOK | jq '.workerpoolOrders[].orderHash' | tail -n 1 | sed "s/\"//g")
      TRUST_VALUE=$(echo $ORDERBOOK | jq '.workerpoolOrders[].order.trust' | tail -n 1)

      if [ ! -z $ORDER_HASH ]
      then

        echo "[INFO] Wallet info"
        iexec wallet show --keystoredir $KEYSTOREPATH --wallet-file wallet.json --password "$WALLETPASSWORD" --chain $CHAIN
        iexec account show --keystoredir $KEYSTOREPATH --wallet-file wallet.json --password "$WALLETPASSWORD" --chain $CHAIN

        echo "[INFO] Order with hash $ORDER_HASH and trust $TRUST_VALUE found in cat $cat"

        echo "[INFO] Init order."
        iexec order init --request --keystoredir $KEYSTOREPATH --wallet-file wallet.json --chain $CHAIN

        echo "[INFO] Changing request data in iexec.json"
        sed -i "s/\"app\":\ \".*\"/\"app\":\ \"$APP\"/g" ./iexec.json

        if [ ! -z $DATASET ]
        then
          sed -i "s/\"dataset\":\ \".*\"/\"dataset\":\ \"$DATASET\"/g" ./iexec.json
        fi

        if [ -f $PARAMS_FILE ]; then
          APP_PARAM=$(eval $(shuf -n 1 parameters))
          echo "[INFO] Selected application parameter is $APP_PARAM"
        fi

        sed -i "s/\"workerpool\":\ \".*\"/\"workerpool\":\ \"$value\"/g" ./iexec.json
        sed -i "s/\"category\":\ .*/\"category\":\ $cat,/g" ./iexec.json
        sed -i "s/\"params\":\ \".*\"/\"params\":\ \"{\ \\\\\"0\\\\\": \\\\\"$APP_PARAM\\\\\"\ }\"/g" ./iexec.json
        sed -i "s/\"appmaxprice\":\ .*/\"appmaxprice\":\ $MAXPRICE,/g" ./iexec.json
        sed -i "s/\"datasetmaxprice\":\ .*/\"datasetmaxprice\":\ $MAXPRICE,/g" ./iexec.json
        sed -i "s/\"workerpoolmaxprice\":\ .*/\"workerpoolmaxprice\":\ $MAXPRICE,/g" ./iexec.json
        sed -i "s/\"trust\":\ .*/\"trust\":\ $TRUST_VALUE,/g" ./iexec.json
        sed -i "s/\"callback\":\ \".*\"/\"callback\":\ \"$CALLBACK\"/g" ./iexec.json
        sed -i "s/\"beneficiary\":\ \".*\"/\"beneficiary\":\ \"$BENEFICIARY\"/g" ./iexec.json

        cat ./iexec.json

        echo "[INFO] Signing order"
        iexec order sign --request --keystoredir $KEYSTOREPATH --wallet-file wallet.json --password "$WALLETPASSWORD" --chain $CHAIN

        echo "[INFO] Get app order hash"
        APP_ORDER_HASH=$(iexec orderbook app $APP --chain $CHAIN --raw | jq '.appOrders[] | select((.status | contains("open")) and (.remaining > 0)) | .orderHash' | tail -n 1 | sed "s/\"//g")
        if [ -z $APP_ORDER_HASH ]
        then
          echo "[ERROR] No apporder found for application $APP"
          exit 1
        fi
        if [ ! -z $DATASET ]
        then
          echo "[INFO] Get dataset order hash"
          DATASET_ORDER_HASH=$(iexec orderbook dataset $DATASET --chain $CHAIN --raw | jq '.datasetOrders[] | select((.status | contains("open")) and (.remaining > 0)) | .orderHash' | tail -n 1 | sed "s/\"//g")
          if [ -z $DATASET_ORDER_HASH ]
          then
            echo "[ERROR] No dataset order found for dataset $DATASET"
            exit 1
          fi
          echo "[INFO] Filling order"
          iexec order fill --workerpool $ORDER_HASH --app $APP_ORDER_HASH --dataset $DATASET_ORDER_HASH --chain $CHAIN --keystoredir $KEYSTOREPATH --wallet-file wallet.json --password "$WALLETPASSWORD"
        else
          echo "[INFO] Filling order"
          iexec order fill --workerpool $ORDER_HASH --app $APP_ORDER_HASH --keystoredir $KEYSTOREPATH --chain $CHAIN --wallet-file wallet.json --password "$WALLETPASSWORD"
        fi
      fi
    done
  done

  SLEEP_FOR=$(shuf -i $SLEEP_VALUE -n 1)
  echo "[INFO] Sleeping $SLEEP_FOR seconds before next check."
  sleep $SLEEP_FOR
done
