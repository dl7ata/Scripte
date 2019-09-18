#!/bin/bash
# ACS_graph.sh
# 19.11.2018
# by DL7ATA
# Grafik aus ACS.rrd erstellen
#
#------------indiv. anpassung--------------------------------------#
pfad=/tmp/Bilder
rrdp=/tmp
db="ACS"
#declare -a zeitraum=("7d" "36h" "14h" "10h" "4h" "20m" "1h")		   # pro Eintrag wird eine Grafik erstellt
declare -a zeitraum=("14h" "10h" "4h" "20m" "5m" "1h")		   # pro Eintrag wird eine Grafik erstellt
#------------------------------------------------------------------#
heute=$(date +"%H:%M:%S")
mkdir -p $pfad
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
#--------------------Schleife 1 für Erzeugung der AVERAGE Werte--------------------#
## loop through the above array
for i in "${zeitraum[@]}"
do
counter=$((counter + 1))
z="$(printf '%02d' "$counter")"

# mit right-axis wird die rechte Skala skaliert und verschoben; der zweite Parameter definiert den Beginn der Skala
# mit der CDEF-Funktion wird der ausgelese Wert an die geänderte Skala angepasst (-12 und verdoppelt weil right-axis 0.5)
#
/usr/bin/rrdtool graph $pfad/pv_graph$z.png \
--start -$i \
-D -N -E -r -a PNG \
--upper-limit 3.5 \
--lower-limit 2 \
-t "Durchschnittswerte $i " \
--font LEGEND:8 \
--vertical-label "Volt" \
--right-axis 10:-20 \
--right-axis-label "Ampere" \
--full-size-mode -w 500 -h 200 \
--watermark "`date`" \
DEF:strom=$rrdp/$db.rrd:strom:AVERAGE \
DEF:spannung=$rrdp/$db.rrd:spannung:AVERAGE \
CDEF:spann1=spannung,20,+,10,/ \
LINE:strom#FF0000 \
LINE:spann1#0000FF \
LINE1:strom#FF0000:"Spannung" \
LINE1:spann1#0000FF:"Strom"

done

#--------------------Schleife 2 für Erzeugung der MAX Werte---------------------------#
for i in "${zeitraum[@]}"
do
counter=$((counter + 1))
z="$(printf '%02d' "$counter")"
/usr/bin/rrdtool graph $pfad/pv_graph$z.png \
--start -$i \
-D -N -E -r -a PNG \
--upper-limit 3.5 \
--lower-limit 2 \
-t "Maximalwerte $i " \
--font LEGEND:8 \
--vertical-label "Volt" \
--right-axis 10:-20 \
--right-axis-label "Ampere" \
--full-size-mode -w 500 -h 200 \
--watermark "(c) DL 7 ATA   -   `date`" \
DEF:strom=$rrdp/$db.rrd:strom:MAX \
DEF:spannung=$rrdp/$db.rrd:spannung:MAX \
CDEF:spann1=spannung,20,+,10,/ \
LINE:strom#FF0000 \
LINE:spann1#0000FF \
LINE1:strom#FF0000:"Spannung" \
LINE1:spann1#0000FF:"Strom"
done

scr_end=$(date +%s)
z=$((scr_end - $scr_start))
echo -e "\n graph.sh fertig  in $((z % 3600 /60)) min, $((z % 60)) s"
exit 0


CDEF:spann1=spannung,12.0,-,2.0,* \
