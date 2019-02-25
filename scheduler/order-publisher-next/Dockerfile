FROM iexechub/iexec-sdk:next
LABEL maintainer "vladimir.ostapenco@iex.ec"
WORKDIR /home/node/app

USER root

RUN apk add --no-cache curl jq
COPY --chown=node:node ./entrypoint.sh /home/node/app/
RUN chmod +x /home/node/app/entrypoint.sh

USER node

ENTRYPOINT ["/home/node/app/entrypoint.sh"]