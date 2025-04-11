#!/bin/bash

# Проверка, запущен ли скрипт на Linux
if [[ "$(uname)" != "Linux" ]]; then
    echo "🚫 Error: This script is for Linux systems only!"
    echo "📄 For Windows use: .\install-and-run-v2.ps1 (Run as Administrator)"
    echo "🔗 See instructions: https://github.com/Ivantech123/proxyserver#-установка"
    exit 1
fi

echo "✅ Script is running on Linux, continuing..."
