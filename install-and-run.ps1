# Proxy server installation and setup script
# Must be run as Administrator

# Set error handling
$ErrorActionPreference = "Stop"

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click on PowerShell and select 'Run as Administrator'" -ForegroundColor Red
    pause
    exit 1
}

# Function for progress display
function Show-Progress {
    param(
        [string]$Activity,
        [int]$PercentComplete,
        [string]$Status
    )
    Write-Progress -Activity $Activity -PercentComplete $PercentComplete -Status $Status
}

# Function for status output
function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    Write-Host "==> $Message" -ForegroundColor $(switch ($Type) {
        "Info" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    })
}

# Проверка системных требований
function Test-SystemRequirements {
    Write-Status "Checking system requirements..." "Info"
    Show-Progress -Activity "System Check" -PercentComplete 0 -Status "Checking CPU..."
    
    # Check CPU cores
    $cpuCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
    if ($cpuCores -lt 2) {
        Write-Status "Warning: Less than 2 CPU cores ($cpuCores cores)" "Warning"
    } else {
        Write-Status "CPU cores: $cpuCores" "Info"
    }
    
    Show-Progress -Activity "System Check" -PercentComplete 33 -Status "Checking RAM..."
    
    # Check RAM
    $totalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    if ($totalRAM -lt 2) {
        Write-Status "Warning: Less than 2GB RAM ($totalRAM GB)" "Warning"
    } else {
        Write-Status "RAM: $totalRAM GB" "Info"
    }
    
    Show-Progress -Activity "System Check" -PercentComplete 66 -Status "Checking disk space..."
    
    # Check disk space
    $disk = Get-PSDrive C
    $freeSpaceGB = [math]::Round($disk.Free / 1GB, 2)
    if ($freeSpaceGB -lt 40) {
        Write-Status "Warning: Less than 40GB free space ($freeSpaceGB GB)" "Warning"
    } else {
        Write-Status "Free disk space: $freeSpaceGB GB" "Info"
    }
    
    Show-Progress -Activity "System Check" -PercentComplete 100 -Status "Complete"
    Start-Sleep -Seconds 1
}

# Check dependencies
function Test-Dependencies {
    Write-Status "Checking required software..." "Info"
    $deps = @{
        "Docker" = { Get-Command docker -ErrorAction SilentlyContinue }
        "Git" = { Get-Command git -ErrorAction SilentlyContinue }
        "OpenSSL" = { Get-Command openssl -ErrorAction SilentlyContinue }
    }
    
    $i = 0
    $missing = @()
    
    foreach ($dep in $deps.GetEnumerator()) {
        $i++
        $percent = ($i / $deps.Count) * 100
        Show-Progress -Activity "Checking Dependencies" -PercentComplete $percent -Status "Checking $($dep.Key)..."
        
        if (-not (& $dep.Value)) {
            $missing += $dep.Key
            Write-Status "$($dep.Key) is not installed" "Warning"
        } else {
            Write-Status "$($dep.Key) is installed" "Info"
        }
    }
    
    if ($missing.Count -eq 0) {
        Write-Status "All dependencies are installed" "Info"
    } else {
        Write-Status "Missing dependencies: $($missing -join ', ')" "Warning"
    }
    
    return $missing
}

# Установка зависимостей
function Install-Dependencies {
    param($MissingDeps)
    
    if ($null -eq $MissingDeps -or $MissingDeps.Count -eq 0) {
        Write-Status "No dependencies to install" "Info"
        return
    }
    
    Write-Status "Installing missing dependencies: $($MissingDeps -join ', ')" "Info"
    
    $total = $MissingDeps.Count
    $current = 0
    
    foreach ($dep in $MissingDeps) {
        $current++
        $percent = ($current / $total) * 100
        Show-Progress -Activity "Установка зависимостей" -PercentComplete $percent -Status "Установка $dep..."
        
        switch ($dep) {
            "Docker" {
                Write-Status "Установка Docker..." "Info"
                $dockerUrl = "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
                $installerPath = "$env:TEMP\DockerInstaller.exe"
                Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath
                Start-Process -Wait $installerPath -ArgumentList "install --quiet"
                Remove-Item $installerPath
            }
            "Git" {
                Write-Status "Установка Git..." "Info"
                winget install -e --id Git.Git
            }
            "OpenSSL" {
                Write-Status "Установка OpenSSL..." "Info"
                if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
                    Set-ExecutionPolicy Bypass -Scope Process -Force
                    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
                }
                choco install openssl -y
            }
        }
    }
}

