#!/bin/bash
# ubnt_stat.sh
# Auslesen der Feldstärke einer verbundenen Ubiquity Station
# Vorher muss auf der GEgenstation der SSH-Schlüssel abgelegt werden (ssh-copy)
# by DL 7 ATA
#
# V 1 16.07.2019
# Abruf M2
ohne_verbindung='\[ \]'
SUCHE='\"rssi\": '
datei="/tmp/ubnt.stat"

while true; do

ssh -x ubnt@<IP> "cat /var/tmp/stats/wstalist" > $datei
rx=$(cat $datei)

if [ "$rx" == "$ohne_verbindung" ]; then
   echo "Kein Verbindung ...."
   echo $rx
else
   signal=$(cat $datei | grep "\"rssi")
   signal1=$(echo $signal | grep $SUCHE | cut -d"," -f1 | cut -d":" -f2)
   signal2=$(echo $signal | grep $SUCHE | cut -d"," -f2 | cut -d":" -f2)
   echo -e "$(date +%H:%M:%S) RX:${signal1}dB TX:${signal2}dB"

fi
sleep 3
done

rm $datei

exit 0
