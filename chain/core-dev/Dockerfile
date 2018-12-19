FROM  iexechub/iexec-chain:f90dda6

RUN apt install -y jq bc && npm install -g iexec@3.0.10

COPY setUpChainForCoreDev.sh /setUpChainForCoreDev.sh

COPY mine.sh /mine.sh

RUN chmod +x setUpChainForCoreDev.sh
RUN chmod +x mine.sh

RUN ./setUpChainForCoreDev.sh

ENTRYPOINT ./mine.sh

EXPOSE 8545


# docker image build -t iexechub/iexec-chain:3.0.13-core-dev .

# docker run -it --name iexec-chain-core-dev -p 8545:8545 iexechub/iexec-chain:3.0.13-core-dev

