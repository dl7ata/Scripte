#!/bin/bash
# qsotime_gestern - Script zur tgl. Berechnung der Sendezeit und TX-Stromverbrauch
# by DL7ATA
#
# Version vom 01.05.2022
# V 1.0	Juli 2018
#
# Das Script ist zur Auswertung von 2 Logiken ausgelegt
#
#------indiv. Anpassung -------------------------------
# Ausgabedatei für Auswertung
file_prefix="/home/svxlink/SvxSystem/svx-log/svx_qsotime"
file=${file_prefix}.log
# Logdatei
datei="/var/log/svxlink"

# Schlüsselbegriffe aus dem Log
tx1="70cmTx: Turning the transmitter"
tx2="2mTx: Turning the transmitter"
rx1="70cmRx: The squelch is"
rx2="2mRx: The squelch is"
#-----------------------------------------------------
d=$(date +%y%m%d.%H%M%S)
gestern=$(date -d "yesterday" '+%d.%m.%Y')
zeitOFF=""
zeitON=""
zeitOPEN=""
zeitCLOSE=""
let z1=0
let z2=0
let z3=0
let z4=0
beginn=$(head -n1 $datei | cut -c1-19)
ende=$(tail -n1 $datei | cut -c1-19)

IFS=$'\n'
grep "$tx1\|$tx2\|$rx1\|$rx2" "$datei" | { while read variable
do
   #prüfen Tx1 (70cm)
   if [[ "$variable" == *"$tx1"* ]] ; then
   	if [[ "$variable" == *"ON"* ]]; then
	   zeitON=$(echo $variable | cut -c12-19)
	# echo "$variable / $zeitON"
	   #in UNIX umwandeln
	   zeiton=`date --utc --date "$zeitON" +%s`

   	else

	 #prüfen ob Log mit TX off beginnt - dann fehlt erster TX on und $zeitON
	 if [[ "$zeitON" != "" ]]; then
	    zeitOFF=$(echo $variable | cut -c12-19)
	    #in UNIX umwandeln
	    zeitoff=`date --utc --date "$zeitOFF" +%s`
	    tt1=$(echo $(($zeitoff-$zeiton)))
	    z1=$(($z1+$tt1))
	#echo "$variable / $zeitOFF / $z1"
	 fi

       fi
   fi

   # prüfen RX1 (70cm)
   if [[ "$variable" == *"$rx1"* ]]; then
   	if [[ "$variable" == *"OPEN"* ]]; then
	   zeitOPEN=$(echo $variable | cut -c12-19)
	#echo "$variable / $zeitOPEN"
	   #in UNIX umwandeln
	   zeitopen=`date --utc --date "$zeitOPEN" +%s`
	else

	 #prüfen ob Log mit RX OPEN beginnt - dann fehlt erster RX on und $zeitOPEN
	 if [[ "$zeitOPEN" != "" ]]; then
	    zeitCLOSE=$(echo $variable | cut -c12-19)
	    #in UNIX umwandeln
	    zeitclose=`date --utc --date "$zeitCLOSE" +%s`
	    tt3=$(echo $(($zeitclose-$zeitopen)))
	    z3=$(($z3+$tt3))
	    #echo "$variable / $zeitCLOSE / $z3"
	 fi
       fi
    fi

 # prüfen Tx2 (2m)
   if [[ "$variable" == *"$tx2"* ]] && [[ "$zeitOFF" != "" ]]; then
   	if [[ "$variable" == *"ON"* ]]; then
	   zeitON=$(echo $variable | cut -c12-19)
	   #in UNIX umwandeln
	   zeiton=`date --utc --date "$zeitON" +%s`

	else

	   if [[ "$zeitON" != "" ]]; then
	      zeitOFF=$(echo $variable | cut -c12-19)
	      #in UNIX umwandeln
  	      zeitoff=`date --utc --date "$zeitOFF" +%s`
	      tt2=$(echo $(($zeitoff-$zeiton)))
	      z2=$(($z2+$tt2))
	      #echo "$variable / $zeitOFF / $z2"
	   fi
        fi
   fi

   # prüfen RX2 (2m)
   if [[ "$variable" == *"$rx2"* ]]; then
   	if [[ "$variable" == *"OPEN"* ]]; then
	   zeitOPEN=$(echo $variable | cut -c12-19)
	#echo "$variable / $zeitOPEN"
	   #in UNIX umwandeln
	   zeitopen=`date --utc --date "$zeitOPEN" +%s`
	else

	 #prüfen ob Log mit RX OPEN beginnt - dann fehlt erster RX on und $zeitOPEN
	 if [[ "$zeitOPEN" != "" ]]; then
	    zeitCLOSE=$(echo $variable | cut -c12-19)
	    #in UNIX umwandeln
	    zeitclose=`date --utc --date "$zeitCLOSE" +%s`
	    tt4=$(echo $(($zeitclose-$zeitopen)))
	    z4=$(($z4+$tt4))
	    #echo "$variable / $zeitCLOSE / $z4"
	 fi
       fi
    fi
done

# Leistungsaufnahme berechnen
# 70cm: 29W, 2m: 21W
kwh=$(echo "100*$z1 /3600 * 2.1 * 12.6/100" | bc)Wh
kwh1=$(echo "100*$z2 /3600 * 1.6 * 12.6/100" | bc)Wh

# Stunden formatieren
count=0
for i in "$z1" "$z2" "$z3" "$z4"; do
  #if [ $i -gt 3600 ];then
     std[$count]=$(printf '%02d' "$(("$i" / 3600))"):
  #fi
  count=$count+1
done

# Minuten formatieren
count=0
for i in "$z1" "$z2" "$z3" "$z4"; do
  #if [ $i -gt 60 ];then
     min[$count]=$(printf '%02d' "$(("$i" % 3600 /60))"):
  #fi
  count=$count+1
done

# Sekunden formatieren
count=0
for i in "$z1" "$z2" "$z3" "$z4"; do
  sek[$count]=$(printf '%02d' "$(("$i" % 60))")
  count=$count+1
done

text="Log von $beginn bis $ende / TX 70cm: ${std[0]}${min[0]}${sek[0]}s (${kwh})/ 2m: ${std[1]}${min[1]}${sek[1]}s (${kwh1})| \
Rx 70cm: ${std[2]}${min[2]}${sek[2]}s / 2m: ${std[3]}${min[3]}${sek[3]}s"

echo -e $text >> $file

}

exit 0
