#!/bin/bash
# Konfugartion in den PK232 via  ttyUSB0 laden
#

# Schnittstelle konfigurieren und öffnen
#
datum=$(date +%y%m%d_%H:%M:%S)
echo "Los geht's ... $datum"
datum=$(date +%y%m%d%H%M%S)

stty -F /dev/ttyUSB0 9600
exec 5>/dev/ttyUSB0
sleep 2

echo -en "daytime $datum \r\n" >&5
echo "Setze Datum: $datum"
sleep 2
echo -en "myc dl7ata \r\n" >&5
echo -en "expert on \r\n" >&5
echo -en "pac \r\n" >&5
echo -en "M 0 \r\n" >&5
echo -en "txd 22 \r\n" >&5
echo -en "daystamp on \r\n" >&5
echo -en "mstamp on \r\n" >&5
echo -en "constamp on \r\n" >&5
echo -en "un BAKE via DB0AVH 3 \r\n" >&5
echo -en "bt JO62ON | 430.025MHz FM | DL7ATA-8 MBX | APRS | Echolink #41041 | Freunde alter Betriebstechniken  \r\n" >&5
echo -en "ct Moinsen, hier ist kein Terminal dran. \v Bitte Nachricht auf DL7ATA-8 hinterlassen, tnx & 73 \r\n" >&5
echo -en "cmsg on \r\n" >&5
echo -en "MTE Mailbox von DL 7 ATA on >> \v H  fuer  Hilfe...  \r\n" >&5
echo -en "MM on \r\n" >&5
echo -en "be every 90 \r\n" >&5
echo -en "3RDPARTY on \r\n" >&5
echo -en "MYMAIL DL7ATA-8 \r\n" >&5
echo -en "MAILDROP on \r\n" >&5
echo -en "mdmon on \r\n" >&5
echo -en "chsw $C7E \r\n" >&5
echo -en "chcall on \r\n" >&5
echo "Schliesse Kanal 5"

datum=$(date +%y%m%d_%H:%M:%S)
# Kanal  schliessen
exec 5>&-
echo "Fertich ...    $datum"

exit 0
