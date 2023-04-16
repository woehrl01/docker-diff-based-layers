#!/usr/bin/env bash

set -e

# install rsync
apt-get update && apt-get install -y rsync && rm -rf /var/lib/apt/lists/*

cat <<EOF > /tmp/.rsyncd.conf
[root]
path = /
read only = false
uid = 0
gid = 0
EOF

rsync --daemon --port 873 --no-detach -vv --config /tmp/.rsyncd.conf
