#!/bin/bash
# mondphase.sh
# Erzeugt numerischen Wert; 1.500.000 = Vollmond. Auswertung via svxlink/ticktimer
# V 1.0	 DL7ATA

datei="/tmp/mondphase.txt"

moonphase(){
  local lp=2551443
  local now=$(date -u +"%s")
  local newmoon=592500
  local phase=$((($now - $newmoon) % $lp))
  local phase_number=$((((phase / 86400) + 1)*100000))

  # Multiply by 100000 so we can do integer comparison.  Go Bash!

  if   [ $phase_number -lt 184566 ];  then phase_icon="○"  # new
  elif [ $phase_number -lt 553699 ];  then phase_icon="❩"  # waxing crescent
  elif [ $phase_number -lt 922831 ];  then phase_icon="◗"  # first quarter
  elif [ $phase_number -lt 1291963 ];  then phase_icon="◑"  # first quarter
  elif [ $phase_number -lt 1661096 ]; then phase_icon="●"  # full
  elif [ $phase_number -lt 2030228 ]; then phase_icon="◐"  # waning gibbous
  elif [ $phase_number -lt 2399361 ]; then phase_icon="◖"  # last quarter
  elif [ $phase_number -lt 2768493 ]; then phase_icon="❨"  # waning crescent
  else
    phase_icon="○"  # new
  fi
  echo "set mond $phase_number" > $datei
}

moonphase
