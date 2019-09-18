#!/bin/bash -e
# Bake zur Aussendung des aktuellen PV-Ladestroms
# DL7ATA 30.10.2016 9:10
#
# 22.02.2019	Korrektur Feld Untergang wg. Ergänzung Sonnenscheindauer
# 21.02.2019	Wechsel auf Banana26 und Aussendung via TCPIP
# 01.02.2019	Umstellung von AX25 auf APRX-Bake
# 13.3.2018	Sonnenauf- und Untergangszeiten berücksichtigen
#
#
pfad=/tmp
datei=${pfad}/APRS.msg
zielH="44.225.73.2"
#Erfurt

zielI="195.190.142.207"
#Koblenz

#zielI="85.116.202.225"
d=$(date +%y%m%d.%H:%M:%S)
hour=$(date +%H)
minute=$(date +%M)
aktZ="${hour}:${minute}"
datei="/tmp/PV_Ertrag.txt"
datei_nc="/tmp/nc_PV_Ertrag.txt"
call="DL7ATA"
long="5234.25"
lat="01313.98"

# Per cronjob erstellte Auf- und Untergangszeiten lesen und aufbereiten aus Datei...
dateiSo="/tmp/sunset.txt"
t=$(cat $dateiSo)
auf=$(echo ${t:0:5})
unter=$(echo ${t:6:5})
delta=$(( $(date -d "$aktZ" +%s) - $(date -d "$unter" +%s) ))
utc=$(date -u +%H%M%S)

# Nur bei Helligkeit hell ausführen
if [ $(date -d "$aktZ" +%s) -ge $(date -d "$auf" +%s) ] &&  [ $(date -d "$aktZ" +%s) -le $(date -d "$unter" +%s) ]
  then
   amp=$(cat $datei | cut -d" " -f1)
   volt=$(cat $datei | cut -d" " -f10)
   wh=$(cat $datei | cut -d" " -f4)
   VA=$(cat $datei | cut -d" " -f8)
   delta=$(echo "$wh-$VA" | bc -l)
   text="Solarpower ${amp}A, ${volt}V, ${wh}Wh, Delta ${delta}Wh"
   call=$(printf "%-9s\n" "$call" | tr [:lower:]äöü [:upper:]ÄÖÜ)
   z1="user DL7ATA pass 21678"
   z2="DL7ATA-11>AP7PV,TCPIP*,DB0TGO-14::$call:$text"
   # z3="DL7ATA-11>AP7PV,TCPIP*:@${utc}h${long}NA${lat}EUSolarenergy powering DB0TGO"
   # echo -e "${z1}\n${z2}\n${z3}" > $datei_nc
   echo -e "${z1}\n${z2}\n" > $datei_nc

   # Falls Hamnet nicht erreichbar, APRS via Internet benutzen
   if ping -c 1 -w 1 $zielH > /dev/null; then
     ziel=$zielH
   else
     ziel=$zielI
   fi

   nc -v -w 5 $ziel 14580 < $datei_nc
   echo "$d : $text"
fi

exit 0
