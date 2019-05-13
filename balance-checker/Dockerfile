FROM iexechub/iexec-sdk
LABEL maintainer "vladimir.ostapenco@iex.ec"

USER root

RUN apk add --no-cache curl jq bc

RUN mkdir /wallets

COPY /entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]