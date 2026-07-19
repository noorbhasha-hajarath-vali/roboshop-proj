#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

CHECK_ROOT

MONGODB_HOST="mongodb.ayri.fun"

dnf module disable nodejs -y
VALIDATE $? "Disable NodeJS Default Module"

dnf module enable nodejs:20 -y
VALIDATE $? "Enable NodeJS 20 Module"

dnf install nodejs -y
VALIDATE $? "Install NodeJS"

id roboshop &>/dev/null
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Create Roboshop User"
else
    echo "Roboshop User Already Exists"
fi

mkdir -p /app
VALIDATE $? "Create App Directory"

curl -L -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
VALIDATE $? "Download Catalogue"

cd /app
VALIDATE $? "Change Directory"

unzip -o /tmp/catalogue.zip
VALIDATE $? "Extract Catalogue"

npm install
VALIDATE $? "Install NodeJS Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copy Catalogue Service"

systemctl daemon-reload
VALIDATE $? "Reload Systemd"

systemctl enable catalogue
VALIDATE $? "Enable Catalogue Service"

systemctl start catalogue
VALIDATE $? "Start Catalogue Service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy MongoDB Repo"

dnf install mongodb-mongosh -y
VALIDATE $? "Install MongoDB Shell"

mongosh --host "$MONGODB_HOST" </app/db/master-data.js
VALIDATE $? "Load Catalogue Data"

systemctl restart catalogue
VALIDATE $? "Restart Catalogue Service"

COMPLETE