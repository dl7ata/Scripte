#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# 21.03.2020	Mehrere Meldungen generieren, zB. bei C0RONA
# 19.03.2020	Umlaute wandeln
# 16.10.2019	Fehlerkorrektur (nur Bundesland ausgeben)
#
# Prüfen und ausgeben aktueller MOWAS-Meldungen für $Bundesland
# auf APRS 	08.10.2019	DL7ATA
# Das erzeugte File wird von aprx in der Beacon-section eingelesen:
#<beacon>
#        beaconmode      both
#        cycle-size      9m
#        beacon via WIDE2-1 \
#        srccall DB0TGO-15 \
#        file /tmp/aprs/MOWAS.TXT
#

import json
import requests
import re
import time
from datetime import datetime
import subprocess
from pathlib import Path

melde_region = ["BE", "BB", "BR"]

ident = 'identifier'
sent = 'sent'
ebene1 = 'msgType'
ebene2 = 'info'
ebene3 = 'headline'
ebene31 = 'description'
ebene30 = 'area'
ebene41 = 'areaDesc'
ebene42 = 'geocode'
ebene51 = 'valueName'
url = 'https://warnung.bund.de/bbk.mowas/gefahrendurchsagen.json'

umlaute = {'ö': 'oe', 'ä': 'ae', 'ü': 'ue', 'Ö': 'OE', 'Ä': 'AE',
           'Ü': 'UE', 'ß': 'ss'}

aprs_msg = "/tmp/aprs/MOWAS.TXT"
mowas = 'MOWAS'
dst = 'DL7ATA'
z = 0
m = 0
msg_sammler = ''

def cleanhtml(raw_html):
    cleanr = re.compile('<.*?>')
    cleantext = re.sub(cleanr, ' ', raw_html)
    return cleantext

json_file = requests.get(url)
data = json_file.json()

for i in data[:]:
    ort = data[z][ident]
    von = data[z][sent]
    b_land = ort.split('-')[1]					# Bundesland
    sender = data[z]['sender'].split('-')[2]
    meld_datum = von.split('T')[0]				# Meldungsdatum
    meld_zeit = von[11:19]					# Meldungszeit
    meld_zeit = meld_zeit.split(':')[0] + ":" + meld_zeit.split(':')[1]
    meld_datum = "vom " + \
                 datetime.strptime(meld_datum, '%Y-%m-%d').strftime('%d.%m.%Y')
    Meldung = cleanhtml(data[z][ebene2][0][ebene31])    	# Meldungstext
    headline = data[z][ebene2][0][ebene3]			# Headline

    try:
        area = (data[z][ebene2][0][ebene30][0][ebene41]).split(':')[1]
    except IndexError as e:
        area = " "
        pass

    geo_Code = (data[z][ebene2][0][ebene30][0][ebene42][0][ebene51])
    for char in umlaute:
        geo_Code = geo_Code.replace(char, umlaute[char])

    if b_land in melde_region:
        # Datei für aprx-Bake erstellen
        for char in umlaute:
            headline = headline.replace(char, umlaute[char])

        text = ":BLN0MOWA" +  str(m).strip() + ":" + geo_Code + ": " + headline + " (MOWAS)"
        with open(aprs_msg, 'w+') as output:
            output.write(text)
            output.close()
        print(time.strftime("%H:%M:%S"), ": ", text)
        m += 1
        time.sleep(539)
    z += 1

my_file = Path(aprs_msg)
if my_file.is_file():
    my_file.unlink()
