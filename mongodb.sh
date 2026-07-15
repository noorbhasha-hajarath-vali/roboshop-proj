#!/bin/bash

USER_ID=$(id -u)

LOG_DIR=/var/log/shell-roboshop
LOG_FILE=$(basename $0 .sh)

echo $LOG_FILE