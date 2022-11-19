#!/bin/bash
# svxreflector_status.sh	Auslesen JSON-Strings von svxreflector-Server
# 14.12.2019	DL7ATA
# Voraussetzung:
# Deb-Paket "jq" muss installiert sein (apt-get install jq)

url="http://master1.thueringen.link:8090/status"

function print_table()
{
  format="%-14s | %8s | %4s | %18s | %18s | %s\n"
  echo "$(date +%d.%m.%y-%H:%M:%S): $url"
  printf "${format}${NC}" "Callsign" "act. TG#" "Ver" "location"  "name" "Monitored TGs"
  echo "-------------------------------------------------------------------------------------------------------------------"

  status=$(curl -s $url)
  local -a nodes=($(echo "$status" | jq -r '.nodes | keys | .[]'))
  for node in "${nodes[@]}"; do
    proto_ver=$(echo "$status" | jq -r ".nodes[\"$node\"].swVer")
    local -i tg=$(echo "$status" | jq -r ".nodes[\"$node\"].tg")
    is_talker=$(echo "$status" | jq -r ".nodes[\"$node\"].isTalker")
    local -a monitored_tgs=($(echo "$status" | jq ".nodes[\"$node\"].monitoredTGs[]"))
    local -a location=$(echo "$status" | jq -er ".nodes[\"$node\"]?.nodeLocation")
    local -a name=$(echo "$status" | jq -er ".nodes[\"$node\"].qth[]?.name")
    printf "${format}${NC}" "$node" "$tg" "$proto_ver" "$location" "$name" "${monitored_tgs[*]}"
  done
}

print_table
