FROM parity/parity:v2.1.1

COPY deployment/chain/spec.json /parity/spec.json
COPY deployment/chain/reserved_peers /parity/reserved_peers
COPY deployment/1/password /parity/password
COPY deployment/1/authority.toml /parity/authority.toml
COPY deployment/1/localParityPOA /parity/data/keys/localParityPOA
COPY deployment/1/key.priv /parity/data/network/key

COPY deployContracts.sh /deployContracts.sh
COPY mine.sh /mine.sh

RUN chmod +x deployContracts.sh
RUN chmod +x mine.sh

RUN apt-get update

RUN apt-get install -y curl
RUN apt-get install -y sudo && curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
RUN apt-get install -y nodejs
RUN apt-get install -y build-essential
RUN apt-get install -y git

RUN ./deployContracts.sh

ENTRYPOINT ./mine.sh

EXPOSE 8545


# docker image build -t iexechub/iexec-chain:1a0bf1e .

# docker run -it --name iexec-chain -p 8545:8545 iexechub/iexec-chain:1a0bf1e

