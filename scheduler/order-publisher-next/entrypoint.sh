#!/bin/sh

# DOCKER ENV: IS_GPU_POOL=false;

# Go to iexec sdk directory
cd /iexec

# Check if template file is present
if [ ! -f iexec.json.template ]; then
    echo "[ERROR] iexec.json.template in /iexec folder required."
    exit
fi

# Check if order price is set correctly
if [ ! -z $ORDER_PRICE ]; then
    ORDER_PRICE_SEND=$ORDER_PRICE
else
    if [ -z $ORDER_PRICE_MIN ] || [ -z $ORDER_PRICE_MAX ]; then
    	echo "[ERROR] You must set ORDER_PRICE or ORDER_PRICE_MIN and ORDER_PRICE_MIN."
    	exit
    fi
fi

REQUESTER_RESTRICT=${REQUESTER_RESTRICT:-"0x0000000000000000000000000000000000000000"}
echo "REQUESTER_RESTRICT: $REQUESTER_RESTRICT"


# Calculate number of workers needed from trust value
function getWorkersNumberFromTrust(){
    if [ 1 -le "$1" ] && [ "$1" -lt 3 ]; then
        echo "1"
    elif [ 3 -le "$1" ] && [ "$1" -lt 5 ]; then
        echo "2"
    elif [ 5 -le "$1" ] && [ "$1" -lt 7 ]; then
        echo "3"
    elif [ 7 -le "$1" ] && [ "$1" -lt 12 ]; then
        echo "4"
    elif [ 12 -le "$1" ] && [ "$1" -lt 19 ]; then
        echo "5"
    elif [ 19 -le "$1" ] && [ "$1" -lt 34 ]; then
        echo "6"
    elif [ 34 -le "$1" ] && [ "$1" -lt 59 ]; then
        echo "7"
    elif [ 59 -le "$1" ] && [ "$1" -lt 103 ]; then
        echo "8"
    elif [ 103 -le "$1" ] && [ "$1" -lt 183 ]; then
        echo "9"
    elif [ 183 -le "$1" ] && [ "$1" -lt 324 ]; then
        echo "10"
    elif [ 324 -le "$1" ] && [ "$1" -lt 576 ]; then
        echo "11"
    elif [ 576 -le "$1" ] && [ "$1" -lt 1026 ]; then
        echo "12"
    elif [ 1026 -le "$1" ] && [ "$1" -lt 1826 ]; then
        echo "13"
    elif [ 1826 -le "$1" ] && [ "$1" -lt 3252 ]; then
        echo "14"
    elif [ 3252 -le "$1" ] && [ "$1" -lt 9999 ]; then
        echo "15"
    else
        echo "1"
    fi
}

# Looping
while true
do

    # Workers needed from trust
    NUM_WORKERS=$(getWorkersNumberFromTrust $TRUST_VALUE)
    echo "[INFO] For the trust $TRUST_VALUE scheduler must have $NUM_WORKERS workers. This is not used yet."

    echo "[INFO] Checking orders in orderbook."
    ORDERBOOK_NUMBER=$(iexec orderbook workerpool $WORKERPOOL_ADDRESS --category $CATEGORY_INDEX --chain $CHAIN --raw | jq '.openVolume')
    echo "[INFO] Opened orders in order book: $ORDERBOOK_NUMBER."

    if [ $ORDERBOOK_NUMBER -ge $MAX_ORDER_NUMBER ]; then
      echo "[INFO] Orderbook contains maximum order number."

    else

      echo "[INFO] Checking scheduler info."
      CORE_REQUEST_RESULT=$(curl -s -X GET "$CORE_URL/metrics" -H "accept: */*")

      if [[ $IS_GPU_POOL == true ]]; then
      	AVAILABLE_COMPUTING_POWER_UNIT=$(echo $CORE_REQUEST_RESULT | jq '.aliveAvailableGpu')
      else
      	AVAILABLE_COMPUTING_POWER_UNIT=$(echo $CORE_REQUEST_RESULT | jq '.aliveAvailableCpu')
      fi

      ALIVE_WORKERS=$(echo $CORE_REQUEST_RESULT | jq '.aliveWorkers')
      echo "[INFO] Scheduler Available computing power unit $AVAILABLE_COMPUTING_POWER_UNIT [isGpu:$IS_GPU_POOL]"

      CAN_PUBLISH_NUMBER=`expr $AVAILABLE_COMPUTING_POWER_UNIT - $ORDERBOOK_NUMBER`
      echo "[INFO] Avaliable publish number $CAN_PUBLISH_NUMBER."

      if [ "$CAN_PUBLISH_NUMBER" -gt 0 ]; then

          for i in $(seq 1 $CAN_PUBLISH_NUMBER); do

              # Calculate order price
              if [ -z $ORDER_PRICE ]; then
                  ORDER_PRICE_SEND=$(shuf -i $ORDER_PRICE_MIN-$ORDER_PRICE_MAX -n 1)
              fi

              echo "[INFO] Signing and publishing order $i."

              # Delete old files and copy template file
          	rm -f iexec.json orders.json
          	cp iexec.json.template iexec.json

              # Preparing order
          	sed -i "s/@WORKERPOOL_ADDRESS@/$WORKERPOOL_ADDRESS/g" iexec.json
          	sed -i "s/@CATEGORY_INDEX@/$CATEGORY_INDEX/g" iexec.json
          	sed -i "s/@TRUST_VALUE@/$TRUST_VALUE/g" iexec.json
          	sed -i "s/@ORDER_PRICE@/$ORDER_PRICE_SEND/g" iexec.json
          	sed -i "s/@TAG_VALUE@/$TAG_VALUE/g" iexec.json
          	sed -i "s/@ORDER_VOLUME@/$ORDER_VOLUME/g" iexec.json
            sed -i "s/@REQUESTER_RESTRICT@/$REQUESTER_RESTRICT/g" iexec.json

          	# Sign and publish an order
          	iexec order sign --workerpool --chain $CHAIN --force --keystoredir /wallets --wallet-file wallet.json --password $WALLETPASSWORD
          	iexec order publish --workerpool --chain $CHAIN --force --keystoredir /wallets --wallet-file wallet.json --password $WALLETPASSWORD

              # Wait for the next publish
              echo "[INFO] Waiting $PUBLISH_PERIOD sec before next publish."
              sleep $PUBLISH_PERIOD

          done
      fi

    fi

	# Wait for the next check
    echo "[INFO] Sleeping $CHECK_SLEEP_TIME seconds before next check."
    sleep $CHECK_SLEEP_TIME

done
