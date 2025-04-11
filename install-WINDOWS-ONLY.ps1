# Proxy Server Installation and Setup Script v2.0
# Must be run as Administrator

<#
.SYNOPSIS
    Advanced proxy server installation and management script.
.DESCRIPTION
    This script provides a comprehensive solution for installing, configuring,
    and managing a high-performance proxy server using Docker containers.
.NOTES
    Version: 2.0
    Author: Ivantech123
    Last Updated: 2025-04-09
#>

# Set error handling
$ErrorActionPreference = "Stop"

# ASCII Art Banner
function Show-Banner {
    $bannerColor = Get-Random -Min 1 -Max 16
    $banner = @"
    ____                      ____                          
   / __ \_________  _  __   / __ \____ _      _____  _____
  / /_/ / ___/ __ \| |/_/  / /_/ / __ \ | /| / / _ \/ ___/
 / ____/ /  / /_/ />  <   / ____/ /_/ / |/ |/ /  __/ /    
/_/   /_/   \____/_/|_|  /_/    \____/|__/|__/\___/_/     
                                                          
                v2.0 - Optimized Edition
"@

    Write-Host $banner -ForegroundColor ([ConsoleColor]$bannerColor)
    Write-Host "" # Empty line after banner
}

# Check if running on Windows
if ($PSVersionTable.PSEdition -eq 'Desktop' -or ($PSVersionTable.Platform -and $PSVersionTable.Platform -eq 'Win32NT') -or ($PSVersionTable.PSVersion.Major -ge 6 -and $env:OS -like '*Windows*')) {
    # Running on Windows, check for admin rights
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if (-not $isAdmin) {
            Write-Host "⛔ Error: This script must be run as Administrator" -ForegroundColor Red
            Write-Host "🔑 Please right-click on PowerShell and select 'Run as Administrator'" -ForegroundColor Red
            pause
            exit 1
        }
    } catch {
        # If we get here, something went wrong with the Windows-specific check
        Write-Host "⛔ Error: Failed to check administrator privileges" -ForegroundColor Red
        exit 1
    }
} else {
    # Not running on Windows
    Write-Host "[ERR] Ошибка: Этот скрипт предназначен только для Windows!" -ForegroundColor Red
    Write-Host "[INFO] Для Linux используйте: sudo bash install-LINUX-ONLY.sh" -ForegroundColor Yellow
    Write-Host "[-->] Подробная инструкция: https://github.com/Ivantech123/proxyserver#-установка" -ForegroundColor Cyan
    exit 1
}

# Function for progress display with improved visuals
function Show-Progress {
    param(
        [string]$Activity,
        [int]$PercentComplete,
        [string]$Status
    )
    
    # Add emoji based on activity type
    $emoji = switch -Wildcard ($Activity) {
        "*System*"      { "[SYS]" }
        "*Dependency*"  { "[DEP]" }
        "*Install*"     { "[INS]" }
        "*Docker*"      { "[DOC]" }
        "*Git*"         { "[GIT]" }
        "*SSL*"         { "[SSL]" }
        "*Server*"      { "[SRV]" }
        "*Credential*" { "[KEY]" }
        default         { "[CFG]" }
    }
    
    Write-Progress -Activity "$emoji $Activity" -PercentComplete $PercentComplete -Status $Status
}

# Function for status output with improved visuals
function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $emoji = switch ($Type) {
        "Info"    { "[INFO]" }
        "Warning" { "[WARN]" }
        "Error"   { "[ERR]" }
        "Success" { "[OK]" }
        default   { "[-->]" }
    }
    
    Write-Host "$emoji $Message" -ForegroundColor $(switch ($Type) {
        "Info"    { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        "Success" { "Cyan" }
        default   { "White" }
    })
}

# Enhanced system detection
function Get-SystemInfo {
    $systemInfo = @{}
    
    # Get OS information
    $os = Get-CimInstance Win32_OperatingSystem
    $systemInfo.OSName = $os.Caption
    $systemInfo.OSVersion = $os.Version
    $systemInfo.OSArchitecture = $os.OSArchitecture
    
    # Get CPU information
    $processor = Get-CimInstance Win32_Processor | Select-Object -First 1
    $systemInfo.CPUName = $processor.Name
    $systemInfo.CPUCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
    $systemInfo.CPUSpeed = "$([math]::Round($processor.MaxClockSpeed / 1000, 2)) GHz"
    
    # Get RAM information
    $systemInfo.TotalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    
    # Get disk information
    $disk = Get-PSDrive C
    $systemInfo.TotalDiskSpace = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
    $systemInfo.FreeDiskSpace = [math]::Round($disk.Free / 1GB, 2)
    
    # Get network information
    $systemInfo.IPAddresses = @(Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -ExpandProperty IPAddress)
    
    return $systemInfo
}

