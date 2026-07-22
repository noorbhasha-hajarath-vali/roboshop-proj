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

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disable redis"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enable redis 7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Install redis"

sed -i \
    -e 's/^bind 127\.0\.0\.1.*/bind 0.0.0.0/' \
    -e 's/^protected-mode yes/protected-mode no/' \
    /etc/redis/redis.conf
VALIDATE $? "Update redis.conf"

systemctl enable redis
VALIDATE $? "Enable redis service"

systemctl start redis
VALIDATE $? "Start redis service"