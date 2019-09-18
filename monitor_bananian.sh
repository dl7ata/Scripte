#!/bin/bash

# OS Übersicht
screenfetch
# WAN und LAN IP
#WANIP4=$(dig +short myip.opendns.com @resolver1.opendns.com)
WANIP6=$(curl -s https://6.ifcfg.me/)
ADDRESS=$(hostname -I | cut -d ' ' -f 1)
echo "CPU Temperatur" 
/usr/sbin/soctemp		#dieser Befehl funktioniert nur mit BANANIAN Linux!
echo "**************************************"
echo "Temperatur Gehäuse"
/usr/sbin/pmutemp		#dieser Befehl funktioniert nur mit BANANIAN Linux!
echo "**************************************"
echo "WAN IPv4: $WANIP4"
echo "-------------------------------------"
echo "LAN IP: $ADDRESS"
echo "-------------------------------------"
date
echo "-------------------------------------"
#echo "htop für Systemmonitor"		#ein paar einfache Textausgaben
#echo "bwm-ng für Traffic Monitor"	#ein paar einfache Textausgaben

# VOLT,AMPERE,WATT ANZEIGE
echo "Strom - Verbrauch"
V0=`cat /sys/devices/platform/sunxi-i2c.0/i2c-0/0-0034/axp20-supplyer.28/power_supply/ac/voltage_now`
V3=`cat /sys/devices/platform/sunxi-i2c.0/i2c-0/0-0034/axp20-supplyer.28/power_supply/ac/current_now`
V1=$V0
V2=$'0.000001'
V4=$'0.000000000001'
echo | gawk '{print '$V1'*'$V2' " Volt " '$V3'*'$V2' " Ampere " '$V3'*'$V1'*'$V4' " Watt "}'
#echo | gawk '{print '$V3'*'$V2' " Ampere "}'
#echo | gawk '{print '$V3'*'$V1'*'$V4' " Watt "}'
echo "-------------------------------------"
exit 0
