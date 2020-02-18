#!/bin/bash

echo 'Starting Grafana...'
/run.sh "$@" &


echo "***************"
ls dashboards
echo "***************"

# Modifing home dashboard title
echo "Modifing home dashboard title..."
cp ./dashboards/viewer/home/home.json ./dashboards/viewer/home/home2.json

#if [ $ACTIVATE_POOL_JOIN == "1" ]; then
#  echo "Pool join activated..."
#  jq ".dashboard.panels[0].content = \"<input type='button' value='Join Worker Pool' id='button' class='navbar-button' onclick=\\\"location.href='/d/JoinWorkerPool';\\\"/><div class='text-center dashboard-header'>\n  <img src='$GRAFANA_HOME_LOGO_PATH' width='$GRAFANA_HOME_LOGO_WIDTH' height='$GRAFANA_HOME_LOGO_HEIGHT' />\n  <span>$GRAFANA_HOME_NAME</span>\n</div>\"" <./dashboards/viewer/home/home2.json >./dashboards/viewer/home/home.json
#else

jq ".dashboard.panels[0].content = \" \
<style type='text/css'> \
  .navbar-button-new {  \
    background-image: linear-gradient(90deg,#F9C300,#FAE900);  \
    font-weight: 500;  \
    padding: 20px 12px;  \
    line-height: 0px;  \
    color: #5D4B00;  \
    border-radius: 5px;  \
  } \
  .navbar-button-new:hover { \
   background: #D2B12A; \
   color: #5D4B00; \
  } \
  .main-div { \
    width: 250px; \
    content: ''; \
    display: table; \
  } \
  .element-div { \
    float: left; \
    width: 50%; \
  } \
  .clear-div { \
    clear: both; \
  } \
</style> \
<div class='main-div'> \
  <div class='element-div'> \
    <input type='button' value='Start A Worker' id='button' class='navbar-button navbar-button-new' onclick=\\\"window.open('https://docs.iex.ec/for-workers');\\\"/> \
  </div> \
  <div class='element-div'> \
    <input type='button' value='Buy Orders' id='button' class='navbar-button navbar-button-new' onclick=\\\"window.open('https://market.iex.ec');\\\"/> \
  </div> \
  <div class='clear-div'> </div> \
</div> \
<div class='text-center dashboard-header'> \
  <img src='$GRAFANA_HOME_LOGO_PATH' width='$GRAFANA_HOME_LOGO_WIDTH' height='$GRAFANA_HOME_LOGO_HEIGHT' /> \
  <span>$GRAFANA_HOME_NAME</span> \
</div>\""  <./dashboards/viewer/home/home2.json >./dashboards/viewer/home/home.json
#fi

rm ./dashboards/viewer/home/home2.json

# Global vars
orgId="null"
homeDashId="null"

# Declaring necessary functions
AddDataSource() {
  curl -s -H "Content-Type: application/json" \
       -X POST -d "{\"name\":\"MongoDB\",
                    \"type\":\"grafana-mongodb-datasource\",
                    \"access\":\"proxy\",
                    \"url\":\"$MONGO_PROXY_URL\",
                    \"password\":\"\",
                    \"user\":\"\",
                    \"database\":\"\",
                    \"basicAuth\":false,
                    \"isDefault\":true,
                    \"jsonData\":{\"keepCookies\":[], \"mongodb_db\": \"$MONGO_DB_NAME\", \"mongodb_url\": \"$MONGO_URL\"},
                    \"readOnly\":false}" \
   http://admin:$GF_SECURITY_ADMIN_PASSWORD@$GRAFANA_HOST/api/datasources
}

AddDashboard() {
  curl -s -H "Content-Type: application/json" \
         -X POST -d "`cat $1`" \
  http://admin:$GF_SECURITY_ADMIN_PASSWORD@$GRAFANA_HOST/api/dashboards/db
  sleep 2
}

