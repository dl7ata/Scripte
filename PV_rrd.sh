#!/bin/bash
# PV_rrd.sh	s.a. Änderungshistorie unten
# (c) by DL7ATA
# Funktion:
# - Daten an Schnittstelle  /dev/ttyAMC0 sammeln und in RRD Datenbank speichern
# - Systemmeldung für svxlink erzeugen bei Unterschreitung einer definierten Mindestspannung
# - Aufbereitung und Ausgabe der lfd. Messdaten für APRS, svxlink und //banana26/p.php-Seite  in der Reihenfolge d. Arduino-Ausgabe:
#
#  >>  akt. Spannung in Volt / Verbrauch in Amp. / Ertrag in Amp <<
#
#	Aufbau des Datensatzes "PV_Ertrag.txt" s. Datei "Doku_Ertrag.txt"
#
# $ardu_LA / $D1h_LA / $Kum_LAa / $Kum_LAw / $ardu_VA / $D1h_VA / $Kum_VAa / $Kum_VAw / $ardu_VO / $datum
#   1	      2		3	   4		5	6	    7		8	9	  10
# Inhalt:
# Feld 1: Aktueller Ladestrom in A
# Feld 2: Durchschnittlicher Ertrag in der letzten Stunde in Ah
# Feld 3: Ertrag seit Mitternacht in Ah
# Feld 4: Ertrag seit Mitternacht in Wh
# Feld 5: Aktueller Verbrauchsstrom in A
# Feld 6: Durchschnittlicher Verbrauch in der letzten Stunde in Ah
# Feld 7: Verbrauch seit Mitternacht in Ah
# Feld 8: Verbrauch seit Mitternacht in Wh
# Feld 9: Aktuelle Spannung in Volt
# Feld 10: Stempel Datum-Uhrzeit
# Feldzähler
# Feld 11 - 18
#
#	LA = Ladestrom der Photovoltaik	 	VA = Strom Verbrauch/Entnahme		VO = Spannung
#
#	akt. Werte	Durchschnitt. letzte Stunde	seit 0h in A	seit 0h in Wh
#	ardu_LA		D1h_LA				Kum_LAa		Kum_LAw
#	ardu_VA		D1h_VA				Kum_VAa		Kum_VAw
#	ardu_VO		M1h_VO (Maximalwert)
#
#-------------------------+
# Ladestrom: max. 9,5A
# Entnahmestrom: max. 15A
# Spannung: 12-16V
#-------------------------+
#
# Variable ardu_LA  Übergabe vom Arduino = Ladestrom, 2-Nachkommastellen mit Dezimalpunkt
# Variable ardu_VS  Übergabe vom Arduino = Entnahmestrom, 2-Nachkommastellen mit Dezimalpunkt
# Variable ardu_VO Übergabe vom Arduino = Spannung    "           "
#
# ar_d1h_LA Array sammelt pro Sekunde den Strom zur Ermittlung des durchschn. stündlichen Ertrags in Ah
# ar_d1h_VA Array sammelt pro Sekunde den Strom zur Ermittlung des durchschn. stündlichen Verbrauchs in Ah
# ar_kumLAw Array sammelt pro Sekunde die Leistung in KWh zur Ermittlung tgl. Ertrags in KWh
# ar_kumVAw Array sammelt pro Sekunde die Leistung in KWh zur Ermittlung tgl. Ertrags in KWh
#_________________________________________________________________________________________________________
#			08.04.2019	Theoret. max. Ertrag (max_Ertrag24wh) ermitteln und ausgeben
#			03.04.2019	Ausgabe der Verbrauchswerte für svxlink
#   1.3.		22.01.2019	10 Sek. Spitzenwert nür für Ausgabe verwenden; echte Werte in DB speichern
#   1.2.		17.01.2019	10 Sek. Spitzenwert  LA ermitteln und in PV_Ertrag.txt ausgeben
#   1.1.		22.12.2018	Kum. Werte einlesen aus $twt
# V 1.0.neu		15.12.2018
#
#----------------------------------------------------------------------------------
# Mindestwert in Volt (ein 10-faches davon) der dauerhaft nicht unterschritten werden darf
Min=123
#
ARDUINO_PORT=/dev/ttyACM0
ARDUINO_SPEED=9600
FILE_PREFIX=/tmp/PV
RRDFILE=${FILE_PREFIX}.rrd

