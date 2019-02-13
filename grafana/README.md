## .env file
```bash
GRAFANA_DOCKER_IMAGE_VERSION=mongodbv1
GRAFANA_MONGO_PROXY_URL=http://mongodb-proxy:3333
GRAFANA_MONGO_DB_NAME=iexec
GRAFANA_MONGO_URL=mongodb://root:example@mongo:27017
GRAFANA_ADMIN_PASSWORD=xxxx
GRAFANA_HOST=localhost:3000
GRAFANA_HOME_NAME=Kovan Worker Pool
GRAFANA_HOME_LOGO_WIDTH=35
GRAFANA_HOME_LOGO_HEIGHT=35
GRAFANA_HOME_LOGO_PATH=https://iex.ec/app/themes/iexec/assets/images/for-everyone/token.svg
GRAFANA_ACTIVATE_POOL_JOIN=1
```

## Launch grafana
```bash
docker-compose up -d
```
