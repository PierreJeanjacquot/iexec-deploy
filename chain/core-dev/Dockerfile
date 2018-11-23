FROM  iexechub/iexec-chain:1a0bf1e

RUN apt install -y jq bc && npm install -g iexec@3.0.6

COPY setUpChainForCoreDev.sh /setUpChainForCoreDev.sh

COPY mine.sh /mine.sh

RUN chmod +x setUpChainForCoreDev.sh
RUN chmod +x mine.sh

RUN ./setUpChainForCoreDev.sh

ENTRYPOINT ./mine.sh

EXPOSE 8545


# docker image build -t iexechub/iexec-chain:core-dev .

# docker run -it --name iexec-chain-core-dev -p 8545:8545 iexechub/iexec-chain:core-dev

