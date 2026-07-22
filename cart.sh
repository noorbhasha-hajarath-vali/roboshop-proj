#!/bin/bash

set -Eeuo pipefail

trap 'echo "ERROR: Command \"$BASH_COMMAND\" failed at line $LINENO"' ERR

USER_ID=$(id -u)
SCRIPT_DIR=$(pwd)

R='\033[0;31m'   # Red
G='\033[0;32m'   # Green
Y='\033[0;33m'   # Yellow
NC='\033[0m'     # No Color

LOG_DIR="/var/log/roboshop_proj"
SCRIPT_FILE=$(basename "$0" .sh)

mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/$SCRIPT_FILE.log"

echo "Script Started at.. $(date)" | tee -a $LOG_FILE

if [ "$USER_ID" -ne 0 ]; then
    echo -e "${R}Run with root privileges${NC}"
    exit 1
fi

VALIDATE() {
    if [ "$1" -ne 0 ]; then
        echo -e "$2... ${R}FAILURE${NC}" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2... ${G}SUCCESS${NC}" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "Enable nodejs"

dnf install nodejs -y
VALIDATE $? "Install nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Setup system user"

mkdir -p /app
VALIDATE $? "Create Directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
VALIDATE $? "Download Files"

cd /app 
VALIDATE $? "Go inside app directory"

unzip /tmp/cart.zip
VALIDATE $? "unzip files"

npm install
VALIDATE $? "Install dependencies"

systemctl daemon-reload
VALIDATE $? "Daemon Reload"

systemctl enable cart 
VALIDATE $? "Enable service"

systemctl start cart
VALIDATE $? "Start service"