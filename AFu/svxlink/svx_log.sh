#!/bin/bash
# svx_log.sh	Erstellen eines svxlink-Logs der Echolinkverbindungen, monatliche Ausgabe in eine Datei
# DL7ATA	10.06.2019
#
#--------------------------------------------------------------------
#   Event		Feld			Inhalt		Feld
#1. Incoming		talker_from		Call		S2
#2.
#a	Accepting	talker_el_id	EL-Nummer		S3
#b	Rejecting	talker_el_id	EL-Nummer		S5
#3. CONNECTED		talker_date	Startzeit merken	S1
#4. DISCONNECTED	talker_date	Laufzeit ermitteln	S4
#--------------------------------------------------------------------
#
# Pfade und Dateien anpassen
PFAD='/var/log/'
DATEI='svxlink'
KUM_LOG='/home/svxlink/SvxSystem/svx-log/'
#---------------------------------------------------
lfd_monat=$(date +%y%m)
KUM_LOGPFAD="${KUM_LOG}svx_log.$lfd_monat.log"
LOGFILE=${PFAD}${DATEI}
#---------------------------------------------------
S1="changed to CONNECT"
S2="Incoming"
S3="Accepting"
S5="Rejecting"
S4=" DISCONNECTED"
declare -a log_array
typeset -i i=0

LOGFILE=${PFAD}${DATEI}

grep "$S1\|$S2\|$S3\|$S4\|$S5" "$LOGFILE" | while read text
do
  text_msg=''
  d_svx=$(echo $text | cut -c 12-19) #cut -d" " -f2)
  inbound=$(echo $text | cut -d" " -f3)

  # Eingehende EL-Verbindung darstellen
  if [[ $text == *" DISCONNECTED"* ]] ; then
    zeitOFF=$(echo $text | cut -c12-19)
    #in UNIX umwandeln
    zeitoff=`date --utc --date "$zeitOFF" +%s`
    talker=$(echo $text | cut -d":" -f4)
    text_msg="$talker_con"
    talker_from=''

  elif [[ $text == *"Accepting"* ]]; then
    talker_el_id=$(echo $text | cut -d" " -f9)

  elif [[ $text == *"Rejecting"* ]] ; then
    talker_from=$(echo $text | cut -d" " -f6)
    talker_el_id="Rejecting"

  elif [ "$inbound" == "Incoming" ] ; then
    talker_from=$(echo $text | cut -d" " -f7-8)

  elif [[ $text == *"CONNECTING"* ]] ; then
    talker_from=$(echo $text | cut -d" " -f3)
    talker_el_id="outbound"

  elif [[ $text == *" CONNECTED"* ]]; then
    talker_date=$(echo $text | cut -d":" -f1-3)
    zeitON=$(echo $text | cut -c12-19)
    #in UNIX umwandeln
    zeiton=`date --utc --date "$zeitON" +%s`
    talker_con="$talker_date $talker_from"

  else
    :
  fi

  #counter=$(( $counter + 1 ))
  #echo -e "$counter \r\c"

  if [ -n "$text_msg" ]; then
    z1=$(echo $(($zeitoff-$zeiton)))

  talk_zeit=$(echo "$((z1 / 3600)):$((z1 % 3600 /60)):$((z1 % 60))")
    echo -e "$talker_con|EL-Id $talker_el_id|Ende: $d_svx|/ $talk_zeit" | awk -F '|' '{ printf ("%-45.45s%19.19s%15s%-25.25s\n", $1 ,$2 ,$3, " " $4)}' >> $KUM_LOGPFAD

  fi

done

exit
