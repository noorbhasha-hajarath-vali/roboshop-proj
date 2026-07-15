#!/bin/bash

USER_ID=$(id -u)

LOG_DIR=/var/log/shell-roboshop
FILE_NAME=$(basename $0 .sh)
LOG_FILE=$LOG_DIR/$FILE_NAME.log

if [$USER_ID -ne 0 ]; then
    echo "User doesn't have root privilages, Run with sudo"
fi

echo "Process Started at $(date)"
