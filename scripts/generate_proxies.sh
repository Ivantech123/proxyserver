#!/bin/bash

# =======================================
# 🚀 Proxy Generator Script v2.0
# =======================================
# Generates multiple proxy entries with unique credentials
# and configures HAProxy accordingly.
# 
# Usage: ./generate_proxies.sh [COUNT] [BASE_PORT]

# Fun ASCII art banner
cat << "EOF"
  _____                      _____                      
 |  __ \                    / ____|                     
 | |__) | __ _____  ___   | |  __  ___ _ __   ___ _ __ 
 |  ___/ '__/ _ \ \/ / | | | | |_ |/ _ \ '_ \ / _ \ '__|
 | |   | | | (_) >  <| |_| | |__| |  __/ | | |  __/ |   
 |_|   |_|  \___/_/\_\\__, |\_____|\___|_| |_|\___|_|   
                       __/ |                           
                      |___/                            
EOF

# Default values with parameter validation
COUNT=${1:-1000}
BASE_PORT=${2:-3128}
OUTPUT_FILE="/etc/haproxy/proxies.txt"
CONFIG_FILE="/etc/haproxy/haproxy.cfg"

# Validate inputs
if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -lt 1 ]; then
    echo "⚠️  Error: COUNT must be a positive integer" >&2
    exit 1
fi

if ! [[ "$BASE_PORT" =~ ^[0-9]+$ ]] || [ "$BASE_PORT" -lt 1024 ] || [ "$BASE_PORT" -gt 65535 ]; then
    echo "⚠️  Error: BASE_PORT must be between 1024 and 65535" >&2
    exit 1
fi

# Check if we'll exceed port range
if [ $((BASE_PORT + COUNT - 1)) -gt 65535 ]; then
    echo "⚠️  Warning: Port range would exceed maximum (65535). Adjusting count..." >&2
    COUNT=$((65535 - BASE_PORT + 1))
    echo "ℹ️  Adjusted proxy count to $COUNT" >&2
fi

# Function to generate random string (optimized)
generate_random() {
    local length=${1:-8}
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result=""
    
    # Use /dev/urandom if available, otherwise use built-in RANDOM
    if [ -e /dev/urandom ]; then
        result=$(head -c 100 /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c "$length")
    else
        for i in $(seq 1 "$length"); do
            result="$result${chars:$((RANDOM % ${#chars})):1}"
        done
    fi
    
    echo "$result"
}

# Start time for performance measurement
start_time=$(date +%s)

# Clear existing proxies file
echo "🧹 Clearing existing proxy configuration..."
> "$OUTPUT_FILE"

# Create temporary file for batch processing
TMP_CONFIG=$(mktemp)

# Generate proxy entries in batches
echo "🔧 Generating $COUNT proxies starting from port $BASE_PORT..."

# Progress bar setup
total=$COUNT
pct=0
prev_pct=0

for i in $(seq 1 "$COUNT"); do
    # Calculate progress percentage
    pct=$((i * 100 / total))
    if [ "$pct" -ne "$prev_pct" ] && [ $((pct % 10)) -eq 0 ]; then
        prev_pct=$pct
        printf "\r[%-50s] %d%%" "$(printf '%0.s#' $(seq 1 $((pct / 2))))" "$pct"
    fi

    PORT=$((BASE_PORT + i - 1))
    USERNAME=$(generate_random 8)
    PASSWORD=$(generate_random 12)
    
    # Add to proxies.txt
    echo "${HOSTNAME}:${PORT}:${USERNAME}:${PASSWORD}" >> "$OUTPUT_FILE"
    
    # Add backend server to temp config
    echo "    server proxy${i} 127.0.0.1:${PORT} check" >> "$TMP_CONFIG"
done

# Complete progress bar
printf "\r[%-50s] %d%%\n" "$(printf '%0.s#' $(seq 1 50))" 100

# Apply changes to HAProxy config in one operation
echo "📝 Updating HAProxy configuration..."
sed -i "/backend proxy_backend/r $TMP_CONFIG" "$CONFIG_FILE"

# Clean up temp file
rm -f "$TMP_CONFIG"

# Reload HAProxy configuration
echo "🔄 Reloading HAProxy configuration..."
if haproxy -c -f "$CONFIG_FILE"; then
    systemctl reload haproxy
    echo "✅ HAProxy configuration reloaded successfully!"
else
    echo "❌ HAProxy configuration validation failed. Changes not applied."
    exit 1
fi

# Calculate execution time
end_time=$(date +%s)
execution_time=$((end_time - start_time))

# Display fun completion message
echo "🎉 Success! Generated $COUNT proxies in ${execution_time}s"
echo "📁 Configuration saved to $OUTPUT_FILE"

# Add a random joke
jokes=(
    "Why don't scientists trust atoms? Because they make up everything, even proxies!"
    "I told my proxy to be transparent. Now I can't find it!"
    "How many proxy servers does it take to change a lightbulb? None, they're too busy hiding your IP address!"
    "My proxy server went to a masquerade party. Nobody recognized it!"
    "What's a proxy's favorite dance? The IP hop!"
)
random_index=$((RANDOM % ${#jokes[@]}))
echo "\n😄 ${jokes[$random_index]}"

