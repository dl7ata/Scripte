#!/bin/bash
# dapnet.sh
# Script zum Versenden von DAPNET-Nachrichten
# DL7ATA 3.10.18
#
d=$(date +%H:%M:%S)
echo "Eingabe CALL und TEXT ohne\""
read v1 v2
# Wenn keine Eingabe erfolgt - also erste Variable leer ist, dann einlesen
if [ -z "$v1" ]; then
   echo "Keine Eingabe, beende"
   exit 1
fi

call=$v1
text="$v2 $d"	#"Max, Du bist der Tollste! $d"
adr="http://www.hampager.de:8080/calls"
cmd="curl -H \"Content-Type: application/json\" -X POST -u dl7ata:GDuzXcLmaf3R9RgrDvuC -d '{ \"text\": \"DL7ATA: $text\", \"callSignNames\": [\"$call\"], \"transmitterGroupNames\": [\"dl-be\"], \"emergency\": false }' $adr"
echo $cmd
eval $cmd

exit
