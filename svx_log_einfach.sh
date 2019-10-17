#!/bin/bash
datei=/tmp/svx_log.tmp
cat /var/log/svxlink |grep "CONNECTED" |grep -v "BYE_RECEIVED"  | while read line; do

status=$(echo $line | awk '{print $NF}')
stn=$(echo $line | cut -d":" -f1-4)
echo $stn $status

done

exit 0

