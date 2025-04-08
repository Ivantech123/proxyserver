#!/bin/bash

PROXIES_FILE="/etc/haproxy/proxies.txt"
TEMP_FILE="/tmp/proxies.tmp"

update_single() {
    local port=$1
    local new_user=$2
    local new_pass=$3
    
    sed -i "s/\(.*:${port}:\)[^:]*:[^:]*/\1${new_user}:${new_pass}/" $PROXIES_FILE
    echo "Updated credentials for port $port"
}

update_bulk() {
    local csv_file=$1
    
    while IFS=, read -r port new_user new_pass; do
        update_single "$port" "$new_user" "$new_pass"
    done < "$csv_file"
}

case "$1" in
    "single")
        if [ $# -ne 4 ]; then
            echo "Usage: $0 single PORT NEW_USERNAME NEW_PASSWORD"
            exit 1
        fi
        update_single "$2" "$3" "$4"
        ;;
    "bulk")
        if [ $# -ne 2 ]; then
            echo "Usage: $0 bulk CSV_FILE"
            echo "CSV format: port,new_username,new_password"
            exit 1
        fi
        update_bulk "$2"
        ;;
    *)
        echo "Usage: $0 {single PORT NEW_USERNAME NEW_PASSWORD|bulk CSV_FILE}"
        exit 1
        ;;
esac

# Verify file integrity
if [ ! -f "$PROXIES_FILE" ]; then
    echo "Error: Proxies file not found!"
    exit 1
fi

echo "Credentials updated successfully"
