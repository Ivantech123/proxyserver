<div align="center">

# 🚀 High-Performance Proxy Server

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Enabled-blue.svg)](https://www.docker.com/)
[![HTTP/2](https://img.shields.io/badge/HTTP%2F2-Supported-green.svg)]()
[![PowerShell](https://img.shields.io/badge/PowerShell-Required-blue.svg)]()

A powerful, secure, and easy-to-deploy HTTP/2 proxy server with Docker support
and automated installation.

[Features](#✨-features) • [Installation](#💻-installation) • [Usage](#📖-usage) • [Documentation](#📚-documentation)

</div>

## ✨ Features

<table>
  <tr>
    <td>🔒 <b>Security</b></td>
    <td>🐳 <b>Docker</b></td>
    <td>🚄 <b>Performance</b></td>
  </tr>
  <tr>
    <td>
      • SSL Certificate Generation<br/>
      • Secure Credential Management<br/>
      • Encrypted Data Storage
    </td>
    <td>
      • Container Isolation<br/>
      • Easy Deployment<br/>
      • Resource Management
    </td>
    <td>
      • HTTP/2 Support<br/>
      • Load Balancing<br/>
      • Connection Pooling
    </td>
  </tr>
</table>

## 🔧 Prerequisites

- Windows with PowerShell 5.1+
- Administrator privileges
- Docker Desktop
- Git
- OpenSSL

## 💻 Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Ivantech123/proxyserver.git
   cd proxyserver
   ```

2. **Run Installation Script** (as Administrator)
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; .\install-and-run.ps1
   ```

3. **Follow Setup Wizard**
   - System requirements check
   - Dependency installation
   - SSL certificate generation
   - Proxy server configuration

## 📖 Usage

### 🎯 Quick Start

1. Launch the management interface:
   ```powershell
   .\install-and-run.ps1
   ```

2. Choose from available options:
   ```
   === Proxy Server Management ===
   1. Check system and dependencies
   2. Install missing components
   3. Initialize Git repository
   4. Install and start proxy server
   5. Stop proxy server
   6. View proxy list
   7. Update proxy credentials
   8. View logs
   9. Restart proxy server
   10. Exit
   ```

### 🛠️ Configuration

- **SSL Certificates**: Automatically generated in `./certs/`
- **Proxy List**: Available at `./proxies.txt`
- **Logs**: Access via menu option 8

## 📚 Documentation

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU Cores | 2       | 4+          |
| RAM       | 2GB     | 4GB+        |
| Disk Space| 40GB    | 100GB+      |

### Directory Structure

```
📁 proxy-server
├── 📄 install-and-run.ps1    # Main installation script
├── 📄 docker-compose.yml     # Docker configuration
├── 📁 certs/                 # SSL certificates
├── 📁 scripts/              # Utility scripts
└── 📁 config/               # Configuration files
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

If you encounter any issues or need assistance:
1. Check the [documentation](#📚-documentation)
2. Open an [issue](https://github.com/Ivantech123/proxyserver/issues)
3. Contact the maintainers

---

<div align="center">

Made with ❤️ by [Ivantech123](https://github.com/Ivantech123)

</div>
