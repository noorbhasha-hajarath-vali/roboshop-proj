#!/bin/bash

USER_ID=$(id -u)

LOG_DIR=/var/log/shell-roboshop
FILE_NAME=$(basename $0 .sh)
LOG_FILE=$LOG_DIR/$FILE_NAME.log
echo $LOG_FILE