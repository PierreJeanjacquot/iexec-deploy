#!/bin/bash
echo $(grep $(hostname) /etc/hosts | cut -f1) host1 >> /etc/hosts && parity --chain /parity/spec.json --config /parity/authority.toml --force-sealing -d /parity/data  --geth