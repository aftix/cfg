#!/run/current-system/sw/bin/bash

[ -d /proc/sys/net/ipv4/conf/nordlynx ] && \
 echo '{"text": " 󰖂  ", "class": ""}' || \
 echo '{"text": " 󰖂  ", "class": "disconnected"}'
