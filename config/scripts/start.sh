#!/bin/bash
#
# Exit on first error.
set -e

# Configure time zone
ln -snf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && echo $TZ > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

echo "Time zone configured to Sao Paulo."