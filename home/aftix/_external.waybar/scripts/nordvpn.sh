#!/usr/bin/env bash

[ -d /proc/sys/net/ipv4/conf/tun0 ] && \
 echo '{"text": " 󰖂  ", "class": ""}' || \
 echo '{"text": " 󰖂  ", "class": "disconnected"}'
