#!/usr/bin/python3
# -*- coding: utf-8 -*-
# APRS_msg_tx.py
# Senden einer APRS-Msg via TCPIP
# 01.03.2019 V1.0 DL7ATA
#
# Aufruf mit: <./APRS_msg_tx.py EMPFÄNGER-CALL "NACHRICHT">
# ACK wird automat. ergänzt
#
import sys
import aprslib
import random
from time import strftime

meinemsgid = "DL7ATA"
passwd="xxxxx"

# Senden
def senden(call,msg):
    # if len(call) < 6:
    #    call = call + " "*(6 - len(call)) # pad with spaces

    # ZIEL-CALL mit 9 Stellen indizieren und durch Zielcall ersetzten
    zielcall = [" "," "," "," "," "," "," "," "," "]
    for i in range(0,len(call)):
        zielcall[i] = str(call[i])

    # Zusammensetzen der MSg
    ackNo = random.randrange(1,999)
    beacon_ack_buff =  ":" + ''.join(zielcall) + ":" + msg + " {" + str(ackNo)
    command = meinemsgid + ">APR7TA,TCPIP:" + beacon_ack_buff #+ "\""
    AIS = aprslib.IS(meinemsgid, passwd, port=14580)
    AIS.connect()
    # senden ack-message
    AIS.sendall(command)
    print("Msg -> " + command + "\nan " + call + " um " + strftime("%H:%M:%S") +  " gesendet.")
    return

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(len(sys.argv), "Argumente. \nAufruf mit: <./APRS_msg_tx.py EMPFÄNGER-CALL 'NACHRICHT'> - ohne lfd. Nummer! .\n Script will be terminated.")
    else:
        call = sys.argv[1].upper()
        msg = sys.argv[2]
        senden(call, msg)
