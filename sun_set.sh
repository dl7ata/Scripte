#!/bin/bash
# Ermittlung von Sonnenauf- und Untergang
# Geklaut im IN
# Aufruf per Cron tgl. um 3°°h, erstellen einer Textdatei
#
# 24.2.2018 DL7ATA
#
#--------- persönliche Anpassungen ---------------------#
# Meine Position
posLaenge="13.2322"
posBreite="52.5696"
# Auf- und Untergang speichern in:
Sun="/tmp/sunset.txt"
#------------ENDE---------------------------------------#
#
# Notwendige Vorberechnungen
zoneinfo=$(date +%z) # Zeitzone
T=`date +%j` # Tag im Jahr
pi="3.14159265358979323844" # pi=`echo "4*a(1)" | bc -l`
rad=$(echo "${pi}/180" | bc -l)
h=$(echo "-(5/6)*(${rad})" | bc -l) # Höhe des Sonnenmittelpunkts bei Aufgang: Radius+Refraktion
BreiteRAD=$(echo "${posBreite}*${rad}" | bc -l)

# Welcher Tag ist heute?
#echo "Heute ist $(date +%d.%m.%y), der $(date +%j). Tag im Jahr"
#echo -n "Wir nutzen die Zeitzone $(date +%Z), dies entspricht $(date +%z) und damit "
#echo "${zoneinfo:0:3}"

sonnendekl=`echo "0.409526325277017*s(0.0169060504029192*(${T}-80.0856919827619))" | bc -l`
sonnendeklDEG=$(echo "${sonnendekl} / ${rad}" | bc -l)

arccosint=$(echo "(s(${h})-s(${BreiteRAD})*s(${sonnendekl}))/(c(${BreiteRAD})*c(${sonnendekl}))" | bc -l)
arccosintsign=${arccosint:0:1}
if [ ${arccosintsign} == "-" ]; then
  usesign="+"
else
  usesign="-"
fi
arc2cosint=$(echo "(${arccosint}) * (${arccosint})" | bc -l)
acoszeit=$(echo "${pi}/2 ${usesign} a(sqrt(${arc2cosint} / (1 - (${arc2cosint}) ) ) ) " | bc -l)

zeitdiff=$(echo "12*${acoszeit}/${pi}" | bc -l) # KORREKT!

zeitgleich=$(echo "-0.170869921174742*s(0.0336997028793971 * ${T} + 0.465419984181394) - 0.129890681040717*s(0.0178674832556871*${T} - 0.167936777524864)" | bc -l)
aufgang=$(echo "12-(${zeitdiff})-(${zeitgleich})-(${posLaenge}/15)${zoneinfo:0:3}" | bc -l)
untergang=$(echo "12+(${zeitdiff})-(${zeitgleich})-(${posLaenge}/15)${zoneinfo:0:3}" | bc -l)

if [ ${aufgang:1:1} == "." ]; then
  # Ist ein einstelliges Ergebnis der Form x.xxxx, wir brauchen noch eine 0 vorne
  aufgang=$(echo 0${aufgang})
fi
# Fuer unsere Breitengrade ueberfluessig, nur der Vollstaendigkeit halber:
#if [ ${untergang:1:1} == "." ]; then
# Ist ein einstelliges Ergebnis der Form x.xxxx, wir brauchen noch eine 0 vorne
#  untergang=$(echo 0${untergang})
#fi

# Umrechnung in Stunden (trivial) und Minuten (runden!)
AufgangMinute=$(echo "(${aufgang} - ${aufgang:0:2}) * 60" | bc | xargs printf "%02.0f\n")
if [ ${AufgangMinute} == "60" ]; then
  AufgangMinute="00"
  AufgangStunde=$(echo "${aufgang:0:2} + 1" | bc | xargs printf "%02.0f")
else
  AufgangStunde=${aufgang:0:2}
fi

UntergangMinute=$(echo "(${untergang} - ${untergang:0:2}) * 60" | bc | xargs printf "%02.0f\n")
if [ ${UntergangMinute} == "60" ]; then
  UntergangMinute="00"
  UntergangStunde=$(echo "${untergang:0:2} + 1" | bc | xargs printf "%02.0f")
else
  UntergangStunde=${untergang:0:2}
fi

up="${AufgangStunde}:${AufgangMinute}"
down="${UntergangStunde}:${UntergangMinute}"

# Ermittlung der hellen Tageszeit in h und m
d=$(date +%D)
z1=$(( $(date -d "$d $down" +%s)  - $(date -d "$d $up" +%s) ))
h=$((z1 /3600))
m=$((z1 % 3600 /60))

echo "$up $down $h:$(printf '%02d' "$m")" > $Sun
#echo "$up $down $((z1 /3600)):$((z1 % 3600 /60))" > $Sun

exit 0
