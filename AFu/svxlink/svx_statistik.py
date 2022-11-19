#!/usr/bin/python3
# -*- coding: utf-8 -*-

rf_log = "/var/log/svxlink"

t_start = 'Logic_Ostlink: Talker start:'
t_stop = 'Logic_Ostlink: Talker stop:'
a_start = 'Logic_DL7ATA: Talker start:'
a_stop = 'Logic_DL7ATA: Talker stop:'

p_call = {}

fobj = open(rf_log)
counter = 0
for packet_str in fobj:
    index = 0
    p_end = 0
    druck = ''
    text = ""
    typ = 0
    counter += 1

    if a_start in packet_str or t_start in packet_str:
        p = packet_str.split(" ")[5]
        # suchen ob vorhanden
        if p in p_call:
            p_call[p] += 1
        else:
            neu = {p:1}
            p_call.update(neu)

    print(str(counter).rstrip(), "\r\b")

fobj.close()
liste = [(val,key) for key,val in p_call.items()]
liste.sort()
for val,key in liste:
    if val > 0:
        proz = "  {0:.0%}".format(float(val)/counter)
        # print(key.ljust(15, ' ').rstrip(), "\t=>", str(val).ljust(5, ' '), proz)
        print(key.rstrip().ljust(20, ' '), "=>", str(val).ljust(5, ' '), proz)
print("\n", counter, " Lines mit ", len(p_call), " Stationen", "\n")
