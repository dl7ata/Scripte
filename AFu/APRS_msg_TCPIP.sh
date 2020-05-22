#!/bin/bash
# APRS_msg_TCPIP.sh
# Prozedur zum Senden einer APRS-Msg via TCPIP
# by DL 7 ATA
#
# V 0.1 21.2.2019
#
pref=$1
text=$2
d=$(date "+%d.%m.%y")
t=$(date "+%H:%M")
datei="/tmp/nc_cmd.tmp"

zielH="44.225.73.2"
#Erfurt
zielI="195.190.142.207"

z1="user DB5XXX pass xxxxx"
z2="DB5XXX-15>APR7WB,TCPIP*,DB5XXX-15:$pref $text"
echo -e "$z1\n$z2" > $datei

# Wenn Hamnet nicht erreichbar, APRS via Internet benutzen
if ping -c 1 -w 1 $zielH > /dev/null; then
  ziel=$zielH
else
  ziel=$zielI
fi

nc -v -w 5 $ziel 14580 <$datei
tail -1  $datei

exit 0
