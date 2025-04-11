#!/bin/bash

# =======================================
# 🚀 Proxy Server Installer for Linux v1.0
# =======================================
# Automatic installation script for Ubuntu/Debian systems
# This script installs all dependencies and sets up the proxy server

# Check if running on Linux
if [[ "$(uname)" != "Linux" ]]; then
    echo -e "🚫 Error: This script is for Linux systems only!"
    echo -e "📄 For Windows use: .\install-and-run-v2.ps1 (Run as Administrator)"
    echo -e "🔗 See instructions: https://github.com/Ivantech123/proxyserver#-установка"
    exit 1
fi

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "🚫 Error: This script must be run as root!"
    echo -e "📄 Please run: sudo bash install-linux.sh"
    exit 1
fi

# Colors and formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

# ASCII Art Banner
echo -e "${CYAN}"
cat << "EOF"
    ____                      ____                          
   / __ \_________  _  __   / __ \____ _      _____  _____
  / /_/ / ___/ __ \| |/_/  / /_/ / __ \ | /| / / _ \/ ___/
 / ____/ /  / /_/ />  <   / ____/ /_/ / |/ |/ /  __/ /    
/_/   /_/   \____/_/|_|  /_/    \____/|__/|__/\___/_/     
                                                          
              Linux Installer v1.0
EOF
echo -e "${NC}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}🛑 This script must be run as root${NC}"
    echo -e "${YELLOW}👉 Please run: sudo $0${NC}"
    exit 1
fi

# Detect distribution
distro=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro="$ID"
fi

if [ "$distro" != "ubuntu" ] && [ "$distro" != "debian" ]; then
    echo -e "${YELLOW}⚠️ Warning: This script is optimized for Ubuntu/Debian.${NC}"
    echo -e "${YELLOW}⚠️ Your distribution: $distro${NC}"
    echo -e "${YELLOW}⚠️ The script will attempt to continue, but may encounter issues.${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation aborted.${NC}"
        exit 1
    fi
fi

# Function for progress display
show_progress() {
    local current=$1
    local total=$2
    local text="$3"
    local percent=$((current * 100 / total))
    local completed=$((percent / 2))
    local remaining=$((50 - completed))
    
    printf "\r[%${completed}s%${remaining}s] %d%% %s" "$(printf '%0.s#' $(seq 1 $completed))" "" "$percent" "$text"
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# Function for logging
log_message() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "INFO")    echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        "ERROR")   echo -e "${RED}[ERROR]${NC} $message" ;;
        "SUCCESS") echo -e "${CYAN}[SUCCESS]${NC} $message" ;;
        *) echo -e "$message" ;;
    esac
}

# Function to check system requirements
check_system_requirements() {
    log_message "INFO" "Checking system requirements..."
    
    # Check CPU cores
    cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        log_message "WARNING" "Less than 2 CPU cores detected ($cpu_cores cores)"
    else
        log_message "SUCCESS" "CPU: $cpu_cores cores"
    fi
    
    # Check RAM
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 2 ]; then
        log_message "WARNING" "Less than 2GB RAM detected ($total_ram GB)"
    else
        log_message "SUCCESS" "RAM: $total_ram GB"
    fi
    
    # Check disk space
    free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$free_space" -lt 40 ]; then
        log_message "WARNING" "Less than 40GB free space ($free_space GB)"
    else
        log_message "SUCCESS" "Disk space: $free_space GB free"
    fi
    
    # Calculate system score
    cpu_score=$((cpu_cores * 25))
    [ "$cpu_score" -gt 100 ] && cpu_score=100
    
    ram_score=$((total_ram * 25))
    [ "$ram_score" -gt 100 ] && ram_score=100
    
    disk_score=$(echo "$free_space * 2.5" | bc | cut -d. -f1)
    [ "$disk_score" -gt 100 ] && disk_score=100
    
    total_score=$(( (cpu_score + ram_score + disk_score) / 3 ))
    
    echo -e "\n${CYAN}🏆 System Compatibility Score: $total_score/100${NC}"
    
    if [ "$total_score" -ge 80 ]; then
        log_message "SUCCESS" "Your system exceeds the recommended requirements"
    elif [ "$total_score" -ge 60 ]; then
        log_message "INFO" "Your system meets the recommended requirements"
    elif [ "$total_score" -ge 40 ]; then
        log_message "WARNING" "Your system meets the minimum requirements"
    else
        log_message "ERROR" "Your system does not meet the minimum requirements"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_message "ERROR" "Installation aborted."
            exit 1
        fi
    fi
}

