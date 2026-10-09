#!/bin/bash

#praguri pentru alerte
CPU_ALERT_THRESHOLD=80
MEMORY_ALERT_THRESHOLD=80
DISK_ALERT_THRESHOLD=90
NETWORK_ALERT_THRESHOLD=50 # KB/s, ajustat pentru a fi mai realist pentru testare

# fișier de log
LOG_FILE="/var/log/system_health_check.log"

#logam evenimentele
log_event() {
local message=$1
# Verifică dacă directorul logului există și are permisiuni de scriere
if [ ! -d "$(dirname "$LOG_FILE")" ]; then
echo "Error: Directory for log file does not exist."
exit 1
fi
echo "$(date) - $message" >> "$LOG_FILE"

#daca directorul nu exista, functia va afisa eroarea si va opri programul
}

# afisam si logam alertele
display_alert() {
local message=$1
echo -e "\033[31m$message\033[0m" # Mesajul de alertă afișat în roșu
log_event "$message"
}


check_cpu_usage() {
local cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
local cpu_usage=$(echo "100 - $cpu_idle" | bc) # Calculează utilizarea CPU cu bc

#aici se obtine utilizarea inactiva a cpu lui cu comanda top si se calculeaza utilizarea
echo "CPU Usage: $cpu_usage%"

# compar pragul utilizând bc pentru valori zecimale
if (( $(echo "$cpu_usage > $CPU_ALERT_THRESHOLD" | bc -l) )); then
local message="Alert! CPU usage is above threshold: $cpu_usage%"
display_alert "$message"
fi
}


check_memory_usage() {
local memory_used=$(free -b | awk '/Mem/ {print $3}')
local memory_total=$(free -b | awk '/Mem/ {print $2}')

#folosim metoda free pentru a obtine memoria utilizata si totala in bytes

# verific dacă valorile sunt valide
if [ -z "$memory_used" ] || [ -z "$memory_total" ] || [ "$memory_total" -eq 0 ]; then
echo "Error: Unable to retrieve valid memory data."
return
fi

# calculez procentajul utilizării memoriei folosind bc
local memory_usage=$(echo "scale=2; $memory_used / $memory_total * 100" | bc)

echo "Memory Usage: $memory_usage%"

# bc este un fel de package care te ajuta sa calculezi valori zecimale

# compar utilizarea memoriei cu pragul folosind bc
if (( $(echo "$memory_usage > $MEMORY_ALERT_THRESHOLD" | bc -l) )); then
local message="Alert! Memory usage is above threshold: $memory_usage%"
display_alert "$message"
fi
}




check_disk_usage() {
local disk_usage=$(df -h | grep '^/dev' | awk '{print $5}' | sed 's/%//')
echo "Disk Usage: $disk_usage%"

#obtinem utilizarea discului cu df si se extrage procentajul utilizarii discului

if [ "$disk_usage" -gt "$DISK_ALERT_THRESHOLD" ]; then
local message="Alert! Disk usage is above threshold: $disk_usage%"
display_alert "$message"
fi
}

# monitorizam activitatea rețelei folosind ifstat

check_network_activity() {
local network_interface=$(ip route | grep default | awk '{print $5}' | head -n 1)

#aici se detecteaza interfata de retea activa cu comanda ip route

#interfata de retea se refera la un dispozitiv cu care sistemul se conecteaza la o retea locala(LAN)
# sau globala(WAN). asa comunica sistemul cu alte servicii

#la rularea programului la network de exemplu apare eth0 si este interfata pt internet conexiune prin cablu

# verific dacă interfața de rețea este validă
if [ -z "$network_interface" ]; then
echo "No active network interface found."
return
fi

local network_activity=$(ifstat -i "$network_interface" 1 1 | tail -n 1 | awk '{print $1}')

# ifstat este comanda pt obtinere a activitatii retelei si se converteste in kb/s

# verific dacă valoarea obținută este validă
if [ -z "$network_activity" ] || [[ ! "$network_activity" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
echo "Network activity: No valid data or activity is zero."
return
fi

# facem conversie activitatii în KB/s
local network_activity_kb=$(echo "scale=2; $network_activity / 1024" | bc)

echo "Network Activity on $network_interface: $network_activity_kb KB/s"

# compar activitatea rețelei cu pragul
if (( $(echo "$network_activity_kb > $NETWORK_ALERT_THRESHOLD" | bc -l) )); then
local message="Alert! Network activity is above threshold on $network_interface: $network_activity_kb KB/s"
display_alert "$message"
fi
}


show_menu() {
echo "========================================="
echo " Health Check Menu"
echo "========================================="
echo "1) CPU Usage"
echo "2) Memory Usage"
echo "3) Disk Usage"
echo "4) Active Processes"
echo "5) Network Activity"
echo "6) Check Health with Alerts"
echo "7) View Logs"
echo "8) Exit"
echo "========================================="
}

read_choice() {
read -p "Enter your choice: " choice
case $choice in
1)
check_cpu_usage
;;
2)
check_memory_usage
;;
3)
check_disk_usage
;;
4)
active_processes
;;
5)
check_network_activity
;;
6)
check_cpu_usage
check_memory_usage
check_disk_usage
check_network_activity
;;
7)
view_logs
;;
8)
echo "Exiting. Goodbye!"
exit 0
;;
*)
echo "Invalid choice, please try again."
;;
esac
}

view_logs() {
if [ -f "$LOG_FILE" ]; then
cat "$LOG_FILE"
else
echo "No logs found."
fi
}


active_processes() {
echo "Active Processes:"
ps aux --sort=-%cpu | head -n 10

#afisam primele 10 procese care ruleaza cel mult cpu
}

# un loop pentru a menține meniul activ in permanenta pana la ctrl+z sau optiunea "8"
while true; do
show_menu
read_choice
echo ""
done

==========================

chmod +x health_check.sh
./health_check.sh
