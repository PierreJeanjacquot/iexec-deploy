FROM grafana/grafana:latest
USER root
RUN apt-get update && apt-get install -y jq  curl

COPY ./init.sh /init.sh
COPY ./dashboards dashboards
COPY launch-worker.sh /launch-worker.sh

COPY ./mongodb-grafana /var/lib/grafana/plugins/mongodb-grafana

RUN chmod +x /init.sh

ENTRYPOINT ["bash", "/init.sh"]
