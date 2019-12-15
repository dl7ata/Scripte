#!/bin/bash
# svxreflector_status.sh	Auslesen JSON-Strings von svxreflector-Server
# 14.12.2019	DL7ATA
# Voraussetzung:
# Deb-Paket "jq" muss installiert sein (apt-get install jq)

declare -a nodes=("http://194.59.205.218:8090/status" "http://hamcloud.info:8090/status")

function print_table()
{
  format="%-14s | %8s | %4s | %s\n"
  echo "$(date +%d.%m.%y-%H:%M:%S): $url"
  printf "${format}${NC}" "Callsign" "TG#" "Ver" "Monitored TGs"
  echo "------------------------------------------------------------------------"

  status=$(curl -s $url)
  local -a nodes=($(echo "$status" | jq -r '.nodes | keys | .[]'))
  for node in "${nodes[@]}"; do
    proto_ver=$(echo "$status" | jq -r ".nodes[\"$node\"].protoVer | \"\(.majorVer).\(.minorVer)\"")
    local -i tg=$(echo "$status" | jq -r ".nodes[\"$node\"].tg")
    is_talker=$(echo "$status" | jq -r ".nodes[\"$node\"].isTalker")
    local -a monitored_tgs=($(echo "$status" | jq ".nodes[\"$node\"].monitoredTGs[]"))
    printf "${format}${NC}" "$node" "$tg" "$proto_ver" "${monitored_tgs[*]}"
  done
}

for url in "${nodes[@]}"
 do
 print_table
 echo -e "\n"
done

