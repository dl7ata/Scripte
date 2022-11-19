#!/bin/bash -e
# svx_lastheard.sh	Chronologische Ausgabe der letzten gehörten Stationen im Verbund
# 19.01.2020	DL7ATA
#

ein="/tmp/svx_lastheard.out"
log='/var/log/svxlink'
declare -A myarray

declare -i scr_start
scr_start=$(date +%s)

# Extrakt in Datei
echo " Load file into array."
cat $log | grep 'Talker stop on TG #' > $ein

while IFS= read -r line_data; do
    call=$(echo $line_data | cut -d" " -f9)		# Call
    zeit_raw=$(echo $line_data | cut -c 12-19)		# Uhrzeit
    zeit_Stempel=$(date -d $zeit_raw +%s)
    myarray["${call}"]="${zeit_Stempel}"
done < $ein

for i in ${!myarray[@]}
do
  last_time=$(date -d @${myarray["$i"]} +'%H:%M:%S')
  echo -e $i ' - ' "\t" $last_time
done |
sort -rn -k3

rm $ein

scr_end=$(date +%s)
z=$((scr_end - $scr_start))
echo -e "\nfertig  in $((z % 3600 /60)) min, $((z % 60)) s"

exit
