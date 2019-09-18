#!/bin/bash
# AVH_up.sh
# Grafiken hochladen ins--Hamnet mit ftp (ehem. wput)
# __________________________________________________________________
#
# 02.07.2019	killall ftp eingefügt
# 12.06.2019	Zurück zum ftp
# 10.05.2019	Einfügen Abfrage zur vollen Stunde
# V 2.0		23.12.2018
#
nach1="/public_html/"
nach2="/public_html/html/"
pfad=/tmp/Bilder
host='44.225.36.10'
USER='DL7ATA'
PASSWD='FtpDL7ATA'
pstring=${USER}:${PASSWD}
ppstring=${pstring}@${host}
declare -i scr_start
scr_start=$(date +%s)

if ping -c 1 -w 1 $host > /dev/null; then
  killall ftp
  sleep 3
  echo "ping auf $host erfolgreich, kopiere ...."

  # Zu jeder vollen Stunde alle Dateien kopieren - sonst nur weniger
  if [ `date +%M` == '00' ] || [ -n "$1" ]; then
  echo "... alle Dateien ..."
  ln -sf /tmp/sunset.txt /tmp/Bilder/
  wget -q -O $pfad/tsc_webcam.jpg http://www.tegeler-segel-club.de/webcam/tsc_webcam.jpg
  wget -q -O $pfad/avh_webcam.jpg http://44.225.36.14/snapshot.cgi?chan=0
  tail -20 /var/www/html/elconnects.txt > $pfad/tmp_svxlink.log
  HOST=$host
  USER='DL7ATA'
  PASSWD='FtpDL7ATA'
  cd $pfad
  ftp -n $HOST << EOT
  user $USER $PASSWD
  binary
  prompt
  lcd $pfad
  cd /public_html/html
  mput sunset.txt
  mput pv_version
  mput tmp_svxlink.log
  cd /public_html
  mput *.png
  mput tsc_webcam.jpg
  mput avh_webcam.jpg
  cd /HamCam
  mput avh_webcam.jpg
EOT

 else
  echo "... nur graph05.png und svx.log ..."
  HOST=$host
  USER='DL7ATA'
  PASSWD='FtpDL7ATA'
  cd $pfad
  ftp -n $HOST << EOT
  user $USER $PASSWD
  binary
  prompt
  lcd $pfad
  cd /public_html
  mput pv_graph05.png
  cd /public_html/html
  mput tmp_svxlink.log
EOT
 fi

  echo "$(date -R) Übertragung fertig"

else

  echo "$host nicht erreichbar"

fi

scr_end=$(date +%s)
z=$((scr_end - $scr_start))
echo -e "\n Upload fertig  in $((z % 3600 /60)) min, $((z % 60)) s"

exit 0
