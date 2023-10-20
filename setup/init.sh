#!/bin/bash
# Version 1.6
# Copyright (c) 2023 3nine
# Author: 3nine
# License: MIT
# https://github.com/3nine/pi/main/LICENSE.md

# Setze die Farben für die Ausgabe
GREEN='\e[32m'
BLUE='\e[34m'
CYAN='\e[36m'
YELLOW='\e[33m'
RED='\e[31m'
RESET='\e[0m'

show_help() {
  GREEN='\e[32m'
  BLUE='\e[34m'
  CYAN='\e[36m'
  YELLOW='\e[33m'
  RED='\e[31m'
  RESET='\e[0m'
  
  echo -e "${GREEN}Dieses Skript fürt automatische Updates sowie Konfigurationen durch${RESET}"
  echo -e "${GREEN}Es aktualisiert die Paketquellen, führt ein Paketupgrade durch und bietet die Option, bestimmte Services zu installieren.${RESET}"
  echo -e "${CYAN}Verwendung:${RESET}"
  echo -e "${CYAN}  ./scriptname              - Führt das Skript aus.${RESET}"
  echo -e "${CYAN}  ./scriptname help or ?    - Zeigt diese Hilfe an.${RESET}"
  exit 0
}

check_docker_installed() {
  if dpkg -l | grep -q "docker"; then
    docker_installed=true
  else
    docker_installed=false
  fi
}

check_docker_compose_installed() {
  if dpkg -l | grep -q "docker-compose"; then
    docker_compose_installed=true
  else
    docker_compose_installed=false
  fi
}

install_docker() {
  echo -e "${BLUE}Installiere Docker...${RESET}"
  sudo curl -sSL https://get.docker.com/ | CHANNEL=stable sh > /dev/null 2>&1
  echo -e "${BLUE}Docker wurde installiertt.${RESET}"
}

install_docker_compose() {
  echo -e "${BLUE}Installiere Docker-Compose...${RESET}"
  sudo apt install docker-compose-plugin
  echo -e "${BLUE}Docker-Compose wurde installiert.${RESET}"
}

pause() {
  sleep 2 # 2 Sekunden Pause
}

autoremove() {
  echo -e "${BLUE}Schritt 3: Überprüfe, ob Pakete zum Entfernen verfügbar sind.${RESET}"
  autoremove_output=$(sudo apt-get autoremove -s > /dev/null 2>&1)

  if [[ "$autoremove_output" == *"Die folgenden Pakete werden entfernt"* ]]; then
    echo -e "${BLUE}Schritt 3: Bereinigung wird durchgeführt, um ungenutzte Pakete zu entfernen.${RESET}"
    sudo apt-get autoremove -y > /dev/null 2>&1
    echo -e "${BLUE}Schritt 3: Bereinigung abgeschlossen.${RESET}"
  else
    echo -e "${YELLOW}Keine Pakete zum Entfernen gefunden. Der Schritt 3 wird übersprungen.${RESET}"
  fi
}

# --------> Start <--------

# Prüfe ob Arg1 "?" oder "help" ist
if [ "$1" = "?" ] || [ "$1" = "help" ]; then
  show_help
fi

sudo echo "Um dieses Skript auszuführen, sind Root Berechtigungen nötig."

echo -e "Grundinstallation eines Pi's"
# Führt ein Update der Paketquellen durch
echo "Aktualisiere Paketquellen"
sudo apt update > /dev/null 2>&1
echo -e "${GREEN}Aktualisierung abgeschlossen${RESET}"

# Führt ein Upgrade der Paketquellen durch
echo "Upgrade der installierten Paketquellen"
sudo apt update > /dev/null 2>&1
echo -e "${GREEN}Upgrade abgeschlossen${RESET}"

# Aufruf function autoremove
autoremove

clear
check_dockerinstalled
if $docker_installed; then
  echo -e "${YELLOW}Docker ist bereits installiert, daher wird dieser Schritt übersprungen!${RESET}"
else
  # Abfrage Docker Installation
  dialog --title "Docker Installation" --yesno "Möchten Sie Docker installieren?" 0 0
  response_docker=$?
  case $response_docker in
    0)
      clear
      install_docker ;; # Benutzer möchte Docker installieren

      # Teste ob Docker-Compose mit installiert wurde.
      check_docker_compose_installed
      if $docker_compose_installed; then
        clear
      else
        # Abfrage Docker-Compose Installation
         dialog --title "Docker-Compose Installation" --yesno "Möchten Sie Docker-Compose  installieren?" 0 0
         response_docker_compose=$?
         case $response_docker_compose
           0)
             clear
             install_docker_compose ;; # Docker Compose wurde nicht installiert aber der Benutzer möchte es installieren
           1)
             echo -e "${GREEN}Docker wurde nicht installiert.${RESET}" # Benutzer möchte Docker-Compose nicht installieren
           255)
             echo -e "${RED}Abbruch.${RESET}" ;; # Benutzer hat abbruch gewählt
    1)
      echo -e "${GREEN}Docker wurde nicht installiert.${RESET}" #Benutzer möchte Docker nicht installieren
    255)
      echo -e "${RED}Abbruch.${RESET}" ;; # Benutzer hat abbruch gewählt






















# Autoupdate Abfrage
dialog --title "Autoupdate aktivieren" --yesno "Möchten Sie Autoupdate aktivieren? Wenn ja, werden wöchentliche Updates automatisch Samstags um 00:00 Uhr durchgeführt." 0 0

response=$?
case $response in
  0)
    echo -e "${YELLOW}Autoupdate wird aktiviert.${RESET}"
    sudo mkdir -p /opt/update/
    sudo curl -o /opt/update/update-script.sh https://raw.githubusercontent.com/3nine/pi/auto_update.sh
    sudo chmod +x /opt/update/auto_update.sh
    (crontab -l ; echo "0 0 * * 6 /opt/update/auto_update.sh") | crontab -
    echo -e "${BLUE}Autoupdate aktiviert.${RESET}"
    ;;
  1)
    echo -e "${GREEN}Autoupdate wird nicht aktiviert.${RESET}" ;;
  255)
    echo -e "${YELLOW}Abbruch.${RESET}" ;;
esac

# Benutzerabfrage, ob das System heruntergefahren werden soll
dialog --title "Skript abgeschlossen" --yesno "Das Skript wurde abgeschlossen. Möchten Sie das System neu starten?" 0 0

# Überprüft die Antwort auf die Benutzerabfrage
response_restart=$?
case $response_restart in
  0)
    echo -e "${GREEN}Der Raspberry Pi wird neu gestartet.${RESET}"
    clear
    sudo shutdown now ;; # Benutzer hat "Ja" ausgewählt, das System wird heruntergefahren
  1)
    echo -e "${GREEN}Der Raspberry Pi bleibt eingeschaltet.${RESET}" ;; # Benutzer hat "Nein" ausgewählt, das Skript wird beendet
  255)
    echo -e "${RED}Abbruch.${RESET}" ;; # Benutzer hat Abbruch ausgewählt
esac

#Lösche das Konsolenfenster
clear