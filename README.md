# Shadowsocks Installation on Ubuntu 20.04 and Later

Shadowsocks is a high-performance cross-platform secured socks5 proxy. It will help you surf the internet privately and securely. This script automates the installation of Shadowsocks on a Ubuntu 20.04 or later server.

## Installation Command

To install Shadowsocks, you can use the following command:

```bash
wget https://is.gd/ss_installer -O ss_installer.sh && bash ss_installer.sh
```

This command performs the following actions:
- Downloads the installation script using `wget`.
- Saves the script as `ss-install.sh`.
- Executes the script using `bash`.

## Features of the Script

- **Automated Installation**: The script automates the process of installing Shadowsocks, making it easy and hassle-free.
- **Security**: Generates a random port and password for the Shadowsocks server to enhance security.
- **Customization**: Allows you to choose the encryption method and optionally specify a custom port, password, and DNS server.
- **Service Management**: Creates and manages a systemd service for Shadowsocks, enabling easy start, stop, and automatic startup on boot.

## Before You Begin

Ensure your system is updated. You might want to run:

```bash
sudo apt update && sudo apt upgrade -y
```

## Usage

After installation, the script will output the Shadowsocks server credentials, including:
- Server IP
- Port
- Password
- Encryption method
- DNS server

You can use these credentials to configure Shadowsocks clients on your devices.

## Managing Shadowsocks Service

The script creates and runs a systemd service for Shadowsocks, making it easy to manage the server. 
But if you want to manage it - here are some common commands:

- To start the Shadowsocks service:

  ```bash
  sudo systemctl start shadowsocks-libev-server@config
  ```

- To stop the Shadowsocks service:

  ```bash
  sudo systemctl stop shadowsocks-libev-server@config
  ```

- To enable Shadowsocks service to start on boot:

  ```bash
  sudo systemctl enable shadowsocks-libev-server@config
  ```

- To disable Shadowsocks service from starting on boot:

  ```bash
  sudo systemctl disable shadowsocks-libev-server@config
  ```

## Uninstallation

If you want to delete Shadowsocks, you can run the script again and select the delete option.
Or stop the service, disable it, and then remove the package:

```bash
sudo systemctl stop shadowsocks-libev-server@config
sudo systemctl disable shadowsocks-libev-server@config
sudo apt-get remove --purge -y shadowsocks-libev
```

Don't forget to also remove the systemd service file if necessary.

## Conclusion

This script simplifies the process of setting up a Shadowsocks server on Ubuntu 20.04 and later. It ensures you have a secure, private channel for your internet browsing needs.
