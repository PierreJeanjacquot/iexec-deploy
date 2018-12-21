#!/bin/bash

if [[ -z $1 ]] ; then
  echo "no starting market order number was given"
  exit
fi;

i=$1
work_number=""

while true
do

#  sudo ./purge.sh
#  sleep 120
  echo "-------- publishing new order ($i) ---------"
  curl --request GET --insecure --user 'admin:TO_BE_DEFINE_HERE' --url 'https://localhost:443/sendmarketorder?XMLDESC=<marketorder><direction>ASK</direction><categoryid>5</categoryid><expectedworkers>1</expectedworkers><nbworkers>0</nbworkers><trust>30</trust><price>69000000000</price><volume>1</volume></marketorder>'
  sleep 60
  printf "=> filling order ($i)"

  iexec order fill $i --force --chain mainnet &> tmp
  MO_DOESNT_EXIST=$(cat tmp | grep "Error:" | wc -l)

  if [[ $MO_DOESNT_EXIST -ne 0 ]] ; then
    echo "=> order $i does not exist yet"
    for FLAG in $(seq 1 5)
    do
      echo "trying $FLAG"
      sleep 60
      echo "=> filling order ($i)"
      iexec order fill $i --force --chain mainnet &> tmp
      MO_DOESNT_EXIST=$(cat tmp | grep "Error:" | wc -l)

      if [[ $MO_DOESNT_EXIST -eq 0 ]] ; then
        break
      fi
    done;
  fi

  work_number=$(cat tmp | grep "New work at" | sed 's/.*\(0x[0-9a-f]*\)\ .*/\1/g')

  if [ "$work_number" != "" ]; then
    iexec work show $work_number --watch --chain mainnet
    sleep 5
    iexec work show $work_number --watch --chain mainnet
  else
    echo "can't get work number. exiting..."
    exit;
  fi

  let "i++"
  echo ""
done;
