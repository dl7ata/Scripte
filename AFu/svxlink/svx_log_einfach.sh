#!/bin/bash
# svx_log_einfach.sh	DL7ATA 2017
# Die paar Zeilen sind ja selbsterklärend   :)
#
datei=/tmp/svx_log.tmp
cat /var/log/svxlink |grep "CONNECTED" |grep -v "BYE_RECEIVED"  > $datei
while read line; do

status=$(echo $line | awk '{print $NF}')
stn=$(echo $line | cut -d":" -f1-4)
echo $stn $status

done < $datei

exit 0