# Инициализация Git
function Initialize-Git {
    Write-Status "Инициализация Git репозитория..." "Info"
    
    Show-Progress -Activity "Git Setup" -PercentComplete 0 -Status "Инициализация репозитория..."
    git init
    
    Show-Progress -Activity "Git Setup" -PercentComplete 50 -Status "Добавление файлов..."
    git add .
    
    Show-Progress -Activity "Git Setup" -PercentComplete 75 -Status "Создание начального коммита..."
    git commit -m "Начальный коммит: настройка прокси-сервера"
    
    Show-Progress -Activity "Git Setup" -PercentComplete 100 -Status "Завершено"
}

# Обработка ошибок
$ErrorActionPreference = "Stop"

function Write-Status {
    param($Message)
    Write-Host "==> $Message" -ForegroundColor Green
}

function Install-DockerIfNeeded {
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Status "Installing Docker..."
        # Download Docker Desktop Installer
        $dockerUrl = "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
        $installerPath = "$env:TEMP\DockerInstaller.exe"
        Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath
        
        # Install Docker Desktop
        Start-Process -Wait $installerPath -ArgumentList "install --quiet"
        Remove-Item $installerPath
        
        Write-Status "Docker installation complete. Please restart your computer and run this script again."
        exit
    }
}

function Install-OpenSSLIfNeeded {
    if (!(Get-Command openssl -ErrorAction SilentlyContinue)) {
        Write-Status "Installing OpenSSL..."
        # Using Chocolatey to install OpenSSL
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }
        choco install openssl -y
    }
}

function New-SSLCertificate {
    Write-Status "Generating SSL certificates..."
    if (!(Test-Path "certs")) {
        New-Item -ItemType Directory -Path "certs"
    }
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
        -keyout certs/server.key -out certs/server.crt `
        -subj "/CN=localhost" `
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
    
    Get-Content certs/server.crt, certs/server.key | Set-Content certs/server.pem
}

function Start-ProxyServer {
    Write-Status "Starting proxy server..." "Info"
    
    # Build and start containers
    docker-compose up --build -d
    
    # Generate initial proxies
    Write-Status "Generating proxies..." "Info"
    docker exec proxy-server /usr/local/bin/generate_proxies.sh 1000
    
    # Show status
    Write-Status "Checking proxy server status..." "Info"
    docker ps
    
    # Show proxy list
    Write-Status "Available proxies:" "Info"
    docker exec proxy-server cat /etc/haproxy/proxies.txt
}

function Show-Menu {
    Clear-Host
    Write-Host "=== Proxy Server Management ===" -ForegroundColor Cyan
    Write-Host "1. Check system and dependencies"
    Write-Host "2. Install missing components"
    Write-Host "3. Initialize Git repository"
    Write-Host "4. Install and start proxy server"
    Write-Host "5. Stop proxy server"
    Write-Host "6. View proxy list"
    Write-Host "7. Update proxy credentials"
    Write-Host "8. View logs"
    Write-Host "9. Restart proxy server"
    Write-Host "10. Exit"
    Write-Host
    
    $choice = Read-Host "Enter your choice (1-10)"
    return $choice
}

function Update-ProxyCredentials {
    Show-Progress -Activity "Updating Credentials" -PercentComplete 0 -Status "Entering data..."
    
    $port = Read-Host "Enter port number"
    $username = Read-Host "Enter new username"
    $password = Read-Host "Enter new password"
    
    Show-Progress -Activity "Updating Credentials" -PercentComplete 50 -Status "Updating..."
    
    docker exec proxy-server /usr/local/bin/update_credentials.sh single $port $username $password
    
    Show-Progress -Activity "Updating Credentials" -PercentComplete 100 -Status "Complete"
    Write-Status "Credentials updated successfully" "Info"
}

# Main script
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
                Write-Status "Installation complete!" "Info"
                pause
            }
            "5" {
                Show-Progress -Activity "Server Management" -PercentComplete 50 -Status "Stopping server..."
                docker-compose down
                Show-Progress -Activity "Server Management" -PercentComplete 100 -Status "Server stopped"
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
                pause
            }
            "10" {
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
    pause
}
