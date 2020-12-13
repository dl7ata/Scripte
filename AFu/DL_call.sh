#!/bin/bash
# DL_call.sh
# Suchen nach einem bei der BNetz registrierten Call in einer konvertierten Bnetz-PDF (Call_DL.TXT)
# 12.12.2020	DL7ATA

callbook="Call_DL.txt"
#------
call=$1
call=$(printf "$call" | tr [:lower:]äöü [:upper:]ÄÖÜ)

if [ -z "$call" ];then
  echo "LEER - Syntax: <DL-Call.sh RUFZEICHEN>"
  exit 1
else
  echo -e "$(date +%H:%M:%S): $call"
fi

such_call="${call},"
text_msg=$(grep "${such_call}" ${callbook})

if [ -n "$text_msg" ];then
   echo $text_msg
else
   echo "$call nicht gefunden"
fi

exit 0
