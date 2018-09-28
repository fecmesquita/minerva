#!/bin/bash
#
# Exit on first error, print all commands.
set -ev

# Configure time zone
ln -snf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && echo $TZ > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

cp /scripts/fabric-ca-server-config.yaml /etc/hyperledger/fabric-ca-server

# Start the root CA
fabric-ca-server start -b admin:adminpw