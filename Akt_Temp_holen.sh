#!/bin/bash
# Akt_Temp_holen.sh
# (c) by DL7ATA
# ---------------------------------------------------------------------------------------------
# Script zur Erzeugung einer aktuellen Temperaturmeldung, wird per cronjob regelmäßig aufgerufen und stellt 
# u.a. für /usr/share/svxlink/events.d/local/Logic.tcl Temperatur als Textvariable zur Verfügung
#
# 10.04.2019	Einfügen Timeout-Parameter bei curl-Aufruf
#
# 30.8.2018	letzte Überarbeitung und Anpassung log-Ausgabe und mehr
#
# 18-12-2016 	v1.4  8.1.2018
# Ausgabe des Wertes für APRS-Statistik: "APRS.TempLuft"
#
# v1.3 vom 4.10.2017
# Falls aviationweather nicht erreichbar, Aufruf der guten alten APRS-Prozedur
#
# v1.2 vom 30.7.2017
# Dezimalstelle mit "cut -d. -f1" abgeschnitten
#
# v1.1 vom 21.5.2017
# Nur Temperatur von EDDT geholt
#
# d=$(date +%y%m%d.%H%M%S)   #Standard
#------------------individuelle Anpassungen-Anfang----------------------------------------------------------------
PFAD=/tmp			#Pfad wo das Spektakel zwischengepeichert werden soll
LK=EDDT				# der gewuenschte Flughafen
server="https://www.aviationweather.gov"
serv_str="/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&hoursBeforeNow=3&mostRecent=true&stationString=$LK"
svx_text="set"
#------------------extrahieren des Textes-----------------------------------------------------------------------

# und prüfen zunächst, ob die Seite erreichbar ist ...
Status_code=$(curl --max-time 5,0 --output /dev/null --silent --head --write-out '%{http_code}\n' "$server")
echo -e " $(date)\nStatuscode für $server: $Status_code"

 # wenn ja = 200
 if [ $Status_code = "200" ]; then
	echo "Hole WX Daten von $server für $LK"
	cont=$(curl -s  --max-time 10 "$server$serv_str")
	# Extrahieren aus der HTML-Seite mit sed:
	msg=$(echo -n "$cont" |  grep '<temp_c>' | sed 's/<temp_c>/temp /g' | sed 's/<\/temp_c>//g' | sed 's/^[ \t]*//' | cut -d. -f1 )

	if [ -n "$msg" ]; then
		echo "$svx_text $msg" > $PFAD/svx_akt_temp
		echo "$msg" | cut -c 6- > $PFAD/APRS.TempLuft
	else
		# Alternative Quelle
		echo "APRS holen weil GOV nicht erreichbar."
		/bin/bash /home/svxlink/Wetter/Akt_Temp_APRS.sh
	fi
 else
		echo "Hole alternativ via Python..."
		/bin/bash /home/svxlink/Wetter/metar.sh
 fi

log=$(echo $msg | cut -c 6-)
echo $log "°C"

exit 0
