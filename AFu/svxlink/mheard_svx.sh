#!/bin/bash
# mheard_svx.sh
# Suche nach letztem Logeintrag/gehört von Call
# Aufruf mit PArameter <call>
#
# 26.09.2019	DL7ATA

mheard=$(echo $1 | tr '[:lower:]' '[:upper:]')
logdatei=/var/log/svxlink
echo -e "Suche nach $mheard in $logdatei \n"

heard=$(tac $logdatei | grep -m 1 "Talker start: ${mheard}" | cut -c1-19)
ended=$(tac $logdatei | grep -m 1 "Talker stop: ${mheard}" | cut -c12-19)
if [ "$heard" != '' ];then
   echo "$mheard zuletzt gehört: $heard  bis  $ended"
else
   beginn=$(head -1 $logdatei | cut -c1-19)
   echo -e "$mheard nicht gehört seit $beginn"
fi
exit 0

