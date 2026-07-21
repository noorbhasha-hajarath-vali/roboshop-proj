#!/bin/bash

USER_ID=$(id -u)
SCRIPT_DIR=$(pwd)

R='\033[0;31m'   # Red
G='\033[0;32m'   # Green
Y='\033[0;33m'   # Yellow
NC='\033[0m'     # No Color

if [ "$USER_ID" -ne 0 ]; then
    echo -e "${R}Run with root privileges${NC}"
    exit 1
fi

VALIDATE() {
    if [ "$1" -ne 0 ]; then
        echo -e "$2... ${R}FAILURE${NC}"
        exit 1
    else
        echo -e "$2... ${G}SUCCESS${NC}"
    fi
}

cp "$SCRIPT_DIR/mongo.repo" /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy repo file"

dnf install mongodb-org -y
VALIDATE $? "Install MongoDB"

systemctl enable mongod
VALIDATE $? "Enable MongoDB"

systemctl start mongod
VALIDATE $? "Start MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Configure MongoDB"

systemctl restart mongod
VALIDATE $? "Restart MongoDB"