#!/bin/bash
# http.sh	by DL7ATA
# Auf Events des svxlink - Log reagieren und auf Oled des HTTP-Servers eines ESP-32 ausgeben
# Konfiguriert für 2 Logiken
# bei eingehendem EL-Connect Suche in BNetzverzeichnis.PDF oder auf QRZ.com
#
# 04.04.2019
# _________________________________________________________________________________
# Nomenklatur aus:
#[RemoteLink]
#CONNECT_LOGICS=SimplexLogic:31:R2,RemoteLogic:31:R70
#[NetLink_Ostlink]
#CONNECT_LOGICS=SimplexLogic:34:NL2,Logic_Ostlink

#Stand: 11.1.20
# _________________________________________________________________________________

typeset -i tx_minuten
# Timeout in Minuten für 2m-Logik
tx_minuten=30

callbook="/home/svxlink/Temp/Call_DL.txt"
qrz_proc="/home/svxlink/Scripte/QRZ_call.sh"
typeset -i tx_timeout
tx_timeout=tx_minuten*60
such_string="Talker "
open_2m="2mRx: The squelch is OPEN"
tx_70cm="70cmTx: Turning the transmitter ON"
activate_logik="Activating link RemoteLink"
disconnect="DISCONNECTED"

status_thrg_file='/var/tmp/svx.remote_netlink2_status'
status_2m_file='/var/tmp/svx.remote_link_status'
logfile="/tmp/svx/http.log"
lastheard_file="/tmp/svx/lastheard"
declare -A myarray

tx_time_2m=$(date +%s)

tail -F --lines 50 /var/log/svxlink | while read text
do
  t=$(date -d @$tx_time_2m)
  d=$(date +%d.%m.-%H:%M:%S)
  #d=$(date +%H:%M:%S)
  status_thrg=$(cut $status_thrg_file -d" " -f3)
  status_2m=$(cut $status_2m_file -d" " -f3)

  # Wemos per HTTP versorgen und auf 'Talker' reagieren
  d_svx=$(echo $text | cut -d" " -f2)   # Uhrzeit
  talker=$(echo $text | cut -d" " -f5)	# Status START, STOP
  inbound=$(echo $text | cut -d" " -f3) # Reagieren auf eingeh. EL-Vbdg.: Incoming
  text_call=$(echo $text | cut -d" " -f9) # Call

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
  if [ "$inbound" == "Incoming" ]; then
    talker=" ${inbound}"
    text_call=$(echo $text | cut -d" " -f7 | cut -d"-" -f1)		#Call aus Zeile suchen und mögliche -L oder -R abtrennen

    # Suche in BNetzverzeichnis oder QRZ.com
    NAME=$(grep "${text_call}," ${callbook} | cut -d" " -f3- | cut -b -35 | cut -d";" -f1)					#Name

    # echo "Ausgabe NAME bei eingeh. EL: $NAME"

    if [ "$NAME" == "" ]; then
	qrz_call=$(${qrz_proc} "${text_call}")
	if [[ $qrz_call == *"Not found:"* ]]; then
           text_msg=" "${text_call}" "
	else
	   text_msg=" "$qrz_call
	fi
    else
	    QTH=$(grep -1 $text_call ${callbook} | cut -d"," -f1,3- | sed -n "/${text_call}/{n;p;}" | cut -d";" -f2-)	#Stadt
	    text_msg=" "${NAME}${QTH}
    fi
  fi

  if [[ $text == *"*** WARNING: Dropping incoming connection due to"* ]]; then
      text_msg="*Dropped:"${text_call}
  fi

  if [[ $text == *"$disconnect"* ]] ; then
    talker="  Disconnected"
    text_call=$(echo $text | cut -d":" -f4 | xargs) # Call
    text_msg=" "$text_call"      "
  fi

  if [ -n "$text_msg" ]; then
    # Array füllen
    call=$(echo $text_msg | cut -b -35)             # Call
    zeit_raw=$(echo $text | cut -c 12-19)          # Uhrzeit
    zeit_Stempel=$(date -d $zeit_raw +%s)
    # echo -e "Array füllen: $text_call $zeit_Stext"			# ZU DEBUGZWECKEN
    myarray["${call}"]="${zeit_Stempel}"
    d_svxD=$(date +%d.%m.-%H:%M:%S)
    text_msg_log="$d_svxD: ${text_msg}   $talker"

    # Ausgabe an Wemos senden
    text_msg="$d_svx   svx${text_msg}   $talker"
    resp=$(curl -sio /dev/null  --connect-timeout 1,5 --head -f "http://192.168.10.181/$text_msg" -w '%{http_code}')

    # Falls esp aus ist, Timeout abfangen
    if [ $? != 0 ]; then
          echo -e "$(date +%H:%M:%S): Timeout Wemos - Errorcode $?. resp = $resp"
          sleep 1
    fi

    # Ausgabe Lastheard-Tabelle
    for VALUE in "${!myarray[@]}"
    do
       last_time=${myarray[$VALUE]}
       last_date=$(date -d @${myarray[$VALUE]} +'%d.%m. %H:%M:%S')
       echo -e  $last_time $last_date ${VALUE}
    done |
    sort -n -k1 | cut -d" " -f2- > $lastheard_file

    echo $text_msg_log > $logfile
    text_msg_log=''
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
