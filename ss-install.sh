#!/bin/bash
#lastlibertarian

PORT=""
PASSWORD=""
METHOD=""
NAMESERVER=""

function shutdown() {
  tput cnorm # Восстанавливаем видимость курсора
}
trap shutdown EXIT

function spinner() {
  local pid=$1 # ID процесса предыдущей запущенной команды
  local spin='▉▊▋▌▍▎▏▎▍▌▋▊▉'
  local charwidth=10
  local i=0
  tput civis # Скрываем курсор
  while kill -0 $pid 2>/dev/null; do
    i=$(((i + charwidth) % ${#spin}))
    printf "%s" "${spin:$i:$charwidth}"
    echo -en "\033[${charwidth}D"
    sleep .1
  done
  tput cnorm # Восстанавливаем видимость курсора
  wait $pid # Ждем завершения процесса и возвращаем его статус
  return $?
}

# Функция для вывода цветного текста
echo_color() {
  color=$1
  text=$2
  echo -e "\e[${color}m${text}\e[0m"
}

generate_random_password() {
  echo $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
}

print_shadowsocks_credentials() {
  IP=$(hostname -I | cut -d' ' -f1)
  # Используем переменную $HOME для указания домашнего каталога
  CREDENTIALS_FILE="$HOME/ss-credentials.txt"

  # Запись данных в файл
  {
    echo "----------------------------------------------------------"
    echo
    echo "Shadowsocks credentials"
    echo
    echo "ip         $IP"
    echo "port       $PORT"
    echo "password   $PASSWORD"
    echo "method     $METHOD"
    echo "nameserver $NAMESERVER"
    echo
    echo "----------------------------------------------------------"
  } > "$CREDENTIALS_FILE"

  # Вывод содержимого файла в консоль
  cat "$CREDENTIALS_FILE" | while IFS= read -r line; do echo_color 32 "$line"; done
  echo_color 93 "Credentials are available in $CREDENTIALS_FILE"
}


update_shadowsocks_config() {
  # Запрашиваем порт
  read -p "Enter port (from 100 to 65535, skip for random selection): " PORT
  if [[ ! $PORT =~ ^[0-9]+$ ]] || [ "$PORT" -lt 100 ] || [ "$PORT" -gt 65535 ]; then
    PORT=$((RANDOM % 65535 + 100)) # Рандомный порт от 100 до 65535
  fi

  # Запрашиваем пароль
  read -p "Enter your password (skip to generate password): " PASSWORD
  if [ -z "$PASSWORD" ]; then
    PASSWORD=$(generate_random_password) # Рандомный пароль из 24 символов
  fi

  # Массив с методами шифрования
  declare -a ENCRYPTION_METHODS=("aes-256-gcm" "aes-256-cfb" "bf-cfb" "camellia-256-cfb" "salsa20" "chacha20" "chacha20-ietf-poly1305" "rc4-md5")
  echo "Select an encryption method:"
  for i in "${!ENCRYPTION_METHODS[@]}"; do
    echo "  [$((i+1))] ${ENCRYPTION_METHODS[$i]}"
  done

  read -p "Enter method number (skip for aes-256-gcm): " ENCRYPTION_CHOICE
  if [[ ! $ENCRYPTION_CHOICE =~ ^[0-9]+$ ]] || [ "$ENCRYPTION_CHOICE" -lt 1 ] || [ "$ENCRYPTION_CHOICE" -gt ${#ENCRYPTION_METHODS[@]} ]; then
    METHOD='aes-256-gcm'
  else
    METHOD=${ENCRYPTION_METHODS[$((ENCRYPTION_CHOICE-1))]}
  fi

  # Массив с DNS серверами
  declare -A DNS_SERVERS=(
    [1]="1.1.1.1"         # Cloudflare
    [2]="8.8.8.8"         # Google
    [3]="208.67.222.222"  # OpenDNS
    [4]="9.9.9.9"         # Quad9
    [5]="176.103.130.130" # AdGuard
  )

  echo "Select DNS server:"
  echo "  [1] Cloudflare"
  echo "  [2] Google"
  echo "  [3] OpenDNS"
  echo "  [4] Quad9"
  echo "  [5] AdGuard"
  
  read -p "Enter the DNS server number (skip for Cloudflare): " DNS_CHOICE

  # Проверяем, что введено число от 1 до 5. Если нет, используем Cloudflare по умолчанию.
  if [[ ! $DNS_CHOICE =~ ^[1-5]$ ]]; then
    DNS_CHOICE=1
  fi

  NAMESERVER=${DNS_SERVERS[$DNS_CHOICE]}

  echo_color 33 "Configuring shadowsocks"
  sudo bash -c "cat > /etc/shadowsocks-libev/config.json" <<EOF
  {
    "server":["::0", "0.0.0.0"],
    "server_port": $PORT,
    "password": "$PASSWORD",
    "timeout":300,
    "method":"$METHOD",
    "nameserver":"$NAMESERVER",
    "mode":"tcp_and_udp"
  }
EOF
  
  sudo systemctl restart shadowsocks-libev > /dev/null 2>&1
  sudo systemctl daemon-reload

  PORT=$PORT
  PASSWORD=$PASSWORD
  METHOD=$METHOD
  NAMESERVER=$NAMESERVER
}

clear

# Проверяем, установлен ли shadowsocks-libev
if dpkg -l | grep -qw shadowsocks-libev; then
  echo_color 33 "Shadowsocks is already installed"
  
  # Предлагаем пользователю выбор
  echo "Choose:"
  echo "  [1] Update the shadowsocks configuration"
  echo "  [2] Remove shadowsocks"
  read -p "Select an action: " action
  
  case $action in
    1)
      echo_color 33 "Updating the shadowsocks configuration..."

      update_shadowsocks_config
      sudo lsof -i :$PORT| awk 'NR!=1 {print $2}' | xargs -r sudo kill -9

      sudo systemctl restart shadowsocks-libev-server@service > /dev/null 2>&1

      clear
      print_shadowsocks_credentials
      ;;
    2)
      echo_color 33 "Removing shadowsocks..."
      
      # Останавливаем и отключаем сервис shadowsocks-libev
      sudo systemctl stop shadowsocks-libev-server@service > /dev/null 2>&1
      sudo systemctl disable shadowsocks-libev-server@service > /dev/null 2>&1

      # Удаляем файл конфигурации сервиса
      sudo rm -f /etc/systemd/system/shadowsocks-libev-server@service

      # Перезагружаем демон systemctl для применения изменений
      sudo systemctl daemon-reload

      # Удаляем пакет shadowsocks-libev
      sudo apt-get remove --purge -y shadowsocks-libev > /dev/null 2>&1 & PID=$!

      spinner $PID
      clear
      echo_color 32 "Shadowsocks has been successfully deleted."
      ;;
    *)
      echo_color 31 "Wrong choice. Exit"
      exit 1
      ;;
  esac
else
  echo_color 33 "Shadowsocks is not installed. The beginning of the installation"
  
  echo_color 33 "Updating system"
  sudo apt update > /dev/null 2>&1 & PID=$!
  spinner $PID

  echo_color 33 "Installing shadowsocks"
  sudo apt install -y shadowsocks-libev > /dev/null 2>&1 & PID=$!
  spinner $PID
  
  update_shadowsocks_config

  sudo systemctl enable shadowsocks-libev > /dev/null 2>&1

  # Создаем и включаем службу shadowsocks-libev
  echo_color 33 "Creating service"
  cat > /etc/systemd/system/shadowsocks-libev-server@.service <<EOF
  [Unit]
  Description=Shadowsocks-Libev Custom Server Service for %I
  Documentation=man:ss-server(1)
  After=network-online.target
  StartLimitIntervalSec=500
  StartLimitBurst=5

  [Service]
  Type=simple
  Restart=always
  RestartSec=5s
  ExecStart=/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json

  [Install]
  WantedBy=multi-user.target
EOF
  
  sudo lsof -i :$PORT| awk 'NR!=1 {print $2}' | xargs -r sudo kill -9
  sudo systemctl enable --now shadowsocks-libev-server@service > /dev/null 2>&1
  sudo systemctl restart shadowsocks-libev-server@service > /dev/null 2>&1

  clear
  echo_color 32 "Shadowsocks installation and configuration completed."

  # Выводим информацию
  print_shadowsocks_credentials
fi

