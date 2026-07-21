#!/bin/bash

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
VALIDATE $? "disable nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "enable nodejs:20"

dnf install nodejs -y
VALIDATE $? "install nodejs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "User Creation"
else
    echo "User Already Exists.. $Y SKIPPING $NC"
fi

mkdir /app
VALIDATE $? "Create app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
VALIDATE $? "Download Catalogue code"

cd /app
VALIDATE $? "Go to app directory"

unzip /tmp/catalogue.zip
VALIDATE $? "unxip catalogue code"

npm install
VALIDATE $? "Install Depenencies"

cp "$SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Install Depenencies"

systemctl daemon-reload
VALIDATE $? "Reload Deamon"

systemctl enable catalogue
VALIDATE $? "enable catalogue service"

systemctl start catalogue
VALIDATE $? "Start catalogue service"

cp "$SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy MongoDB Repo"

dnf install mongodb-mongosh -y
VALIDATE $? "Install MongoDB Client"

mongosh --host mongodb.ayri.fun </app/db/master-data.js
VALIDATE $? "Load Master Data"