# Anzahl der gespeicherten Werte zur Unterschreitung der Mindestspannung (3600 Sek. = 1h) sowie Ermittlung Strom pro Einheit
typeset -i stunden_sekunden=3600
typeset -i h=0
# 10-Sekundenzähler
typeset -i i=0
# Tagesstundenzähler. Reset um Mitternacht
j24=0
typeset -i D1h_LA=0
typeset -i D1h_VA=0
Ertrag=0
Ertrag24=0
Leistung=0
max=0
# Maximalwert Ladestrom der letzten 10 Sek.
max10s_LA=0
max_Ertrag24wh=0

echo "PV_rrd.sh gestartet: $(date)"
# Merker um beim Tageswechsel den 24h-Wert auszugeben
heute=$(date "+%Y%m%d")

# Set speed for usb
stty -F $ARDUINO_PORT $ARDUINO_SPEED raw -clocal -ixon
# Redirect Arduino port to file descriptor 6 for reading later
exec 6<$ARDUINO_PORT
# Wg. Dezimalpunkt "."
export LC_NUMERIC="en_US.UTF-8"

# Per cronjob erstellte Auf- und Untergangszeiten lesen aus Datei
datei="/tmp/sunset.txt"
t=$(cat $datei)
auf=$(echo ${t:0:5})
unter=$(echo ${t:5:6})
dauer=$(echo ${t:12:13})

# Tageswerte einlesen falls vorhanden
twt="/tmp/PV_Ertrag.txt"
tw="/home/svxlink/PV/Ertrag/PV_Ertrag.txt"

# falls $twt nicht existiert oder neuer ist als die Version in /tmp:
if [ ! -e $twt ] || [ $tw -nt $twt ]; then
   cp $tw $twt
fi

if [ -e $twt ]; then
   Sum1h_LA=$(cat $twt | cut -f 13 -d" ")
   Kum_LAa=$(cat $twt | cut -f 14 -d" ")
   Kum_LAw=$(cat $twt | cut -f 15 -d" ")
   Sum1h_VA=$(cat $twt | cut -f 17 -d" ")
   Kum_VAa=$(cat $twt | cut -f 18 -d" ")
   Kum_VAw=$(cat $twt | cut -f 19 -d" ")
   Ertrag=$(echo "scale=1; $Sum1h_LA / $stunden_sekunden" | bc | awk '{printf("%.1f\n", $1)}')
   Ertrag24=$(echo "scale=1; $Kum_LAa / $stunden_sekunden / 10" | bc | awk '{printf("%.1f\n", $1)}')
   Leistung_LA=$(echo "scale=1; $Kum_LAw / $stunden_sekunden / 10" | bc | awk '{printf("%.1f\n", $1)}')
   Verbrauch=$(echo "scale=1; $Sum1h_VA / $stunden_sekunden" | bc | awk '{printf("%.1f\n", $1)}')
   Verbrauch24=$(echo "scale=1; $Kum_VAa / $stunden_sekunden / 10" | bc | awk '{printf("%.1f\n", $1)}')
   Leistung_VA=$(echo "scale=1; $Kum_VAw / $stunden_sekunden / 10" | bc | awk '{printf("%.1f\n", $1)}')
   Leistung_LA=$(echo "scale=1; $Kum_LAw / $stunden_sekunden / 10" | bc | awk '{printf("%.1f\n", $1)}')
   echo -e "\n$twt eingelesen. \nErtrag: $Ertrag24 $Leistung_LA | Verbrauch: $Verbrauch24 $Leistung_VA\n\n"
   echo   $ardu_LAp $Ertrag $Ertrag24 $Leistung_LA "||" $ardu_VAp $Verbrauch $Verbrauch24 $Leistung_VA "||" $ardu_VO $datum "||LA" $Sum1h_LA $Kum_LAa $Kum_LAw "||VA" $Sum1h_VA $Kum_VAa $Kum_VAw
