#!/bin/bash
# wettwarn.sh	Wetterwarnung aus RSS-Feed extrahieren
# geht nur über den Umweg einer Datei wegen LF
msg=/tmp/rss
quelle="https://wettwarn.de/rss/bxx.rss"
wget -q -O $msg $quelle
cat $msg | sed 's/<[^>]\+>/ /g' | sed -n '2,3p' | sed 's/\([\ä\ö\ü\Ä\Ü\Ö]\)/\&\1uml\;/g;y/\ä\ö\ü\Ä\Ö\Ü/aouAOU/;s/\ß/\&szlig\;/g' > /tmp/AVH_wettwarn.txt

rm $msg
exit 0
