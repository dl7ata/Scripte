#!/bin/bash
# graph.sh	by DL 7 ATA
# Grafik aus PV.rrd erstellen; Aufruf durch Cronjob
# __________________________________________________________________
#   3.3         15.02.2019      Prozessprüfung nach Erstellung Grafik verschoben
#   3.2         16.01.2019      APRS-Statistik Rhythmus geändert
#   3.1		29.12.2018	Neues Grafik-Outfit  von 220 auf 300 height und Wh-Ermittlung
# V 3.0		13.12.2018	Neuerstellung wg. Erweiterung auf 3 Sensoren - 1x Volt, 2x Amps
#
# Felder vom Arduino: spannung / verbrauch / ertrag
#______________________________________________________________________
#
# Beispiel unter https://stackoverflow.com/questions/11353289/rrdtool-gprint-formatting-with-printf
#------------indiv. anpassung--------------------------------------#
pfad=/tmp/Bilder
rrdp=/tmp
declare -a zeitraum=( "720h" "168h" "24h" "10h" "1h" "600sec")	 # pro Eintrag wird eine Grafik erstellt
declare -a typ=("AVERAGE" "MAX")
intervall="20"
#------------------------------------------------------------------#
a=$(date +%M)
heute=$(date +"%H:%M:%S")

#-------- Teil I -----------------Erzeugung Grafiken
declare -i counter
tag=$(date +%y%m%d)
datum=$(date -R)
hour=$(date +%H)
minute=$(date +%M)
aktZ="${hour}:${minute}"
ver=$(date +"%d.%m.%Y %H:%M:%S")
declare -i scr_start
declare -i scr_end
scr_start=$(date +%s)

# Start
echo -e "\n graph.sh gestartet um $heute \n"

# Per cronjob erstellte Auf- und Untergangszeiten lesen und aufbereiten aus Datei...
datei="/tmp/sunset.txt"
t=$(cat $datei)
auf=$(echo ${t:0:5})
unter=$(echo ${t:5:6})
delta=$(( $(date -d "$aktZ" +%s) - $(date -d "$unter" +%s) ))

# Wenn noch hell, dann Teil I ausführen
if ([ $(date -d "$aktZ" +%s) -ge $(date -d "$auf" +%s) ] &&  [ $(date -d "$aktZ" +%s) -le $(date -d "$unter" +%s) ])  || [ -n "$1" ]
   then
   sleep 5
#-------------------Schleife 1: 1x AVERAGE, 1x MAX - Werte erzeugen
for h in "${typ[@]}"
do

#--------------------Schleife 2 für Erzeugung der AVERAGE Werte--------------------#
## loop through the above array
for zr in "${zeitraum[@]}"
do
counter=$((counter + 1))
z="$(printf '%02d' "$counter")"

