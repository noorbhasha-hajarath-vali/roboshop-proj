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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "User Creation"
else
    echo -e "User Already Exists.. $Y SKIPPING $NC" 
fi

mkdir -p /app
VALIDATE $? "Create Directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOG_FILE
VALIDATE $? "Download Files"

cd /app 
VALIDATE $? "Go inside app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip  &>>$LOG_FILE
VALIDATE $? "unzip files"

npm install  &>>$LOG_FILE
VALIDATE $? "Install dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "create user.service file"

systemctl daemon-reload
VALIDATE $? "Daemon Reload"

systemctl enable user 
VALIDATE $? "Enable service"

systemctl start user
VALIDATE $? "Start service"