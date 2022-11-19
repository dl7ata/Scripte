#!/usr/bin/python3
# -*- coding: utf-8 -*-
# SvxStat_time.py
# Ermittelt für jede im Logfile erscheinende Station die Gesamtsendezeit
# 01.10.2019	DL7ATA

import datetime
import time

rf_log = "/var/log/svxlink"

t_start = 'Logic_Ostlink: Talker start'
t_stop = 'Logic_Ostlink: Talker stop'
a_start = 'Logic_DL7ATA: Talker start'
a_stop = 'Logic_DL7ATA: Talker stop'

p_call = {}
p_time = 0

fobj = open(rf_log, encoding='latin1')
counter = 0

def parsen(packet_str):
    call = packet_str.split(" ")[8].rstrip()
    #print(call, packet_str)
    zeit = packet_str.split(" ")[1]
    time = datetime.datetime.strptime(zeit[:-1], "%H:%M:%S")
    t = sum(x * int(t) for x, t in zip([1, 60, 3600], reversed(zeit[:-1].split(":"))))
    return(call, t)

for packet_str in fobj:
    #packet_str = packet_str.encode('utf-16')
    index = 0
    p_end = 0
    druck = ''
    text = ""
    typ = 0
    counter += 1

    # 17.10.2019 07:40:04
    # 0123456789012345678
    log_Date = packet_str[:10]
    log_Time = packet_str[11:16]

    if a_start in packet_str or t_start in packet_str:
        call1, t1 = parsen(packet_str)

    if a_stop in packet_str or t_stop in packet_str:
        call2, t2 = parsen(packet_str)

        if call2 == call1:
            txd = t2 - t1
            # suchen ob vorhanden
            if call2 in p_call:
                p_call[call2] += txd
            else:
                neu = {call2:txd}
                p_call.update(neu)

            p_time += txd

    print(str(counter).rstrip(), log_Date, log_Time, "\r\b")

fobj.close()

liste = [(val,key) for key,val in p_call.items()]
liste.sort()
for val,key in liste:
    if val > 0:
        proz = "  {0:.0%}".format(float(val)/counter)
        print(key.rstrip().ljust(20, ' '), "=>", str(val).ljust(5, ' '), proz)

print("\n", counter, "Log-Lines mit ", len(p_call), "Stationen. Total", \
      time.strftime('%H:%M:%S', time.gmtime(p_time)), "\n")
