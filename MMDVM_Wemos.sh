#!/bin/bash
# http.sh	by DL7ATA
#
# 28.06.2019	Version "MMDVM/DMR"
# Wandelt die UTC-Logzeit in Lokalzeit um

start_rcv="received network voice header from"
end_rcv="received network end of voice transmission"
logfile="/var/log/MMDVM/MMDVM-`date +%Y-%m-%d`.log"

while true; do

 utc=$(echo `date +%:::z `)
 if [ "$utc" == "+02" ];then
   utc_offset=7200
 elif [ "$utc" == "+01" ];then
   utc_offset=3600
 else
   echo "Fehler UTC-Offset: $utc -  good bye..."
   exit 9
 fi

   tail -F --lines 2 $logfile | while read text; do

  # Auf 'such_string' reagieren
  if [[ $text == *"$start_rcv"* ]] ; then
     text_msg=$(echo $text | cut -d" " -f12-15)
  elif [[ $text == *"$end_rcv"* ]]; then
     text_msg2=$(echo $text | cut -d"," -f3-4)
     text_msg="$text_msg $text_msg2"
  else
     text_msg=""
  fi

   # Ausgabe an Wemos senden
   if [ -n "$text_msg" ]; then
     dmr_time=$(echo $text | cut -d" " -f3 | cut -d"." -f1)
     dmr_timeS=$(($(date --date="$dmr_time" +%s) + $utc_offset))
     dmr_mesz=$(date -d "@$dmr_timeS" "+%H:%M:%S")
     # echo -e "$dmr_time / $dmr_timeS / $dmr_mesz\n"
     text_out="$dmr_mesz: DMR   $text_msg"
     resp=$(curl -i -o /dev/null  --connect-timeout 1,0 -s --show-error --head -f "http://<IP>/$text_out" -w '%{http_code}')

   # Falls esp aus ist, Timeout abfangen
   if [ $? != 0 ]
       then
         echo $?
         sleep 1
     else
         echo "$dmr_mesz: $text_msg"
     fi
   fi

 # Tageswechsel liegt vor, wenn neues Logfile da ist
 next_day=$(date +"%Y-%m-%d" -d "+ 1 day")
 if [ -e "/var/log/MMDVM/MMDVM-${next_day}.log" ]; then
   logfile="/var/log/MMDVM/MMDVM-${next_day}.log"
   break
 fi

 done

done
