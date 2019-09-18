#!/bin/bash
# Erzeugen Tabelle für php
# Aufruf durch graph_num.sh
# 28.06.2019	DL7ATA

lfd_tag=$(date +%y%j)
PFAD="/home/svxlink/PV/Ertrag/PV-Ausgabe_${lfd_tag}.txt"
echo "Ertrag letzte ...."
var=$(sed -n '1p' $PFAD | cut -d" " -f7); printf "4 Wochen   %'6.f Wh\n" $var
var=$(sed -n '2p' $PFAD | cut -d" " -f7); printf "Woche      %'6.f Wh\n" $var
var=$(sed -n '3p' $PFAD | cut -d" " -f7); printf "24 Stunden %'6.f Wh\n" $var
echo "Stand: $(date +%d.%m.%Y-%H:%M:%S)"

exit 0
