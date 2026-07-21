#!/bin/bash

USER_ID=$(id -u)
PATH=$(pwd)

R='\033[0;31m' # Red
G='\033[0;32m' # Green
Y='\033[0;33m' # Yellow
NC='\033[0m' # No Color


if [ $USER_ID -ne 0 ]; then
    echo "Run with root privilages"
    exit 1
fi

VALIDATE() {
    if [$1 -ne 0]; then
        echo "$2.. $R FAILURE $NC"
        exit 1
    else
        echo "$2.. $G SUCCESS $NC"
    fi
}

cp $PATH/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy files"

dnf install mongodb-org -y
VALIDATE $? "Install MongoDB"

systemctl enable mongod
VALIDATE $? "Enable MongoDB"

systemctl start mongod
VALIDATE $? "Start MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Start MongoDB"

systemctl restart mongod
VALIDATE $? "ReStart MongoDB"