# Enhanced system requirements check
function Test-SystemRequirements {
    Write-Status "Checking system requirements..." "Info"
    Show-Progress -Activity "System Check" -PercentComplete 0 -Status "Gathering system information..."
    
    $systemInfo = Get-SystemInfo
    
    # Display system information
    Write-Host ""
    Write-Host "📊 System Information:" -ForegroundColor Cyan
    Write-Host "  🖥️ OS: $($systemInfo.OSName) ($($systemInfo.OSVersion))" -ForegroundColor White
    Write-Host "  💻 CPU: $($systemInfo.CPUName)" -ForegroundColor White
    Write-Host "  🧠 RAM: $($systemInfo.TotalRAM) GB" -ForegroundColor White
    Write-Host "  💾 Disk: $($systemInfo.FreeDiskSpace) GB free of $($systemInfo.TotalDiskSpace) GB" -ForegroundColor White
    Write-Host "  🌐 IP: $($systemInfo.IPAddresses -join ', ')" -ForegroundColor White
    Write-Host ""
    
    Show-Progress -Activity "System Check" -PercentComplete 25 -Status "Checking CPU..."
    
    # Check CPU cores
    if ($systemInfo.CPUCores -lt 2) {
        Write-Status "Warning: Less than 2 CPU cores ($($systemInfo.CPUCores) cores)" "Warning"
    } else {
        Write-Status "CPU cores: $($systemInfo.CPUCores) - Sufficient" "Success"
    }
    
    Show-Progress -Activity "System Check" -PercentComplete 50 -Status "Checking RAM..."
    
    # Check RAM
    if ($systemInfo.TotalRAM -lt 2) {
        Write-Status "Warning: Less than 2GB RAM ($($systemInfo.TotalRAM) GB)" "Warning"
    } else {
        Write-Status "RAM: $($systemInfo.TotalRAM) GB - Sufficient" "Success"
    }
    
    Show-Progress -Activity "System Check" -PercentComplete 75 -Status "Checking disk space..."
    
    # Check disk space
    if ($systemInfo.FreeDiskSpace -lt 40) {
        Write-Status "Warning: Less than 40GB free space ($($systemInfo.FreeDiskSpace) GB)" "Warning"
    } else {
        Write-Status "Free disk space: $($systemInfo.FreeDiskSpace) GB - Sufficient" "Success"
    }
    
    Show-Progress -Activity "System Check" -PercentComplete 100 -Status "Complete"
    Start-Sleep -Seconds 1
    
    # Return system compatibility score (0-100)
    $cpuScore = [Math]::Min(100, $systemInfo.CPUCores * 25)
    $ramScore = [Math]::Min(100, $systemInfo.TotalRAM * 25)
    $diskScore = [Math]::Min(100, $systemInfo.FreeDiskSpace * 2.5)
    
    $totalScore = [Math]::Round(($cpuScore + $ramScore + $diskScore) / 3)
    
    Write-Host ""
    Write-Host "🏆 System Compatibility Score: $totalScore/100" -ForegroundColor Cyan
    
    if ($totalScore -ge 80) {
        Write-Status "Your system exceeds the recommended requirements" "Success"
    } elseif ($totalScore -ge 60) {
        Write-Status "Your system meets the recommended requirements" "Info"
    } elseif ($totalScore -ge 40) {
        Write-Status "Your system meets the minimum requirements" "Warning"
    } else {
        Write-Status "Your system does not meet the minimum requirements" "Error"
    }
}

