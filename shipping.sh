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

dnf install maven -y

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

mkdir -p /app

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip

cd /app

unzip /tmp/shipping.zip

mvn clean package

mv target/shipping-1.0.jar shipping.jar

systemctl daemon-reload

systemctl enable shipping

systemctl start shipping

dnf install mysql -y

mysql -h mysql.ayri.fun -uroot -pRoboShop@1 < /app/db/schema.sql

mysql -h mysql.ayri.fun -uroot -pRoboShop@1 < /app/db/app-user.sql

mysql -h mysql.ayri.fun -uroot -pRoboShop@1 < /app/db/master-data.sql

systemctl restart shipping