#!/bin/bash
# dapnet.sh
# Script zum Versenden von DAPNET-Nachrichten
# DL7ATA 3.10.18
#
# 08.10.2019	Wenn Hamnet nicht erreichbar, Versand via Internet
#
d=$(date +%H:%M:%S)
RED='\e[31m'
LYELLOW='\e[33m'
NORMAL='\e[0m'
call=${1^^}
Msg=$2

lan=$(echo $Msg | awk '{print length($zeichen)}')
if [ $lan -gt 72 ];then
    echo "Nachricht ist $lan Zeichen lang, kürze auf 72 Zeichen ..."
    text=$(echo "$Msg" | cut -c1-72)
else
    text=$Msg
fi

if [ -z "$1" ]; then
   echo "Eingabe CALL und TEXT mit\""
   exit 1
else
   echo -e "Sende $LYELLOW $text $NORMAL an ${call}.\n"
fi

zielI="www.hampager.de"
# http://www.hampager.de:8080/calls
zielH="44.225.164.27"
# zielI="137.226.79.98"
port="8080"

# Falls Hamnet nicht erreichbar, Internet benutzen
if ping -c 3 -w 1 $zielH > /dev/null; then
   ziel=$zielH
else
   ziel=$zielI
fi

adr=${ziel}":"${port}"/calls"
cmd="curl -H \"Content-Type: application/json\" -X POST -u dl7ata:<your_HASH> \
-d '{ \"text\": \"DL7ATA: $text\", \"callSignNames\": [\"$call\"], \"transmitterGroupNames\": [\"dl-be\"], \"emergency\": false }' $adr"
echo $cmd
eval $cmd

exit 0