# Enhanced dependency check
function Test-Dependencies {
    Write-Status "Checking required software..." "Info"
    $deps = @{
        "Docker" = @{ 
            Check = { Get-Command docker -ErrorAction SilentlyContinue };
            Version = { (docker version --format '{{.Server.Version}}') };
            MinVersion = "20.10.0"
        };
        "Git" = @{ 
            Check = { Get-Command git -ErrorAction SilentlyContinue };
            Version = { (git --version).Replace('git version ', '') };
            MinVersion = "2.30.0"
        };
        "OpenSSL" = @{ 
            Check = { Get-Command openssl -ErrorAction SilentlyContinue };
            Version = { (openssl version).Split(' ')[1] };
            MinVersion = "1.1.1"
        }
    }
    
    $i = 0
    $missing = @()
    $outdated = @()
    
    foreach ($dep in $deps.GetEnumerator()) {
        $i++
        $percent = ($i / $deps.Count) * 100
        Show-Progress -Activity "Checking Dependencies" -PercentComplete $percent -Status "Checking $($dep.Key)..."
        
        if (-not (& $dep.Value.Check)) {
            $missing += $dep.Key
            Write-Status "$($dep.Key) is not installed" "Warning"
        } else {
            try {
                $version = & $dep.Value.Version
                Write-Status "$($dep.Key) is installed (version: $version)" "Success"
                
                # Version comparison logic could be added here
                # This is a simplified check
                if ($version -lt $dep.Value.MinVersion) {
                    $outdated += "$($dep.Key) (current: $version, required: $($dep.Value.MinVersion))"
                    Write-Status "$($dep.Key) version is outdated" "Warning"
                }
            } catch {
                Write-Status "$($dep.Key) is installed (version unknown)" "Info"
            }
        }
    }
    
    if ($missing.Count -eq 0 -and $outdated.Count -eq 0) {
        Write-Status "All dependencies are installed and up to date" "Success"
    } else {
        if ($missing.Count -gt 0) {
            Write-Status "Missing dependencies: $($missing -join ', ')" "Warning"
        }
        if ($outdated.Count -gt 0) {
            Write-Status "Outdated dependencies: $($outdated -join ', ')" "Warning"
        }
    }
    
    return $missing
}

# Enhanced dependency installation
function Install-Dependencies {
    param($MissingDeps)
    
    if ($null -eq $MissingDeps -or $MissingDeps.Count -eq 0) {
        Write-Status "No dependencies to install" "Info"
        return
    }
    
    Write-Status "Installing missing dependencies: $($MissingDeps -join ', ')" "Info"
    
    $total = $MissingDeps.Count
    $current = 0
    $installationResults = @()
    
    foreach ($dep in $MissingDeps) {
        $current++
        $percent = ($current / $total) * 100
        Show-Progress -Activity "Installing Dependencies" -PercentComplete $percent -Status "Installing $dep..."
        
        try {
            switch ($dep) {
                "Docker" {
                    Write-Status "Installing Docker..." "Info"
                    # Download Docker Desktop Installer
                    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
                    $installerPath = "$env:TEMP\DockerInstaller.exe"
                    
                    Show-Progress -Activity "Installing Docker" -PercentComplete 25 -Status "Downloading installer..."
                    Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath
                    
                    Show-Progress -Activity "Installing Docker" -PercentComplete 50 -Status "Installing..."
                    # Install Docker Desktop
                    Start-Process -Wait -FilePath $installerPath -ArgumentList "install --quiet"
                    
                    Show-Progress -Activity "Installing Docker" -PercentComplete 75 -Status "Cleaning up..."
                    # Clean up
                    Remove-Item $installerPath -ErrorAction SilentlyContinue
                    
                    Show-Progress -Activity "Installing Docker" -PercentComplete 100 -Status "Verifying..."
                    # Verify installation
                    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
                        throw "Docker installation failed. Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop"
                    }
                    $installationResults += "Docker: ✅ Successfully installed"
                }
                "Git" {
                    Write-Status "Installing Git..." "Info"
                    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
                        Write-Status "Installing Chocolatey..." "Info"
                        Set-ExecutionPolicy Bypass -Scope Process -Force
                        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
                        
                        # Refresh environment variables
                        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                    }
                    Show-Progress -Activity "Installing Git" -PercentComplete 50 -Status "Installing via Chocolatey..."
                    choco install git -y --force
                    $installationResults += "Git: ✅ Successfully installed"
                }
                "OpenSSL" {
                    Write-Status "Installing OpenSSL..." "Info"
                    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
                        Write-Status "Installing Chocolatey..." "Info"
                        Set-ExecutionPolicy Bypass -Scope Process -Force
                        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
                        
                        # Refresh environment variables
                        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                    }
                    Show-Progress -Activity "Installing OpenSSL" -PercentComplete 50 -Status "Installing via Chocolatey..."
                    choco install openssl -y --force
                    $installationResults += "OpenSSL: ✅ Successfully installed"
                }
            }
        }
        catch {
            Write-Status "Failed to install ${dep}: $($_.Exception.Message)" "Error"
            Write-Status "Please try installing ${dep} manually" "Info"
            $installationResults += "${dep}: ❌ Installation failed: $($_.Exception.Message)"
        }
    }
    
    # Display installation summary
    Write-Host ""
    Write-Host "📋 Installation Summary:" -ForegroundColor Cyan
    foreach ($result in $installationResults) {
        Write-Host "  $result" -ForegroundColor White
    }
}

