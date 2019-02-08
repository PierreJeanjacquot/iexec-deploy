#!/bin/bash

echo 'Starting Grafana...'
/run.sh "$@" &


echo "***************"
ls dashboards
echo "***************"

# Modifing home dashboard title
echo "Modifing home dashboard title..."
cp ./dashboards/viewer/home/home.json ./dashboards/viewer/home/home2.json
if [ $ACTIVATE_POOL_JOIN == "1" ]; then
  echo "Pool join activated..."
  jq ".dashboard.panels[0].content = \"<input type='button' value='Join Worker Pool' id='button' class='navbar-button' onclick=\\\"location.href='/d/JoinWorkerPool';\\\"/><div class='text-center dashboard-header'>\n  <img src='$GRAFANA_HOME_LOGO_PATH' width='$GRAFANA_HOME_LOGO_WIDTH' height='$GRAFANA_HOME_LOGO_HEIGHT' />\n  <span>$GRAFANA_HOME_NAME</span>\n</div>\"" <./dashboards/viewer/home/home2.json >./dashboards/viewer/home/home.json
else
  jq ".dashboard.panels[0].content = \"<div class='text-center dashboard-header'>\n  <img src='$GRAFANA_HOME_LOGO_PATH' width='$GRAFANA_HOME_LOGO_WIDTH' height='$GRAFANA_HOME_LOGO_HEIGHT' />\n  <span>$GRAFANA_HOME_NAME</span>\n</div>\"" <./dashboards/viewer/home/home2.json >./dashboards/viewer/home/home.json
