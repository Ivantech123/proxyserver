#!/bin/bash

# Default values
COUNT=${1:-1000}
BASE_PORT=${2:-3128}
OUTPUT_FILE="/etc/haproxy/proxies.txt"
CONFIG_FILE="/etc/haproxy/haproxy.cfg"

# Function to generate random string
generate_random() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-8} | head -n 1
}

# Clear existing proxies file
> $OUTPUT_FILE

# Generate proxy entries
for i in $(seq 1 $COUNT); do
    PORT=$((BASE_PORT + i - 1))
    USERNAME=$(generate_random 8)
    PASSWORD=$(generate_random 12)
    
    # Add to proxies.txt
    echo "${HOSTNAME}:${PORT}:${USERNAME}:${PASSWORD}" >> $OUTPUT_FILE
    
    # Add backend server to HAProxy config
    if [ $i -eq 1 ]; then
        sed -i "/backend proxy_backend/a\    server proxy${i} 127.0.0.1:${PORT} check" $CONFIG_FILE
    else
        sed -i "/server proxy$((i-1))/a\    server proxy${i} 127.0.0.1:${PORT} check" $CONFIG_FILE
    fi
done

# Reload HAProxy configuration
haproxy -c -f $CONFIG_FILE && systemctl reload haproxy

echo "Generated $COUNT proxies. Configuration saved to $OUTPUT_FILE"
