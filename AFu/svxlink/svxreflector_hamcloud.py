#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Ausgeben aller angeschlossenen HAMCLOUD-Netlink Tln.
# 12.12.2019	DL7ATA
#
# nodes ['CALL']	= Rufzeichen

import requests
import time
from geopy import distance
from time import strftime

home = (52.1, 13.0)
url = 'http://hamcloud.info:8090/status'
f_rot = '\033[31m'
f_gruen = '\033[32m'
f_gelb = '\033[33m'
f_aus = '\033[0m'

# Start
print("Status Netlink-Berlin/Hamcloud von", strftime("%H:%M:%S"), url, "\n")
while True:
    json_file = requests.get(url)
    data = json_file.json()
    # with open(quelle, 'rb') as json_file:
    #    data = json.load(json_file)
    liste = data['nodes']
    for i in liste:
        call = i
        druck = ''
        if liste[i]['isTalker']:
            druck += f_rot + i.ljust(14, ' ') + f_aus
        else:
            druck += f_gelb + i.ljust(14, ' ') + f_aus
        j = 0
        try:
            druck += liste[i]['qth'][0]['name'].ljust(28, ' ')
            if liste[i]['qth'][0]['pos']['lat']:
                stn = (liste[i]['qth'][0]['pos']['lat'],
                       liste[i]['qth'][0]['pos']['long'])
                # print(type(home), type(stn))
                entfernung = round(distance.distance(home, stn).km, 1)
                druck += " "+ (str(entfernung) + "km").ljust(8, ' ')
        except KeyError as e:
            druck += " /" + f_rot + ".." + str(e) + f_aus
            pass
        druck += "V" + liste[i]['swVer']
        if liste[i]['tg']:
            druck += " / aktive TG:" + str(liste[i]['tg'])
        while j < len(liste[i]['monitoredTGs']):
            druck += " " + f_gruen + str(liste[i]['monitoredTGs'][j]) + f_aus
            j += 1
        print(druck)
    print("\n")
    time.sleep(30)
