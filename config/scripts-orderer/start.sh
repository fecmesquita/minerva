#!/bin/bash
#
# Exit on first error, print all commands.
set -ev

# Configure time zone
ln -snf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && echo $TZ > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata