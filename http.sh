#!/bin/bash
# http.sh	by DL7ATA
# Aufruf über Startprozedur http_start.sh
#
# 04.09.2019	Manuelle, dauerhafte Deaktivierung 2m zulassen
# Status 2m-Link: 0 dauerhaft getrennt, 1 verbunden, 2 temp. getrennt
# 26.07.2019	Bei manueller Aktivierung, Rücksetzen des Timers
# 10.05.2019	Eingehende EL-Verbindung ausgeben
# 07.05.2019	Status Thrg_Link aus cut 'svx.remote_netlink2_status' auslesen
# 04.04.2019	Teil I. implementiert
#
# I. 2m-Logik Timeout und disc. nach $tx_timeout Sekunden
# II. svxlink-Talker auf esp8266-OLED per http senden
#

# Timeout in Sek. für 2m-Logik
tx_timeout=360

such_string="Talker " #start:"
open_2m="2mRx: The squelch is OPEN"
tx_70cm="70cmTx: Turning the transmitter ON"
activate_logik="Activating link RemoteLink"

status_thrg_file='/var/tmp/svx.remote_netlink2_status'
status_2m_file='/var/tmp/svx.remote_link_status'
logfile="/tmp/http.log"

tx_time_2m=$(date +%s)

tail -F --lines 2 /var/log/svxlink | while read text
do
  t=$(date -d @$tx_time_2m)
  d=$(date +%H:%M:%S)
  status_thrg=$(cut $status_thrg_file -d" " -f3)
  status_2m=$(cut $status_2m_file -d" " -f3)

 # Teil I - 2m Timer: Bei Aktivität, Logiken verbinden - bei Inaktivität und Timeout, 2m & 70cm-Logiken trennen, wenn Thrg.-Link nicht zugeschaltet (0)
 if [ "$status_thrg" == "0" ];then
   talk=$(echo $text | cut -d" " -f3-7)
   tx_svx=$(echo $text | cut -c 12-19)
   tx_time=$(date -d $tx_svx +%s)
   diff_time=$(( $(date +%s) - $tx_time_2m ))

# # Wenn nicht manuell getrennt
 if [ "$status_2m" != "0" ];then

   # Wenn 2m sendet Timer starten:
   if [ "$talk" == "$open_2m" ];then
     echo "$d: 2m spricht: ${talk}. 2m_link_Status: ${status_2m}"
     tx_time_2m=$tx_time

     # Sind die Logiken temp. getrennt (2 in svx.remote_link_status), dann verbinden
     if [ "$status_2m" == "2" ];then
	echo "$d: Logiken verbinden"
	echo "*911#" > /tmp/svx_pty.SimplexLogic

     fi

   # Wenn 70cm sendet oder LINK aktiviert
   # Prüfe ob VERBINDEN-Cmd
   elif [ "$talk" == "$activate_logik" ];then
 	echo "$d: Manuelle Aktivierung der Logiken, $talk"
        tx_time_2m=$(date +%s)

   elif [[ "$talk" == "$tx_70cm" ]] && [[ "$status_2m" == "1" ]];then
	echo "$d: 2+70 verbunden, 70 spricht, $talk"
	# prüfen ob Timer abgelaufen
        if [ $diff_time -gt $tx_timeout ];then
	   echo "$d: Timeout, trenne Logiken"
 	   echo "*910#" > /tmp/svx_pty.SimplexLogic
	   sleep 2
	   echo "set status_link 2" > /var/tmp/svx.remote_link_status
	fi
   else
	   :
   fi

  #else
  #   echo "$d: ${talk} - Logiken dauerhaft getrennt"
  fi

 # Status Thrg-Link
 fi

  # Teil II - Wemos per HTTP versorgen und auf 'Talker' reagieren
  d_svx=$(echo $text | cut -d" " -f2)
  talker=$(echo $text | cut -d" " -f5)
  inbound=$(echo $text | cut -d" " -f3)

  # Netlink-Status: Wenn nicht = 0: Thrg.-Link aktiviert
  if [ "$status_thrg" == "0" ]; then
    such_link="Logic_DL7ATA"
    text_msg=$(echo $text | grep --line-buffered "$such_link" | grep --line-buffered "$such_string" | cut -d":" -f6)
  else
    ausblenden="DB0TGO"
    such_link="Logic_"
    text_msg=$(echo $text | grep -v "$ausblenden" | grep --line-buffered "$such_link" | grep --line-buffered "$such_string" | cut -d":" -f6)
  fi

  # Eingehende EL-Verbindung darstellen
  if [ "$inbound" == "Incoming" ] ; then
    text_msg=" ${inbound}"
    talker=$(echo $text | cut -d" " -f7-8)
  fi

  if [[ $text == *"BYE_RECEIVED"* ]] ; then
    text_msg=" Disconnected"
    talker=$(echo $text | cut -d":" -f4)
  fi

  # Ausgabe an Wemos senden
  if [ -n "$text_msg" ]; then
    text_msg_log="$d_svx: ${text_msg}   $talker"
    text_msg="$d_svx   svx${text_msg}   $talker"
    resp=$(curl -i -o /dev/null  --connect-timeout 1,0 -s --show-error --head -f "http://192.168.10.181/$text_msg" -w '%{http_code}')

    # Falls esp aus ist, Timeout abfangen
    if [ $? != 0 ]; then
          echo -e "$(date +%H:%M:%S): Timeout Wemos - $?"
          sleep 1
    fi

    echo $text_msg_log
  fi

done

#hierher kommen wir nie .....
exit 1

# Beschreibung OLED Zeilen:
# 16 Spalten
# 4 Zeilen
text_msg="\
	1234567890123456\
	789012345678901\
	2344567890123456\
	789012345678901"
