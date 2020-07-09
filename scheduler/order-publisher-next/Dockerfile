FROM iexechub/iexec-sdk:5.0.0-alpha.9
LABEL maintainer "vladimir.ostapenco@iex.ec"

COPY iexec /iexec

USER root

RUN apk add --no-cache curl jq

RUN mkdir /wallets

COPY /entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENV IS_GPU_POOL false

ENTRYPOINT ["/entrypoint.sh"]
