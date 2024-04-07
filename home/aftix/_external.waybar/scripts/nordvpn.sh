#!/usr/bin/env bash

[ -d /proc/sys/net/ipv4/conf/nordlynx ] && \
 echo '{"text": " 󰖂  ", "class": ""}' || \
 echo '{"text": " 󰖂  ", "class": "disconnected"}'
