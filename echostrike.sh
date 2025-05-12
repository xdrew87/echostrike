#!/bin/bash

APP_NAME="EchoStrike"
AUTHOR="@xlsuixideix"
LOG_FILE="$HOME/echostrike_$(date +%Y%m%d_%H%M%S).log"

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
MAGENTA="\e[35m"
RESET="\e[0m"

# Banner
print_banner() {
  clear
  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗"
  echo -e "║${CYAN}   ███████╗███████╗ ██████╗ ██╗   ██╗███████╗██████╗     ${MAGENTA}║"
  echo -e "║${CYAN}   ██╔════╝██╔════╝██╔═══██╗██║   ██║██╔════╝██╔══██╗    ${MAGENTA}║"
  echo -e "║${CYAN}   ███████╗█████╗  ██║   ██║██║   ██║█████╗  ██████╔╝    ${MAGENTA}║"
  echo -e "║${CYAN}   ╚════██║██╔══╝  ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗    ${MAGENTA}║"
  echo -e "║${CYAN}   ███████║███████╗╚██████╔╝ ╚████╔╝ ███████╗██║  ██║    ${MAGENTA}║"
  echo -e "║${CYAN}   ╚══════╝╚══════╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝    ${MAGENTA}║"
  echo -e "║${CYAN}   $APP_NAME by $AUTHOR                                       ${MAGENTA}║"
  echo -e "╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo
}

# Prompt for targets
read_targets() {
  echo -ne "${CYAN}Enter IPs/hosts (space-separated): ${RESET}"
  read -ra TARGETS
}

# Protocol selection
choose_protocol() {
  echo -e "\n${CYAN}Select Protocol:${RESET}"
  echo "1) TCP (custom port)"
  echo "2) UDP (ports 53, 80, 6672)"
  read -rp "Choice [1-2]: " choice
  case $choice in
    1)
      PROTOCOL="TCP"
      read -rp "Enter TCP port to scan: " PORT
      ;;
    2)
      PROTOCOL="UDP"
      PORTS=(53 80 6672)
      ;;
    *)
      choose_protocol
      ;;
  esac
}

# Log result
log_result() {
  echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

# Connection tests
test_tcp() {
  timeout 1 bash -c "</dev/tcp/$1/$2" &>/dev/null
}

test_udp() {
  timeout 1 bash -c "</dev/udp/$1/$2" &>/dev/null
}

# Main loop
scan_loop() {
  while true; do
    print_banner
    for ip in "${TARGETS[@]}"; do
      if [[ "$PROTOCOL" == "TCP" ]]; then
        test_tcp "$ip" "$PORT"
        if [[ $? -eq 0 ]]; then
          latency=$(ping -c 1 "$ip" | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)
          ms=${latency%.*}
          [[ $ms -le 100 ]] && tag="LOW" && color=$GREEN
          [[ $ms -gt 100 && $ms -le 200 ]] && tag="MED" && color=$YELLOW
          [[ $ms -gt 200 ]] && tag="HIGH" && color=$RED
          echo -e "✅ [$(date '+%H:%M:%S')] ${CYAN}$ip:$PORT${RESET} | $latency ms [$color$tag${RESET}]"
          log_result "SUCCESS $ip:$PORT - $latency ms [$tag]"
        else
          echo -e "❌ [$(date '+%H:%M:%S')] ${CYAN}$ip:$PORT${RESET} | ${RED}Timeout${RESET}"
          log_result "FAIL $ip:$PORT"
        fi
      else
        for udp_port in "${PORTS[@]}"; do
          test_udp "$ip" "$udp_port"
          if [[ $? -eq 0 ]]; then
            latency=$(ping -c 1 "$ip" | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)
            ms=${latency%.*}
            [[ $ms -le 100 ]] && tag="LOW" && color=$GREEN
            [[ $ms -gt 100 && $ms -le 200 ]] && tag="MED" && color=$YELLOW
            [[ $ms -gt 200 ]] && tag="HIGH" && color=$RED
            echo -e "✅ [$(date '+%H:%M:%S')] ${CYAN}$ip:$udp_port${RESET} | $latency ms [$color$tag${RESET}]"
            log_result "SUCCESS $ip:$udp_port - $latency ms [$tag]"
          else
            echo -e "❌ [$(date '+%H:%M:%S')] ${CYAN}$ip:$udp_port${RESET} | ${RED}Timeout${RESET}"
            log_result "FAIL $ip:$udp_port"
          fi
        done
      fi
    done
    sleep 1
  done
}

# Run
print_banner
read_targets
choose_protocol
scan_loop