# Enhanced Git initialization
function Initialize-Git {
    Write-Status "Initializing Git repository..." "Info"
    
    Show-Progress -Activity "Git Initialization" -PercentComplete 0 -Status "Checking repository..."
    
    if (!(Test-Path ".git")) {
        Show-Progress -Activity "Git Initialization" -PercentComplete 25 -Status "Creating repository..."
        git init
        
        Show-Progress -Activity "Git Initialization" -PercentComplete 50 -Status "Adding files..."
        git add .
        
        Show-Progress -Activity "Git Initialization" -PercentComplete 75 -Status "Creating initial commit..."
        git commit -m "Initial commit: proxy server setup"
        
        Show-Progress -Activity "Git Initialization" -PercentComplete 100 -Status "Complete"
        Write-Status "Git repository initialized" "Success"
    } else {
        Show-Progress -Activity "Git Initialization" -PercentComplete 100 -Status "Repository exists"
        Write-Status "Git repository already exists" "Warning"
    }
}

# Enhanced SSL certificate generation
function New-SSLCertificate {
    Write-Status "Generating SSL certificates..." "Info"
    
    Show-Progress -Activity "SSL Certificate Generation" -PercentComplete 0 -Status "Creating directory..."
    
    if (!(Test-Path "certs")) {
        New-Item -ItemType Directory -Path "certs"
    }
    
    Show-Progress -Activity "SSL Certificate Generation" -PercentComplete 25 -Status "Generating certificate..."
    
    try {
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
            -keyout certs/server.key -out certs/server.crt `
            -subj "/C=US/ST=CA/L=San Francisco/O=Security/OU=IT Department/CN=localhost"
        
        Show-Progress -Activity "SSL Certificate Generation" -PercentComplete 75 -Status "Verifying certificates..."
        
        # Check if certificates were generated
        if (!(Test-Path "certs/server.key") -or !(Test-Path "certs/server.crt")) {
            throw "Failed to generate SSL certificates"
        }
        
        Show-Progress -Activity "SSL Certificate Generation" -PercentComplete 100 -Status "Complete"
        Write-Status "SSL certificates generated successfully" "Success"
    }
    catch {
        Write-Status "Failed to generate SSL certificates: $_" "Error"
        throw
    }
}

# Enhanced proxy server startup
function Start-ProxyServer {
    Write-Status "Starting proxy server and web interface..." "Info"
    
    Show-Progress -Activity "Server Startup" -PercentComplete 0 -Status "Building containers..."
    
    # Build and start containers (both proxy server and web interface)
    docker-compose up --build -d
    
    Show-Progress -Activity "Server Startup" -PercentComplete 40 -Status "Generating proxies..."
    
    # Generate initial proxies
    Write-Status "Generating proxies..." "Info"
    docker exec proxy-server /usr/local/bin/generate_proxies.sh 1000
    
    Show-Progress -Activity "Server Startup" -PercentComplete 60 -Status "Checking status..."
    
    # Show status
    Write-Status "Checking proxy server status..." "Info"
    docker ps
    
    Show-Progress -Activity "Server Startup" -PercentComplete 80 -Status "Starting web interface..."
    
    # Open web interface in browser
    Start-WebInterface
    
    Show-Progress -Activity "Server Startup" -PercentComplete 100 -Status "Complete"
    
    # Show proxy list
    Write-Status "Available proxies:" "Info"
    docker exec proxy-server cat /etc/haproxy/proxies.txt
    
    # Display fun message
    $messages = @(
        "Your proxies are ready to rock and roll! 🎸",
        "Proxy server deployed! Time to surf the web incognito. 🕵️",
        "Proxies deployed successfully! You're now a digital ninja. 🥷",
        "Proxy server is up and running faster than a caffeinated cheetah! ☕🐆",
        "Success! Your proxies are now hiding like ninjas in the digital shadows. 🥷"
    )
    $randomMessage = Get-Random -InputObject $messages
    Write-Host ""
    Write-Host $randomMessage -ForegroundColor Cyan
}

# Function to start and open web interface
function Start-WebInterface {
    Write-Status "Starting web interface..." "Info"
    
    # Get the local IP address for the web interface
    $ipAddress = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1).IPAddress
    if (-not $ipAddress) {
        $ipAddress = "localhost"
    }
    
    # Check if web interface is running
    $webStatus = docker inspect --format='{{.State.Running}}' proxy-web-ui 2>$null
    if ($webStatus -ne "true") {
        Write-Status "Web interface container is not running. Starting it now..." "Warning"
        docker-compose up -d web-ui
        Start-Sleep -Seconds 5 # Give it time to start
    }
    
    # Open the web interface in the default browser
    Write-Status "Opening web interface in browser: http://${ipAddress}:8080" "Success"
    Start-Process "http://${ipAddress}:8080"
}

# Enhanced menu with ASCII art
function Show-Menu {
    Clear-Host
    Show-Banner
    
    Write-Host "=== 🚀 Proxy Server Management ===" -ForegroundColor Cyan
    Write-Host "1. 🖥️  Check system and dependencies"
    Write-Host "2. 📦  Install missing components"
    Write-Host "3. 📂  Initialize Git repository"
    Write-Host "4. 🚀  Install and start proxy server with web interface"
    Write-Host "5. 🛑  Stop proxy server"
    Write-Host "6. 📋  View proxy list"
    Write-Host "7. 🔑  Update proxy credentials"
    Write-Host "8. 📊  View logs"
    Write-Host "9. 🔄  Restart proxy server"
    Write-Host "10. 🌐  Open web interface"
    Write-Host "11. 🚪 Exit"
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-11)"
    return $choice
}

# Enhanced credential update
function Update-ProxyCredentials {
    Show-Progress -Activity "Updating Credentials" -PercentComplete 0 -Status "Entering data..."
    
    $port = Read-Host "Enter port number"
    $username = Read-Host "Enter new username"
    $password = Read-Host "Enter new password"
    
    Show-Progress -Activity "Updating Credentials" -PercentComplete 50 -Status "Updating..."
    
    docker exec proxy-server /usr/local/bin/update_credentials.sh single $port $username $password
    
    Show-Progress -Activity "Updating Credentials" -PercentComplete 100 -Status "Complete"
    Write-Status "Credentials updated successfully" "Success"
}

# Main script with enhanced error handling
try {
    $missingDeps = $null
    
    while ($true) {
        $choice = Show-Menu
        
        switch ($choice) {
            "1" {
                Test-SystemRequirements
                $missingDeps = Test-Dependencies
                pause
            }
            "2" {
                if ($null -eq $missingDeps) {
                    Write-Status "Please check system requirements first (Option 1)" "Warning"
                } else {
                    Install-Dependencies $missingDeps
                }
                pause
            }
            "3" {
                Initialize-Git
                pause
            }
            "4" {
                New-SSLCertificate
                Start-ProxyServer
                Write-Status "Installation complete! Web interface is now available." "Success"
                pause
            }
            "5" {
                Show-Progress -Activity "Server Management" -PercentComplete 50 -Status "Stopping server..."
                docker-compose down
                Show-Progress -Activity "Server Management" -PercentComplete 100 -Status "Server stopped"
                Write-Status "Proxy server and web interface stopped successfully" "Success"
                pause
            }
            "6" {
                Write-Status "Current proxy list:" "Info"
                docker exec proxy-server cat /etc/haproxy/proxies.txt
                pause
            }
            "7" {
                Update-ProxyCredentials
                pause
            }
            "8" {
                Write-Status "Recent logs:" "Info"
                docker exec proxy-server tail -f /var/log/haproxy/access.log
                pause
            }
            "9" {
                Show-Progress -Activity "Server Management" -PercentComplete 50 -Status "Restarting server..."
                docker-compose restart
                Show-Progress -Activity "Server Management" -PercentComplete 100 -Status "Server restarted"
                Write-Status "Proxy server restarted successfully" "Success"
                pause
            }
            "10" {
                Start-WebInterface
                Write-Status "Web interface opened in browser" "Success"
                pause
            }
            "11" {
                Write-Status "Exiting..." "Info"
                exit
            }
            default {
                Write-Status "Invalid choice. Please try again." "Error"
                pause
            }
        }
    }
}
catch {
    Write-Status "An error occurred: $_" "Error"
    Write-Status "Stack trace: $($_.ScriptStackTrace)" "Error"
    
    # Provide helpful recovery suggestions
    Write-Host ""
    Write-Host "🔧 Troubleshooting Suggestions:" -ForegroundColor Cyan
    Write-Host "  1. Make sure you're running as Administrator" -ForegroundColor White
    Write-Host "  2. Check if Docker Desktop is running" -ForegroundColor White
    Write-Host "  3. Verify network connectivity" -ForegroundColor White
    Write-Host "  4. Try restarting your computer" -ForegroundColor White
    
    pause
}
