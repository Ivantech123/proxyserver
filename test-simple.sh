#!/bin/bash

# Check if running on Linux
OS_TYPE=$(uname)
echo "Detected OS: $OS_TYPE"

if [ "$OS_TYPE" != "Linux" ]; then
    echo "[ERROR] This script is for Linux systems only!"
    echo "[INFO] For Windows use: .\\install-and-run-v2.ps1 (Run as Administrator)"
    echo "[LINK] See instructions: https://github.com/Ivantech123/proxyserver"
    exit 1
fi

echo "[OK] Script is running on Linux, continuing..."