AddDashBoards() {

  for filename in ./dashboards/$1/*.json; do

    if [ -z $ACTIVATE_POOL_JOIN ] && [ "$ACTIVATE_POOL_JOIN" == "0" ] && [ "$filename" == "./dashboards/viewer/join-worker-pool.json" ]; then
      echo "Pool join is not activated. Pass join-worker-pool dashboard."
    else
      echo "Adding $filename dashboard..."
      AddDashboard "$filename"
    fi

  done

}

SetOrganisation() {
  echo "Setting organisation to id $1..."
  curl -s -X POST http://admin:$GF_SECURITY_ADMIN_PASSWORD@$GRAFANA_HOST/api/user/using/$1
  sleep 2
}

CreateOrganisation() {

  createResult=$(curl -s -X POST \
               -H "Content-Type: application/json" \
               -d "{\"name\": \"$GF_AUTH_ANONYMOUS_ORG_NAME\"}" http://admin:$GF_SECURITY_ADMIN_PASSWORD@$GRAFANA_HOST/api/orgs)
  echo $createResult
  orgId=$(echo $createResult | jq -r '.orgId')

  echo "Created Organisation ID: $orgId"
  sleep 2
}

AddHomeDashboard() {

  createHome=$(AddDashboard "./dashboards/viewer/home/home.json")
  echo $createHome
  homeDashId=$(echo $createHome | jq -r '.id')
  sleep 2
}

SetHomeDashboard() {

    curl -s -H "Content-Type: application/json" \
         -X PUT -d "{\"theme\": \"\",
                     \"homeDashboardId\":$1,
                     \"timezone\":\"utc\"}" \
    http://admin:$GF_SECURITY_ADMIN_PASSWORD@$GRAFANA_HOST/api/org/preferences
    sleep 2
}

# Working with admin account and dashboards
until SetOrganisation "1"; do
  echo "Setting organisation..."
  sleep 1
done

until AddDataSource; do
  echo 'Configuring Data Sources in Grafana...'
  sleep 1
done

until AddDashBoards "admin"; do
  echo 'Configuring Dashboards in Grafana...'
  sleep 1
done


# Working with viewer account and dashboard
until CreateOrganisation; do
  echo "Creating an organisation for viewers..."
  sleep 1
done

if [ "$orgId" != "null" ]
then
  until SetOrganisation "$orgId"; do
    echo "Setting organisation for admin user..."
    sleep 1
  done

  until AddDataSource; do
    echo 'Configuring Data Sources in Grafana...'
    sleep 1
  done

  until AddDashBoards "viewer"; do
    echo 'Configuring Dashboards in Grafana...'
    sleep 1
  done

  until AddHomeDashboard; do
    echo "Add viewer home dashboard..."
    sleep 1
  done

  if [ "$homeDashId" != "null" ]
  then
    until SetHomeDashboard "$homeDashId"; do
      echo "Setting home dashboard..."
      sleep 1
    done
  fi

fi

echo "Grafana has been configured"

if [ ! -z $ACTIVATE_POOL_JOIN ] && [ "$ACTIVATE_POOL_JOIN" == "1" ]; then
  echo "Configure Worker Deploy Script..."

  if [ ! -z "$POOL_JOIN_WORKER_POOLNAME" ] ; then
  	sed -i "s/^WORKER_POOLNAME=.*$/WORKER_POOLNAME=$POOL_JOIN_WORKER_POOLNAME/g" /launch-worker.sh
  else
  	sed -i "s/^WORKER_POOLNAME=.*$/WORKER_POOLNAME=unknown/g" /launch-worker.sh
  fi

  if [ ! -z "$POOL_JOIN_DEPOSIT" ] ; then
  	sed -i "s/^DEPOSIT=.*$/DEPOSIT=$POOL_JOIN_DEPOSIT/g" /launch-worker.sh
  else
  	sed -i "s/^DEPOSIT=.*$/DEPOSIT=0/g" /launch-worker.sh
  fi

  if [ ! -z "$POOL_JOIN_CHAIN" ] ; then
  	sed -i "s/^CHAIN=.*$/CHAIN=$POOL_JOIN_CHAIN/g" /launch-worker.sh
  else
  	sed -i "s/^CHAIN=.*$/CHAIN=kovan/g" /launch-worker.sh
  fi

  if [ ! -z "$POOL_JOIN_MINETHEREUM" ] ; then
  	sed -i "s/^MINETHEREUM=.*$/MINETHEREUM=$POOL_JOIN_MINETHEREUM/g" /launch-worker.sh
  else
  	sed -i "s/^MINETHEREUM=.*$/MINETHEREUM=0.25/g" /launch-worker.sh
  fi

  if [ ! -z "$POOL_JOIN_HUBCONTRACT" ] ; then
  	sed -i "s/^HUBCONTRACT=.*$/HUBCONTRACT=$POOL_JOIN_HUBCONTRACT/g" /launch-worker.sh
  else
  	sed -i "s/^HUBCONTRACT=.*$/HUBCONTRACT=0x/g" /launch-worker.sh
  fi

  if [ ! -z "$POOL_JOIN_WORKER_DOCKER_IMAGE_VERSION" ] ; then
  	sed -i "s/^WORKER_DOCKER_IMAGE_VERSION=.*$/WORKER_DOCKER_IMAGE_VERSION=$POOL_JOIN_WORKER_DOCKER_IMAGE_VERSION/g" /launch-worker.sh
  else
  	sed -i "s/^WORKER_DOCKER_IMAGE_VERSION=.*$/WORKER_DOCKER_IMAGE_VERSION=latest/g" /launch-worker.sh
  fi

  if [ ! -z "$POOL_JOIN_IEXEC_CORE_HOST" ] ; then
  	sed -i "s/^IEXEC_CORE_HOST=.*$/IEXEC_CORE_HOST=$POOL_JOIN_IEXEC_CORE_HOST/g" /launch-worker.sh
  else
  	sed -i "s/^IEXEC_CORE_HOST=.*$/IEXEC_CORE_HOST=mainnet/g" /launch-worker.sh
  fi

  if [ ! -z "$POOL_JOIN_IEXEC_SDK_VERSION" ] ; then
    sed -i "s/^IEXEC_SDK_VERSION=.*$/IEXEC_SDK_VERSION=$POOL_JOIN_IEXEC_SDK_VERSION/g" /launch-worker.sh
  else
    sed -i "s/^IEXEC_SDK_VERSION=.*$/IEXEC_SDK_VERSION=latest/g" /launch-worker.sh
  fi


  if [ ! -z "$POOL_JOIN_IEXEC_CORE_PORT" ] ; then
  	sed -i "s/^IEXEC_CORE_PORT=.*$/IEXEC_CORE_PORT=$POOL_JOIN_IEXEC_CORE_PORT/g" /launch-worker.sh
  else
  	sed -i "s/^IEXEC_CORE_PORT=.*$/IEXEC_CORE_PORT=/g" /launch-worker.sh
  fi

  cp /launch-worker.sh /usr/share/grafana/public/launch-worker.sh

fi

echo "Grafana was successfully configured."

wait
