#!/bin/bash

# =======================================
# 🔑 Proxy Credentials Manager v2.0
# =======================================
# Updates proxy credentials for single or multiple ports
# 
# Usage: ./update_credentials.sh single PORT NEW_USERNAME NEW_PASSWORD
#        ./update_credentials.sh bulk CSV_FILE

# Fun ASCII art banner
cat << "EOF"
  _____               _            _   _       _     
 |  __ \             | |          | | (_)     | |    
 | |__) | __ _____  _| |_   _     | |  _ _ __ | |___ 
 |  ___/ '__/ _ \ \/ / | | |    | | | | '_ \| / __|
 | |   | | | (_) >  <| |_| |    | | | | | | | \__ \
 |_|   |_|  \___/_/\_\\__, |    |_| |_|_| |_|_|___/
                       __/ |                        
                      |___/                         
EOF

# Configuration
PROXIES_FILE="/etc/haproxy/proxies.txt"
TEMP_FILE="/tmp/proxies.tmp"
LOG_FILE="/var/log/proxy_credentials.log"

# Colors and formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Terminal output with color
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "SUCCESS") echo -e "${CYAN}[SUCCESS]${NC} $message" ;;
        *) echo -e "$message" ;;
    esac
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local text="$3"
    local percent=$((current * 100 / total))
    local completed=$((percent / 2))
    local remaining=$((50 - completed))
    
    printf "\r[%${completed}s%${remaining}s] %d%% %s" "" "" "$percent" "$text"
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# Enhanced single credential update
update_single() {
    local port=$1
    local new_user=$2
    local new_pass=$3
    
    # Validate port number
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
        log_message "ERROR" "Invalid port number: $port (must be between 1024-65535)"
        return 1
    fi
    
    # Check if port exists in the file
    if ! grep -q ":${port}:" "$PROXIES_FILE"; then
        log_message "ERROR" "Port $port not found in proxy list"
        return 1
    fi
    
    # Backup original file
    cp "$PROXIES_FILE" "${PROXIES_FILE}.bak"
    
    # Update credentials
    if sed -i "s/\(.*:${port}:\)[^:]*:[^:]*/\1${new_user}:${new_pass}/" "$PROXIES_FILE"; then
        log_message "SUCCESS" "Updated credentials for port $port"
        return 0
    else
        log_message "ERROR" "Failed to update credentials for port $port"
        # Restore backup on failure
        cp "${PROXIES_FILE}.bak" "$PROXIES_FILE"
        return 1
    fi
}

# Enhanced bulk credential update
update_bulk() {
    local csv_file=$1
    local total_lines=$(wc -l < "$csv_file")
    local current_line=0
    local success_count=0
    local failure_count=0
    
    log_message "INFO" "Starting bulk update from $csv_file ($total_lines entries)"
    
    # Validate CSV format first
    while IFS=, read -r port new_user new_pass; do
        if ! [[ "$port" =~ ^[0-9]+$ ]]; then
            log_message "ERROR" "Invalid CSV format. Line contains invalid port: $port"
            return 1
        fi
    done < "$csv_file"
    
    # Process updates
    while IFS=, read -r port new_user new_pass; do
        ((current_line++))
        show_progress "$current_line" "$total_lines" "Updating port $port"
        
        if update_single "$port" "$new_user" "$new_pass"; then
            ((success_count++))
        else
            ((failure_count++))
        fi
    done < "$csv_file"
    
    # Summary
    log_message "INFO" "Bulk update completed: $success_count successful, $failure_count failed"
}

# Verify file integrity before starting
if [ ! -f "$PROXIES_FILE" ]; then
    log_message "ERROR" "Proxies file not found at $PROXIES_FILE!"
    exit 1
fi

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Process command arguments
case "$1" in
    "single")
        if [ $# -ne 4 ]; then
            log_message "ERROR" "Usage: $0 single PORT NEW_USERNAME NEW_PASSWORD"
            exit 1
        fi
        log_message "INFO" "Updating credentials for port $2"
        if update_single "$2" "$3" "$4"; then
            log_message "SUCCESS" "Credentials updated successfully"
        else
            log_message "ERROR" "Failed to update credentials"
            exit 1
        fi
        ;;
    "bulk")
        if [ $# -ne 2 ]; then
            log_message "ERROR" "Usage: $0 bulk CSV_FILE"
            log_message "INFO" "CSV format: port,new_username,new_password"
            exit 1
        fi
        
        if [ ! -f "$2" ]; then
            log_message "ERROR" "CSV file not found: $2"
            exit 1
        fi
        
        update_bulk "$2"
        ;;
    *)
        log_message "ERROR" "Usage: $0 {single PORT NEW_USERNAME NEW_PASSWORD|bulk CSV_FILE}"
        exit 1
        ;;
esac

# Add a random joke
jokes=(
    "Why don't hackers use weak passwords? They prefer to crack their own jokes!"
    "I changed my password to 'incorrect'. So when I forget it, the computer will tell me 'Your password is incorrect'."
    "My password is the last 8 digits of pi. Good luck with that!"
    "Why did the password go to therapy? It had too many personal issues."
    "What's a hacker's favorite season? Phishing season!"
)
random_index=$((RANDOM % ${#jokes[@]}))
echo -e "
${YELLOW}😄 ${jokes[$random_index]}${NC}"