fi

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

  if [ ! -z "$SCRIPT_DEPOSIT" ] ; then
  	sed -i "s/^DEPOSIT=.*$/DEPOSIT=$SCRIPT_DEPOSIT/g" /launch-worker.sh
  else 
  	sed -i "s/^DEPOSIT=.*$/DEPOSIT=0/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_CHAIN" ] ; then
  	sed -i "s/^CHAIN=.*$/CHAIN=$SCRIPT_CHAIN/g" /launch-worker.sh
  else 
  	sed -i "s/^CHAIN=.*$/CHAIN=mainnet/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_MINETHEREUM" ] ; then
  	sed -i "s/^MINETHEREUM=.*$/MINETHEREUM=$SCRIPT_MINETHEREUM/g" /launch-worker.sh
  else 
  	sed -i "s/^MINETHEREUM=.*$/MINETHEREUM=0.18/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_SCHEDULER_DOMAIN" ] ; then
  	sed -i "s/^SCHEDULER_DOMAIN=.*$/SCHEDULER_DOMAIN=$SCRIPT_SCHEDULER_DOMAIN/g" /launch-worker.sh
  else 
  	sed -i "s/^SCHEDULER_DOMAIN=.*$/SCHEDULER_DOMAIN=localhost/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_SCHEDULER_IP" ] ; then
  	sed -i "s/^SCHEDULER_IP=.*$/SCHEDULER_IP=$SCRIPT_SCHEDULER_IP/g" /launch-worker.sh
  else 
  	sed -i "s/^SCHEDULER_IP=.*$/SCHEDULER_IP=127.0.0.1/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_WORKER_DOCKER_IMAGE_VERSION" ] ; then
  	sed -i "s/^WORKER_DOCKER_IMAGE_VERSION=.*$/WORKER_DOCKER_IMAGE_VERSION=$SCRIPT_WORKER_DOCKER_IMAGE_VERSION/g" /launch-worker.sh
  else 
  	sed -i "s/^WORKER_DOCKER_IMAGE_VERSION=.*$/WORKER_DOCKER_IMAGE_VERSION=14.0.0/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_WORKER_POOLNAME" ] ; then
  	sed -i "s/^WORKER_POOLNAME=.*$/WORKER_POOLNAME=$SCRIPT_WORKER_POOLNAME/g" /launch-worker.sh
  else 
  	sed -i "s/^WORKER_POOLNAME=.*$/WORKER_POOLNAME=mainnet/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_WORKER_HOSTNAME" ] ; then
  	sed -i "s/^WORKER_HOSTNAME=.*$/WORKER_HOSTNAME=$SCRIPT_WORKER_HOSTNAME/g" /launch-worker.sh
  else 
  	sed -i "s/^WORKER_HOSTNAME=.*$/WORKER_HOSTNAME=/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_WORKER_LOGIN" ] ; then
  	sed -i "s/^WORKER_LOGIN=.*$/WORKER_LOGIN=$SCRIPT_WORKER_LOGIN/g" /launch-worker.sh
  else 
  	sed -i "s/^WORKER_LOGIN=.*$/WORKER_LOGIN=vworker/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_WORKER_PASSWORD" ] ; then
  	sed -i "s/^WORKER_PASSWORD=.*$/WORKER_PASSWORD=$SCRIPT_WORKER_PASSWORD/g" /launch-worker.sh
  else 
  	sed -i "s/^WORKER_PASSWORD=.*$/WORKER_PASSWORD=vworker/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_WORKER_LOGGERLEVEL" ] ; then
  	sed -i "s/^WORKER_LOGGERLEVEL=.*$/WORKER_LOGGERLEVEL=$SCRIPT_WORKER_LOGGERLEVEL/g" /launch-worker.sh
  else 
  	sed -i "s/^WORKER_LOGGERLEVEL=.*$/WORKER_LOGGERLEVEL=DEBUG/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_WORKER_SHAREDPACKAGES" ] ; then
  	sed -i "s/^WORKER_SHAREDPACKAGES=.*$/WORKER_SHAREDPACKAGES=$SCRIPT_WORKER_SHAREDPACKAGES/g" /launch-worker.sh
  else 
  	sed -i "s/^WORKER_SHAREDPACKAGES=.*$/WORKER_SHAREDPACKAGES=/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_WORKER_SHAREDAPPS" ] ; then
  	sed -i "s/^WORKER_SHAREDAPPS=.*$/WORKER_SHAREDAPPS=$SCRIPT_WORKER_SHAREDAPPS/g" /launch-worker.sh
  else 
  	sed -i "s/^WORKER_SHAREDAPPS=.*$/WORKER_SHAREDAPPS=docker/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_WORKER_SANDBOX_ENABLED" ] ; then
  	sed -i "s/^WORKER_SANDBOX_ENABLED=.*$/WORKER_SANDBOX_ENABLED=$SCRIPT_WORKER_SANDBOX_ENABLED/g" /launch-worker.sh
  else 
  	sed -i "s/^WORKER_SANDBOX_ENABLED=.*$/WORKER_SANDBOX_ENABLED=true/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_BLOCKCHAINETHENABLED" ] ; then
  	sed -i "s/^BLOCKCHAINETHENABLED=.*$/BLOCKCHAINETHENABLED=$SCRIPT_BLOCKCHAINETHENABLED/g" /launch-worker.sh
  else 
  	sed -i "s/^BLOCKCHAINETHENABLED=.*$/BLOCKCHAINETHENABLED=true/g" /launch-worker.sh
  fi

  if [ ! -z "$SCRIPT_WORKERWALLETPASSWORD" ] ; then
  	sed -i "s/^WORKERWALLETPASSWORD=.*$/WORKERWALLETPASSWORD=$SCRIPT_WORKERWALLETPASSWORD/g" /launch-worker.sh
  else 
  	sed -i "s/^WORKERWALLETPASSWORD=.*$/WORKERWALLETPASSWORD=whatever/g" /launch-worker.sh
  fi


  if [ ! -z "$SCRIPT_WORKERWALLETPATH" ] ; then
    
    sed -i -e "/^#\!\/bin\/bash$/ { d; }" /launch-worker.sh 
    sed -i -e "/^WORKERWALLETPATH=.*$/ { d; }" /launch-worker.sh 

    echo "#!/bin/bash" > /launch-worker.sh.temp
    echo "WORKERWALLETPATH=$SCRIPT_WORKERWALLETPATH" >> /launch-worker.sh.temp
    cat /launch-worker.sh >> /launch-worker.sh.temp
    mv /launch-worker.sh.temp /launch-worker.sh

  fi

  if [ ! -z "$SCRIPT_WORKERWALLETPATH" ] ; then
    
    sed -i -e "/^#\!\/bin\/bash$/ { d; }" /launch-worker.sh 
    sed -i -e "/^WORKER_TMPDIR=.*$/ { d; }" /launch-worker.sh 

    echo "#!/bin/bash" > /launch-worker.sh.temp
    echo "WORKER_TMPDIR=$SCRIPT_WORKER_TMPDIR" >> /launch-worker.sh.temp
    cat /launch-worker.sh >> /launch-worker.sh.temp
    mv /launch-worker.sh.temp /launch-worker.sh

  fi

  cp /launch-worker.sh /usr/share/grafana/public/launch-worker.sh

fi

echo "Config was finished."

wait