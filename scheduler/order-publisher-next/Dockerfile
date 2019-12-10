FROM nexus.iex.ec/iexec-sdk:4.0.0-alpha
LABEL maintainer "vladimir.ostapenco@iex.ec"

USER root

RUN apk add --no-cache curl jq

RUN mkdir /wallets

COPY /entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]