# Function to install dependencies
install_dependencies() {
    log_message "INFO" "Updating package lists..."
    apt-get update
    
    # List of required packages
    packages=("docker.io" "docker-compose" "git" "openssl" "curl" "jq")
    total=${#packages[@]}
    current=0
    
    log_message "INFO" "Installing required packages..."
    for pkg in "${packages[@]}"; do
        ((current++))
        show_progress "$current" "$total" "Installing $pkg"
        
        if dpkg -l | grep -q "$pkg"; then
            log_message "SUCCESS" "$pkg is already installed"
        else
            if apt-get install -y "$pkg"; then
                log_message "SUCCESS" "$pkg installed successfully"
            else
                log_message "ERROR" "Failed to install $pkg"
                read -p "Continue anyway? (y/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    log_message "ERROR" "Installation aborted."
                    exit 1
                fi
            fi
        fi
    done
    
    # Check if Docker service is running
    if ! systemctl is-active --quiet docker; then
        log_message "INFO" "Starting Docker service..."
        systemctl start docker
        systemctl enable docker
    fi
    
    # Add current user to docker group if not root
    if [ "$SUDO_USER" != "" ]; then
        log_message "INFO" "Adding user $SUDO_USER to docker group..."
        usermod -aG docker "$SUDO_USER"
        log_message "WARNING" "You may need to log out and back in for docker group changes to take effect"
    fi
}

# Function to clone or update repository
setup_repository() {
    repo_dir="/opt/proxy-server"
    
    if [ -d "$repo_dir/.git" ]; then
        log_message "INFO" "Updating existing repository..."
        cd "$repo_dir"
        git pull
    else
        log_message "INFO" "Cloning repository..."
        mkdir -p "$repo_dir"
        git clone https://github.com/Ivantech123/proxyserver.git "$repo_dir"
        cd "$repo_dir"
    fi
    
    # Set appropriate permissions
    chown -R $([ "$SUDO_USER" != "" ] && echo "$SUDO_USER" || echo "root") "$repo_dir"
}

# Function to generate SSL certificates
generate_ssl_certificates() {
    log_message "INFO" "Generating SSL certificates..."
    
    certs_dir="$repo_dir/certs"
    mkdir -p "$certs_dir"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$certs_dir/server.key" -out "$certs_dir/server.crt" \
        -subj "/C=US/ST=CA/L=San Francisco/O=Security/OU=IT Department/CN=localhost"
    
    # Check if certificates were generated
    if [ -f "$certs_dir/server.key" ] && [ -f "$certs_dir/server.crt" ]; then
        log_message "SUCCESS" "SSL certificates generated successfully"
    else
        log_message "ERROR" "Failed to generate SSL certificates"
        exit 1
    fi
}

# Function to start proxy server
start_proxy_server() {
    log_message "INFO" "Starting proxy server..."
    
    cd "$repo_dir"
    
    # Build and start containers
    if docker-compose up --build -d; then
        log_message "SUCCESS" "Proxy server containers started"
    else
        log_message "ERROR" "Failed to start proxy server containers"
        exit 1
    fi
    
    # Generate initial proxies
    log_message "INFO" "Generating proxies..."
    docker exec proxy-server /usr/local/bin/generate_proxies.sh 1000
    
    # Show status
    log_message "INFO" "Proxy server status:"
    docker ps | grep proxy-server
    
    # Show proxy list
    log_message "INFO" "Available proxies:"
    docker exec proxy-server head -n 5 /etc/haproxy/proxies.txt
    log_message "INFO" "... (and more)"
    
    # Display access information
    ip_address=$(hostname -I | awk '{print $1}')
    log_message "SUCCESS" "Proxy server is now running!"
    echo -e "\n${CYAN}=== Access Information ===${NC}"
    echo -e "${GREEN}Server IP: ${NC}$ip_address"
    echo -e "${GREEN}Proxy List: ${NC}$repo_dir/proxies.txt"
    echo -e "${GREEN}To view all proxies: ${NC}docker exec proxy-server cat /etc/haproxy/proxies.txt"
    echo -e "${GREEN}To stop server: ${NC}cd $repo_dir && docker-compose down"
    echo -e "${GREEN}To restart server: ${NC}cd $repo_dir && docker-compose restart"
}

# Function to create a convenient management script
create_management_script() {
    script_path="/usr/local/bin/proxymanage"
    
    cat > "$script_path" << 'EOL'
#!/bin/bash

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
NC="\033[0m"

PROXY_DIR="/opt/proxy-server"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}🛑 This script must be run as root${NC}"
    echo -e "${YELLOW}👉 Please run: sudo $0${NC}"
    exit 1
fi

# Display menu
show_menu() {
    clear
    echo -e "${CYAN}=== Proxy Server Management ===${NC}"
    echo -e "1. 🟢 Start proxy server"
    echo -e "2. 🔴 Stop proxy server"
    echo -e "3. 🔄 Restart proxy server"
    echo -e "4. 📋 View proxy list"
    echo -e "5. 🔑 Update proxy credentials"
    echo -e "6. 📊 View logs"
    echo -e "7. 🔍 Check server status"
    echo -e "8. 🚪 Exit"
    echo
    read -p "Enter your choice (1-8): " choice
    return $choice
}

# Main loop
while true; do
    show_menu
    choice=$?
    
    case $choice in
        1)
            echo -e "${GREEN}Starting proxy server...${NC}"
            cd "$PROXY_DIR" && docker-compose up -d
            echo -e "${GREEN}Proxy server started${NC}"
            read -p "Press Enter to continue..."
            ;;
        2)
            echo -e "${YELLOW}Stopping proxy server...${NC}"
            cd "$PROXY_DIR" && docker-compose down
            echo -e "${YELLOW}Proxy server stopped${NC}"
            read -p "Press Enter to continue..."
            ;;
        3)
            echo -e "${CYAN}Restarting proxy server...${NC}"
            cd "$PROXY_DIR" && docker-compose restart
            echo -e "${CYAN}Proxy server restarted${NC}"
            read -p "Press Enter to continue..."
            ;;
        4)
            echo -e "${CYAN}Proxy list:${NC}"
            docker exec proxy-server cat /etc/haproxy/proxies.txt | less
            ;;
        5)
            echo -e "${CYAN}Update proxy credentials${NC}"
            read -p "Enter port number: " port
            read -p "Enter new username: " username
            read -p "Enter new password: " password
            docker exec proxy-server /usr/local/bin/update_credentials.sh single "$port" "$username" "$password"
            echo -e "${GREEN}Credentials updated${NC}"
            read -p "Press Enter to continue..."
            ;;
        6)
            echo -e "${CYAN}Viewing logs...${NC}"
            docker exec proxy-server tail -f /var/log/haproxy/access.log
            ;;
        7)
            echo -e "${CYAN}Server status:${NC}"
            docker ps | grep proxy-server
            echo
            echo -e "${CYAN}Resource usage:${NC}"
            docker stats --no-stream proxy-server
            read -p "Press Enter to continue..."
            ;;
        8)
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
done
EOL

    # Make the script executable
    chmod +x "$script_path"
    log_message "SUCCESS" "Management script created: proxymanage"
    log_message "INFO" "You can now manage your proxy server by running: sudo proxymanage"
}

# Main installation process
echo -e "\n${CYAN}=== Proxy Server Installation ===${NC}\n"

# Step 1: Check system requirements
check_system_requirements

# Step 2: Install dependencies
install_dependencies

# Step 3: Setup repository
setup_repository

# Step 4: Generate SSL certificates
generate_ssl_certificates

# Step 5: Start proxy server
start_proxy_server

# Step 6: Create management script
create_management_script

# Display completion message with a joke
jokes=(
    "Why don't scientists trust atoms? Because they make up everything, even proxies!"
    "I told my proxy to be transparent. Now I can't find it!"
    "How many proxy servers does it take to change a lightbulb? None, they're too busy hiding your IP address!"
    "My proxy server went to a masquerade party. Nobody recognized it!"
    "What's a proxy's favorite dance? The IP hop!"
)
random_index=$((RANDOM % ${#jokes[@]}))

echo -e "\n${GREEN}✅ Proxy server installation complete!${NC}"
echo -e "${YELLOW}😄 ${jokes[$random_index]}${NC}\n"
echo -e "${CYAN}To manage your proxy server, run: ${GREEN}sudo proxymanage${NC}\n"
