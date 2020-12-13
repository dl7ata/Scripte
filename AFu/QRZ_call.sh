#!/bin/bash
# QRZ_call.sh
# Rufzeicheninfos aus QRZ.com holen
# Aufruf mit <QRZ_call.sh RUFZEICHEN>
#
# 13.12.2020	DL7ATA
#
# Dazu wird ein einfacher Account auf QRZ.COM benötigt
# Zunächst muss ein Hash-key per einfacher Anmeldung erzeugt und gespeichert werden,
# dieser wird dann bei jeder weiteren Abfrage zur Identifizierung verwendet.
#
# Anpassen:
mycall='DB5***'
pass='***'
#-----------------------------------------------------

qrz_url="https://xmldata.qrz.com/xml/"
suche="$1"

function key_holen() {
    Status_code=$(curl --write-out %{http_code} --silent --output /tmp/qrz_key "${qrz_url}?username=${mycall};password=${pass}")
    qrz_key=$(cat /tmp/qrz_key |  grep Key | awk -F'[<">">]' '{print $3}')
    echo $qrz_key > /tmp/qrz_key
    ret=$? 				# store return value for later usage in the error message
    if [ "$Status_code" -ne 200 ] ; then
	echo "Lief allet falsch: $Status_code - $ret"
	exit 1
    fi
}

function call_holen() {
    qrz_key=$(cat /tmp/qrz_key)
    Status_code=$(curl --write-out %{http_code} --silent --output  /tmp/qrz "${qrz_url}current/?s=${qrz_key};callsign=${suche}")
    if [ "$Status_code" -ne 200 ] ; then
        echo "Failed with exit code $ret, getting KEY"
	key_holen
    else
	echo "$suche holen Status: $Status_code"
    fi
}


if [ -z "$suche" ];then
   echo "Aufruf mit Such-Call ..."
   exit 1
else
   echo "$(date +%H:%M:%S) Suche nach ${suche}"
   call_holen

  # XML zerlegen nach relevanten Filtern, im Array speichern und am Ende mit "echo" komplett ausgeben
  i=0
  declare -a a_array

  rdom () { local IFS=\> ; read -d \< E C ;}
  while rdom; do
      if [[ $E = "fname" ]]; then
        a_array[i]=$C
    elif [[ $E = "name" ]]; then
        a_array[i]=$C
    elif [[ $E = "addr2" ]]; then
        a_array[i]=$C
    elif [[ $E = "country" ]]; then
        a_array[i]=$C
    elif [[ $E = "Error" ]]; then
        a_array[i]=$C
    fi
    ((++i))
  done < /tmp/qrz

  echo -e "${a_array[@]}"

fi

exit 0