else
   Kum_LAa=0
   Kum_LAw=0
   Kum_VAa=0
   Kum_VAw=0
fi

if [ ! -e $RRDFILE ]
 then
	if [ ! -e /home/svxlink/PV/PV.rrd ]; then
	 rrdtool create $RRDFILE --step 1 \
	 DS:spannung:GAUGE:5:12:16 \
	 DS:verbrauch:GAUGE:5:0:15 \
	 DS:ertrag:GAUGE:5:0:10 \
	 RRA:AVERAGE:0.5:1:86400 \
	 RRA:AVERAGE:0.5:60:1440 \
	 RRA:AVERAGE:0.5:60:10080 \
	 RRA:AVERAGE:0.5:3600:720 \
	 RRA:AVERAGE:0.5:86400:236 \
	 RRA:MAX:0.5:1:86400 \
	 RRA:MAX:0.5:60:1440 \
	 RRA:MAX:0.5:60:10080 \
	 RRA:MAX:0.5:3600:720 \
	 RRA:MAX:0.5:86400:236
       else
        cp /home/svxlink/PV/PV.rrd $RRDFILE
       fi
fi

# Read data from Arduino via file descriptor 6 [Workaround um Var 2 und 3 aus dem Arduinostring zu trennen]
while read -u 6 f g ;do
     datum=$(date +%d.%m.%y-%H:%M:%S)
     ((++i))
     ((++j))
     ardu_VO=$(awk -v "f=$f" 'BEGIN {printf "%.1f\n", f}')
     a=$(echo $g | cut -d" " -f1)
     b=$(echo $g | cut -d" " -f2)
     ardu_VA=$(awk -v "a=$a" 'BEGIN {printf "%.1f\n", a}')
     ardu_LA=$(awk -v "b=$b" 'BEGIN {printf "%.1f\n", b}')

     # Testausgabe
     # echo "Ladestrom: $ardu_LA / Max10s_LA: $max10s_LA / Verbrauch: $ardu_VA"

     # Messfehler bereinigen, keine negativen Werte möglich
     if [[ "$ardu_VA" =~ "-" ]]; then
            ardu_VA=0
     fi

     if [[ "$ardu_LA" =~ "-" ]]; then
            ardu_LA=0
     fi

     # Maximalwert STROM für 10 Sek. speichern.
     # Das geht so: Wenn $str (akt. Wert) > $max10 (letztem Max-Wert) ist, dann 1
     max1=$(echo "$ardu_LA > $max10s_LA" | bc)
     if [ $max1 -eq 1 ]
      then
        max10s_LA=$ardu_LA
     fi

     rrdtool update $RRDFILE N:$ardu_VO:$ardu_VA:$ardu_LA

     # Für Speichern in Array, Werte * 10 ohne Nachkommastelle ermitteln
     ardu_VO10=$(echo "$ardu_VO * 10" | bc | awk '{printf "%.0f\n", $1}')
     ardu_VA10=$(echo "$ardu_VA * 10" | bc | awk '{printf "%.0f\n", $1}')
     ardu_LA10=$(echo "$ardu_LA * 10" | bc | awk '{printf "%.0f\n", $1}')
     max10s_LAt=$(echo "$max10s_LA * 10" | bc | awk '{printf "%.0f\n", $1}')

     # Summe aller Stromwerte zur Addition auf Tagesertrag
     Kum_LAa=$((Kum_LAa+$ardu_LA10))
     Kum_VAa=$((Kum_VAa+$ardu_VA10))

     # Summe Leistung ermitteln
     Kum_LAw=$((Kum_LAw+($ardu_VO10*$ardu_LA10/10)))
     Kum_VAw=$((Kum_VAw+($ardu_VO10*$ardu_VA10/10)))
     # theoret. max. Leistung
     max_Ertrag24wh=$((max_Ertrag24wh+($max10s_LAt*$ardu_VO10)))

     if [ $i -ge 10 ]
      then
	aktZ=$(date +%H:%M)
	# Daten aufbereiten für Svxlink, APRS-Bake, APRS_Statistik und php-Skript
	# PV-Daten nur schreiben, wenn es noch hell ist
	if [[ ( $(date -d "$aktZ" +%s) -ge $(date -d "$auf" +%s) ) && ( $(date -d "$aktZ" +%s) -le $(date -d "$unter" +%s) ) ]]; then

	   # Summe aller Stromwerte PV in den letzten $h Sekunden zur Addition auf durchschn. Stundenertrag
	   ar_d1h_LA[$j]=$ardu_LA10
	   for x in ${ar_d1h_LA[@]}; do
	       Sum1h_LA=$((Sum1h_LA+$x));
	   done

	   # Aufbereitung der Zahlen in lesbares Format
	   Ertrag=$(echo "scale=1; $Sum1h_LA / $stunden_sekunden" | bc | awk '{printf("%.1f\n", $1)}')
	   Ertrag24=$(echo "scale=1; $Kum_LAa / $stunden_sekunden / 10" | bc | awk '{printf("%.1f\n", $1)}')
	fi

	# Summe aller Stromwerte Verbr. in den letzten $h Sekunden zur Addition auf durchschn. Stundenverbrauch
	ar_d1h_VA[$j]=$ardu_VA10
	for x in ${ar_d1h_VA[@]}; do
	    Sum1h_VA=$((Sum1h_VA+$x));
	done

	Verbrauch=$(echo "scale=1; $Sum1h_VA / $stunden_sekunden" | bc | awk '{printf("%.1f\n", $1)}')
	Verbrauch24=$(echo "scale=1; $Kum_VAa / $stunden_sekunden / 10" | bc | awk '{printf("%.1f\n", $1)}')
  	Leistung_VA=$(echo "scale=1; $Kum_VAw / $stunden_sekunden / 10" | bc | awk '{printf("%.0f\n", $1)}')
  	Leistung_LA=$(echo "scale=1; $Kum_LAw / $stunden_sekunden / 10" | bc | awk '{printf("%.0f\n", $1)}')
  	Leistung_LA_max24=$(echo "scale=1; $max_Ertrag24wh / $stunden_sekunden / 100" | bc | awk '{printf("%.1f\n", $1)}')

	 # Ausgaben:

	 # svxlink
	 echo $ardu_VO | sed 's/,/./' | sed 's/^/set PV_Spannung /g' > /tmp/svx_PV_Strom 2>&1
         echo $max10s_LA | sed 's/,/./' | sed 's/^/set PV_Strom /g' >> /tmp/svx_PV_Strom 2>&1
	 echo $Ertrag | sed 's/,/./' | sed 's/^/set PV_1h /g' >> /tmp/svx_PV_Strom 2>&1
	 echo $Ertrag24 | sed 's/,/./' | sed 's/^/set PV_24h /g' >> /tmp/svx_PV_Strom 2>&1
	 echo $Leistung_LA | sed 's/,/./' | sed 's/^/set PV_kwh /g' >> /tmp/svx_PV_Strom 2>&1

         echo $ardu_VA | sed 's/,/./' | sed 's/^/set VA_Strom /g' >> /tmp/svx_PV_Strom 2>&1
	 echo $Verbrauch | sed 's/,/./' | sed 's/^/set VA_1h /g' >> /tmp/svx_PV_Strom 2>&1
	 echo $Verbrauch24 | sed 's/,/./' | sed 's/^/set VA_24h /g' >> /tmp/svx_PV_Strom 2>&1
	 echo $Leistung_VA | sed 's/,/./' | sed 's/^/set VA_kwh /g' >> /tmp/svx_PV_Strom 2>&1

         # APRS.fi-Statistik auf Banana
         echo $max10s_LA " " $ardu_VA > /tmp/APRS.Strom 2>&1

	 ardu_LAp=$(printf "%.1f\n" $max10s_LA)
	 ardu_VAp=$(printf "%.1f\n" $ardu_VA)

         # Master-String u.a. für php-Skript auf Banana, Oledausgabe usw.
	 #  	           $Sum1h_LA $Kum_LAa    $Kum_LAw       	      $Sum1h_VA    $Kum_VAa	  $Kum_VAw
	 # 	$ardu_LA / $Ertrag / $Ertrag24 / $Leistung_LA / $ardu_VA / $Verbrauch / $Verbrauch24 / $Leistung_VA / $ardu_VO / $datum /              $Sum1h_LA $Kum_LAa $Kum_LAw   $Sum1h_VA $Kum_VAa $Kum_VAw
	 #      1          2         3           4              5          6            7              8   9          10         11                12  13        14       15     16  17        18       19
	 #      0.1        0.2       1.7         21.9           0.0        0.0          0.0            0.4 |          12.9       19.12.18-14:47:04 |LA 1004      61911    790331 |VA 11        1324     16043

         echo  	$ardu_LAp $Ertrag $Ertrag24 $Leistung_LA $ardu_VAp $Verbrauch $Verbrauch24 $Leistung_VA "|" $ardu_VO \
		$datum "|LA" $Sum1h_LA $Kum_LAa $Kum_LAw "|VA" $Sum1h_VA $Kum_VAa $Kum_VAw \
		> /tmp/PV_Ertrag.txt 2>&1

         Sum1h_LA=0
         Sum1h_VA=0
	 max10s_LA=$ardu_LA
         i=0
    fi

  # Maximalwert SPANNUNG der letzten $stunden_sekunden in Array speichern. Dazu Wert * 10 ohne Nachkommastelle ermitteln
  strN=$(echo "$ardu_VO * 10" | bc | awk '{printf "%.0f\n", $1}')
  array[$j]=$strN

  if [ $j -eq $stunden_sekunden ] ;then
     h=0
     j=0
     max=0
     j24=$((j24+1))

     # Maximalwert Spannung der letzten $stunden_sekunden ermitteln in $max für Mindestspannungs-Prüfung
     for v in ${array[@]}; do
         if (( $v > $max )); then max=$v; fi;
     done

     # Stündliche Ausgabe ins Log:
     echo  -e "$datum: max. V 1h $max / aktuell $ardu_VO |Verbrauch: 1h $Verbrauch A/ seit 0h $Leistung_VA Wh| Ertrag: 1h $Ertrag Ah / seit $j24 h: $Leistung_LA Wh / theoret. Wh $Leistung_LA_max24" >> /tmp/PV_rrd.log

     # Prüfen ob Mindestspannung unterschritten
     max2=$(echo "$max < $Min" | bc)
     if [ $max2 -eq 1 ]; then
        meldungs_datum=$(date +%d.%m.%Y)
        meldungs_h=$(date +%H)
        meldungs_m=$(date +%M)
	# Umwandeln $Min in lesbares Format
	min=$(echo "scale=1; $Min / 10" | bc | awk '{printf("%.1f\n", $1)}')
        echo "#PV#DL7ATA-9#Die Spannung der Solarbatterie beträgt $ardu_VO Volt und hat dauerhaft $min Volt unterschritten. Meldung generiert am $meldungs_datum, $meldungs_h Uhr." > /tmp/aprsmsg.text
     fi

     # Prüfen ob Tageswechsel vorliegt, dann Speichern der Tageswerte, Sonnenauf- und -untergangszeiten aktualisieren
     vortag=$(date -d 'yesterday' "+%Y%m%d")
     if [ "$vortag" == "$heute" ]; then
	 echo "$heute $Verbrauch24 $Leistung_VA $Ertrag24 $Leistung_LA $dauer $Leistung_LA_max24" >> ~/PV/Ertrag/Ertrag.txt
	 heute=$(date "+%Y%m%d")
	 Sum1h_LA=0
	 Sum1h_VA=0
	 Kum_LAa=0
	 Kum_LAw=0
	 Kum_VAa=0
	 Kum_VAw=0
	 Ertrag24=0
	 Leistung=0
	 Ertrag=0
	 Verbrauch=0
	 max_Ertrag24wh=0
	 j24=0
	 # Per cronjob erstellte Auf- und Untergangszeiten lesen und aufbereiten aus Datei
	 t=$(cat $datei)
	 auf=$(echo ${t:0:5})
	 unter=$(echo ${t:5:6})
	 dauer=$(echo ${t:12:13})
     fi
     Max=$(echo "scale=1; $ardu_VO / 10" | bc | awk '{printf("%.1f\n", $1)}')
  fi

done

exit 0
