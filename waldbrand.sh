#!/bin/bash
# Bake zur Aussendung möglicher Waldbrandwarstufen		DL7ATA 27.8.2018
#
# 19-06.2019	Verlagerung und Integration der TCPIP-ausgabe vom APRS-pi
# 26.04.2019	Ergänzt um Ausgabe als Object via TCPIP
# 19.04.2019	ping auf URL eingefügt; falls IN nicht verfügbar
#
# Checkout https://aprs.fi/#!mt=roadmap&z=10&call=a/GEFAHRUM&others=1&timerange=3600&tail=3600
#
# Bis zu welcher Warstufe soll nicht gewarnt werden?
soll_warnstufe=3
PFAD="/tmp"                       #Pfad wo das Spektakel zwischengepeichert werden soll
datei="waldbrand.txt"
quelle="https://mlul.brandenburg.de/wgs/wgs_bb.xml"
host="brandenburg.de"
i=0
j=0
k=0
stufe4=0
stufe5=0
wbgs=";GEFAHR"
svx_file="${PFAD}/svx_waldbrand"
LK1="Oberhavel"
LK2="Havelland"

declare -a lk=("Barnim" "Dahme-Spreewald" "Elbe-Elster" \
"Havelland" "Märkisch-Oderland" "Oberhavel" \
"Oberspreewald-Lausitz" "Oder-Spree" "Ostprignitz-Ruppin" \
"Potsdam-Mittelmark" "Prignitz" "Spree-Neiße" \
"Teltow-Fläming" "Uckermark")
declare -a lkS=("BAR" "LDS" "EE " "HVL" "MOL" "OHV" "OSL" "LOS" "OPR" "PM " "PR " "SPN" "TF " "UM ")
declare -a gps=("5242.50N/01334.60E" "5214.91N/01342.53E" "5142.02N/01313.96E" \
"5237.36N/01230.95E" "5233.25N/01405.87E" "5253.64N/01321.71E" \
"5145.10N/01352.28E" "5215.34N/01400.52E" "5302.28N/01252.38E" \
"5212.56N/01229.88E" "5305.76N/01142.79E" "5140.40N/01419.84E" \
"5205.02N/01320.68E" "5311.37N/01332.24E")

# Holen und extrahieren des Textes
if ping -c 1 -w 1 $host > /dev/null; then
  wget -q -O $PFAD/$datei $quelle
else
   echo " $(date +%H:%M:%S): $host nicht erreichbar, breche ab."
   exit 1
fi

# I. Aufbereitung der Ausgabe via TCPIP als FIRE-Object für APRS.fi-Karte
for i in ${lk[@]}; do
  d=$(date +%y%m%d.%H:%M:%S)
  ist_warnstufe=$(cat $PFAD/$datei | grep $i | awk -F'[<">">]' '{print $3}')
  if [ -z "$ist_warnstufe" ];then
      ist_warnstufe=0
  fi

  if [ $ist_warnstufe -gt $soll_warnstufe ]; then
    lk=$(echo $i | sed 's/\ü/ue/g;s/\ä/ae/g;s/\ö/oe/g;s/\Ü/UE/g;s/\Ä/AE/g;s/\ß/ss/g;s/\Ö/OE/g')
    text="Waldbrandgefahrenstufe $ist_warnstufe fuer LK $lk. Quelle: mlul.brandenburg.de"
    var1="$wbgs${lkS[$j]}*111111z${gps[$j]}:"
    /home/svxlink/Scripte/APRS_msg_TCPIP.sh "$var1" "$text"

    k=$((k + 1))

    if [ $ist_warnstufe -eq 4 ]; then
       stufe4=$((stufe4 + 1))
    else
       stufe5=$((stufe5 + 1))
    fi

  fi

j=$((j + 1))

done

echo -e "\n$d: $j Landkreise abgefragt, $k ausgeben. Stufe 4: ${stufe4}, Stufe 5: ${stufe5} \n"
/home/svxlink/Scripte/waldbrand_txl.sh

# II. Aufbereitung der beiden LK für svxlink
svx_LK1="set wbws_${LK1}"
svx_LK2="set wbws_${LK2}"

stufe=$(cat $PFAD/$datei | grep $LK1 | awk -F'[<">">]' '{print $3}')
if [ -z "$stufe" ];then
   stufe=0
fi
echo "$svx_LK1 $stufe" >  $svx_file

stufe=$(cat $PFAD/$datei | grep $LK2 | awk -F'[<">">]' '{print $3}')
if [ -z "$stufe" ];then
   stufe=0
fi
echo "$svx_LK2 $stufe" >>  $svx_file

exit 0
