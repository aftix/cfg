#!/usr/bin/env bash

[ -f /var/run/backupdisk.pid ] && echo '{"text": "Backing up disk"}'
inotifywait -m /var/run --include "backupdisk\\.pid" -e create -e delete 2>/dev/null | while read -r line ; do
  grep -Fq '/var/run DELETE backupdisk.pid' <<< "$line" && echo '{}'
  grep -Fq '/var/run CREATE backupdisk.pid' <<< "$line" && echo '{"text": "Backing up disk"}'
done
