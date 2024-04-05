#!/usr/bin/env bash

COUNT=$(dunstctl count waiting)
ENABLED=
DISABLED=
if [ "$COUNT" != 0 ]; then 
  DISABLED=" $COUNT"
fi

if dunstctl is-paused | grep -q "false" ; then
  echo '{"class": "", "text": " '"$ENABLED"' "}'
else
  echo '{"class": "disabled", "text": " '"$DISABLED"' "}'
fi
