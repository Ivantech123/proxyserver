# Скрипт установки и настройки прокси-сервера
# Запускать от имени администратора

# Обработка ошибок
$ErrorActionPreference = "Stop"

# Функция для отображения прогресса
function Show-Progress {
    param(
        [string]$Activity,
        [int]$PercentComplete,
        [string]$Status
    )
    Write-Progress -Activity $Activity -PercentComplete $PercentComplete -Status $Status
}

# Функция для вывода статуса
function Write-Status {
    param($Message, $Type = "Info")
    switch ($Type) {
        "Info" { $Color = "Green" }
        "Warning" { $Color = "Yellow" }
        "Error" { $Color = "Red" }
    }
    Write-Host "==> $Message" -ForegroundColor $Color
}

# Проверка системных требований
function Test-SystemRequirements {
    Write-Status "Проверка системных требований..." "Info"
    Show-Progress -Activity "Проверка системы" -PercentComplete 0 -Status "Проверка CPU..."
    
    # Проверка ядер CPU
    $cpuCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
    if ($cpuCores -lt 2) {
        Write-Status "Внимание: Меньше 2 ядер CPU ($cpuCores ядер)" "Warning"
    }
    
    Show-Progress -Activity "Проверка системы" -PercentComplete 33 -Status "Проверка RAM..."
    
    # Проверка RAM
    $totalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    if ($totalRAM -lt 2) {
        Write-Status "Внимание: Меньше 2GB RAM ($totalRAM GB)" "Warning"
    }
    
    Show-Progress -Activity "Проверка системы" -PercentComplete 66 -Status "Проверка места на диске..."
    
    # Проверка места на диске
    $disk = Get-PSDrive C
    $freeSpaceGB = [math]::Round($disk.Free / 1GB, 2)
    if ($freeSpaceGB -lt 40) {
        Write-Status "Внимание: Меньше 40GB свободного места ($freeSpaceGB GB)" "Warning"
    }
    
    Show-Progress -Activity "Проверка системы" -PercentComplete 100 -Status "Завершено"
    Start-Sleep -Seconds 1
}

# Проверка зависимостей
function Test-Dependencies {
    Write-Status "Проверка необходимого ПО..." "Info"
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
        Show-Progress -Activity "Проверка зависимостей" -PercentComplete $percent -Status "Проверка $($dep.Key)..."
        
        if (-not (& $dep.Value)) {
            $missing += $dep.Key
            Write-Status "$($dep.Key) не установлен" "Warning"
        } else {
            Write-Status "$($dep.Key) установлен" "Info"
        }
    }
    
    return $missing
}

# Установка зависимостей
function Install-Dependencies {
    param($MissingDeps)
    
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
    Write-Status "Starting proxy server..."
    
    # Build and start containers
    docker-compose up --build -d
    
    # Generate initial proxies
    Write-Status "Generating proxies..."
    docker exec proxy-server /usr/local/bin/generate_proxies.sh 1000
    
    # Show status
    Write-Status "Checking proxy server status..."
    docker ps
    
    # Show proxy list
    Write-Status "Available proxies:"
    docker exec proxy-server cat /etc/haproxy/proxies.txt
}

function Show-Menu {
    Clear-Host
    Write-Host "=== Управление прокси-сервером ===" -ForegroundColor Cyan
    Write-Host "1. Проверить систему и зависимости"
    Write-Host "2. Установить недостающие компоненты"
    Write-Host "3. Инициализировать Git репозиторий"
    Write-Host "4. Установить и запустить прокси-сервер"
    Write-Host "5. Остановить прокси-сервер"
    Write-Host "6. Посмотреть список прокси"
    Write-Host "7. Обновить учетные данные прокси"
    Write-Host "8. Посмотреть логи"
    Write-Host "9. Перезапустить прокси-сервер"
    Write-Host "10. Выход"
    Write-Host
}

function Update-ProxyCredentials {
    Show-Progress -Activity "Обновление учетных данных" -PercentComplete 0 -Status "Ввод данных..."
    
    $port = Read-Host "Введите номер порта"
    $username = Read-Host "Введите новое имя пользователя"
    $password = Read-Host "Введите новый пароль"
    
    Show-Progress -Activity "Обновление учетных данных" -PercentComplete 50 -Status "Обновление..."
    
    docker exec proxy-server /usr/local/bin/update_credentials.sh single $port $username $password
    
    Show-Progress -Activity "Обновление учетных данных" -PercentComplete 100 -Status "Завершено"
    Write-Status "Учетные данные обновлены" "Info"
}

# Main script
try {
    $missingDeps = $null
    
    while ($true) {
        Show-Menu
        $choice = Read-Host "Введите ваш выбор (1-10)"
        
        switch ($choice) {
            "1" {
                Test-SystemRequirements
                $missingDeps = Test-Dependencies
                pause
            }
            "2" {
                if ($null -eq $missingDeps) {
                    Write-Status "Сначала выполните проверку системы (Пункт 1)" "Warning"
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
                Write-Status "Установка завершена!" "Info"
                pause
            }
            "5" {
                Show-Progress -Activity "Управление сервером" -PercentComplete 50 -Status "Остановка сервера..."
                docker-compose down
                Show-Progress -Activity "Управление сервером" -PercentComplete 100 -Status "Сервер остановлен"
                pause
            }
            "6" {
                Write-Status "Текущий список прокси:" "Info"
                docker exec proxy-server cat /etc/haproxy/proxies.txt
                pause
            }
            "7" {
                Update-ProxyCredentials
                pause
            }
            "8" {
                Write-Status "Последние записи:" "Info"
                docker exec proxy-server tail -f /var/log/haproxy/access.log
                pause
            }
            "9" {
                Show-Progress -Activity "Управление сервером" -PercentComplete 50 -Status "Перезапуск сервера..."
                docker-compose restart
                Show-Progress -Activity "Управление сервером" -PercentComplete 100 -Status "Сервер перезапущен"
                pause
            }
            "10" {
                Write-Status "Завершение работы..." "Info"
                exit
            }
            default {
                Write-Status "Неверный выбор. Попробуйте еще раз." "Error"
                pause
            }
        }
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    pause
}