# Aufbereiten Wh-Multiplikator, umrechnen in Stunden pro Zeitraum; dazu String zerlegen z.B. in "10" und "h"
zahl=$(echo $zr | sed 's/[^0-9]//g')
einheit=$(echo $zr | sed s/^[0123456789]*//)

if [ "$einheit" = "h" ];
then			# Angabe war shcon in Stunden
   zr2=$zahl

elif [ "$einheit" = "min" ]
then			# Umrechnen Minuten in Stunden
   zr2=$(echo "$zahl / 60" | bc | awk '{printf "%.0f\n", $1}')

elif [ "$einheit" = "sec" ]
then			# Umrechnen Sekunden in Stunden
   zr2=$(echo $(echo | gawk '{print '$zahl'/'3600'}') | gawk '{printf "%.3f\n", $1}')

else
   echo "Error in Einheit... goodbye."
   exit 2
fi

#echo "Erstelle für '$zr'h mit $zr2 $einheit"

# mit right-axis wird die linke Skala skaliert und verschoben
# mit der CDEF-Funktion wird der ausgelese Wert an die geänderte Skala angepasst (-12 und verdoppelt weil right-axis 0.5)
#
~/rrdtool-1.x/src/rrdtool graph $pfad/pv_graph$z.png \
--start -$zr \
-D -N -E -r -a PNG \
--y-grid 0.5:2 \
-Y \
-t "PV-Anlage, $zr " \
--font LEGEND:8 \
--vertical-label "Ampere" \
--left-axis-format "%.1lf" \
--right-axis-label "Volt" \
--right-axis-format "%.1lf" \
--right-axis 0.2:12 \
--full-size-mode -w 550 -h 300 \
--watermark "(c) DL 7 ATA   -  `date` / $h Werte" \
DEF:ertrag=$rrdp/PV.rrd:ertrag:AVERAGE \
DEF:verbrauch=$rrdp/PV.rrd:verbrauch:AVERAGE \
DEF:spannung=$rrdp/PV.rrd:spannung:$h \
CDEF:spann1=spannung,12.0,-,5.0,* \
CDEF:ertr_wh=ertrag,spannung,*,$zr2,* \
CDEF:verb_wh=verbrauch,spannung,*,$zr2,* \
LINE:ertrag#00FF00:"Ertrag (A)  " \
LINE:verbrauch#FF0000:"Verbrauch (A)    " \
LINE:spann1#0000FF:"Spannung (V) \\n" \
GPRINT:ertr_wh:AVERAGE:"Ertrag %2.1lf Wh" \
GPRINT:verb_wh:AVERAGE:" Verbrauch %2.1lf Wh" \
GPRINT:spannung:MIN:"  Minimum %2.1lf V" \
GPRINT:spannung:MAX:"Maximum %2.1lf V \\n" \
COMMENT:"\\n"

done
#--------ende-Schleife-2-------------------------------------------------

done
#--------ende-Schleife-1-------------------------------------------------

#Letzten 10h pro Tag speichern   --> jetzt in crontab
# cp  $pfad/pv_graph04.png  $pfad/pv_graph.$tag.png

#--------------------------------upload auf DB0AVH----------------------#
# Section prüft ob derselbe Prozess im Hintergrund noch läuft bzw. hängt, weil Hamnet nicht erreichbar
#if [ "$(pidof -x "$0")" != "$$" ]; then
#   echo "$heute: Vorheriger Prozess läuft noch - kein Upload."
#   killall -9 ftp
#else

 # Nur alle $intervall Minuten auf AVH hochladen
 b="10#"
 c=$b$a
 if [ $(($c % $intervall)) -eq 0 ]  || [ -n "$1" ] ; then
       # APRS-Statistik
       /home/svxlink/APRSMsg/APRS_PV.sh
       echo "Datenstand vom:  $ver" > $pfad/pv_version
       /home/svxlink/PV/AVH_up.sh
 else
	echo -e "\nIntervall $c, ohne AVH Kopie (Intervall: $intervall)\n"
 fi
 echo "$(date -R) PNGs erstellt."
#fi

# Schleifenende hell/Teil I
fi

#-----Teil II----------------
# prüfen, ob PV-Prozess läuft. Falls nicht, Meldung an svxlink und Sprachausgabe via TTS
#		21.8.2017	Meldung mit Datumsstempel versehen, damit sie nicht als Doublette erkannt wird (1x pro Tag)
# DL7ATA V 0.1 	31.7.2017
#
# Variable "P" = Prozessname

P="PV_rrd.sh"

if ps -C $P; then
   	echo "$P läuft, # (Prozess-ID: $(pidof -x $P))"
else
	heute=$(date +"%Y-%m-%d")
	meldungs_datum=$(date +%d.%m.%Y)
	meldungs_h=$(date +%H)
	meldungs_m=$(date +%M)
   	echo "$P läuft nicht "
   	echo "#PV#DL7ATA#Achtung! Solar - Datenlogger läuft nicht mehr, es liegt ein technisches Problem vor. Meldung generiert am $meldungs_datum , um $meldungs_h uhr." > /tmp/aprsmsg.text
fi

scr_end=$(date +%s)

z=$((scr_end - $scr_start))
echo -e "\n graph.sh fertig  in $((z % 3600 /60)) min, $((z % 60)) s"  #...  in $((z /3600)) h, ....

exit 0
