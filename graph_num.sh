#!/bin/bash
# graph_num.sh
# Werte aus PV.rrd extrahieren
# Aufruf @weekly in crontab
# __________________________________________________________________
#   1.0		29.03.2019	Grafik eliminiert, Ausgabe der Werte in Zahlenformat in Datei
#
# Felder: spannung / verbrauch / ertrag
#______________________________________________________________________
#
# Beispiel unter https://stackoverflow.com/questions/11353289/rrdtool-gprint-formatting-with-printf
# https://raspcb.wordpress.com/projekte/temperaturauswertung-mit-rrdtool/
#------------indiv. anpassung--------------------------------------#
pfad="/home/svxlink/PV/Ertrag/"
rrdp=/tmp
declare -a zeitraum=( "720h" "168h" "24h")	 # pro Eintrag wird eine Zahlenreihe erstellt
#declare -a typ=("AVERAGE" "MAX")
declare -a typ=("MAX")
#------------------------------------------------------------------#
a=$(date +%M)
heute=$(date +"%H:%M:%S")
declare -i counter
tag=$(date +%y%m%d)
datum=$(date -R)
hour=$(date +%H)
minute=$(date +%M)
aktZ="${hour}:${minute}"
declare -i scr_start
declare -i scr_end
scr_start=$(date +%s)
lfd_tag=$(date +%y%j)
ausgabe=${pfad}PV-Ausgabe_$lfd_tag.txt
let counter=0

# Start
echo -e "\ngraph_num.sh gestartet um $heute, Ausgabe in $ausgabe \n"
#rm -f $ausgabe

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
then			# Angabe war schon in Stunden
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

#echo -e "\nErstelle $h für '$zr'h mit $zr2 $einheit"

werte=$(~/rrdtool-1.x/src/rrdtool graph /dev/null \
--start -$zr \
DEF:ertrag=$rrdp/PV.rrd:ertrag:AVERAGE \
DEF:verbrauch=$rrdp/PV.rrd:verbrauch:AVERAGE \
DEF:spannung=$rrdp/PV.rrd:spannung:$h \
CDEF:spann1=spannung,12.0,-,5.0,* \
CDEF:ertr_wh=ertrag,spannung,*,$zr2,* \
CDEF:verb_wh=verbrauch,spannung,*,$zr2,* \
PRINT:ertr_wh:AVERAGE:"Ertrag %2.2lf Wh" \
PRINT:verb_wh:AVERAGE:" Verbrauch %2.2lf Wh" \
PRINT:spannung:MIN:"  Minimum %2.2lf V" \
PRINT:spannung:MAX:"Maximum %2.2lf V " \
| sed 's/.*0x0//')

echo -e "$h - $zr2 $einheit: \t" $werte >> $ausgabe

done
#--------ende-Schleife-2-------------------------------------------------

done
#--------ende-Schleife-1-------------------------------------------------

# Erstellen Ausgabe für php-Aufbereitung
PFAD='/tmp/Bilder/pv_Wh'
/home/svxlink/PV/pv_woche.sh > $PFAD

scr_end=$(date +%s)
z=$((scr_end - $scr_start))
echo -e "\ngraph_num.sh fertig  in $((z % 3600 /60)) min, $((z % 60)) s"

exit 0

PFAD='/tmp/Bilder/pv_Wh'
echo "Ertrag letzte ...." > $PFAD
var=$(sed -n '1p' $ausgabe | cut -d" " -f7); printf "4 Wochen   %'6.f Wh\n" $var" >> $PFAD
var=$(sed -n '2p' $ausgabe | cut -d" " -f7); printf "Woche      %'6.f Wh\n" $var" >> $PFAD
var=$(sed -n '3p' $ausgabe | cut -d" " -f7); printf "24 Stunden %'6.f Wh\n" $var" >> $PFAD
echo "Stand: $(date +%y%M%d-%H:%M:%S)"
