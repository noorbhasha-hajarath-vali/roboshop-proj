#!/bin/bash

# ==========================================================
# Logging
# ==========================================================

LOG_DIR=${LOG_DIR:-"$HOME/shell-roboshop/logs"}

FILE_NAME=$(basename "$0" .sh)
LOG_FILE="$LOG_DIR/$FILE_NAME.log"

mkdir -p "$LOG_DIR"

# Save original stdout/stderr
exec 3>&1 4>&2

# Send everything else to the log file
exec >>"$LOG_FILE" 2>&1

echo "=================================================================="
echo "Process Started At : $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Script Name        : $FILE_NAME.sh"
echo "Log File           : $LOG_FILE"
echo "=================================================================="

# ==========================================================
# Root Check
# ==========================================================

CHECK_ROOT() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: Please run this script as root." >&3
        echo "ERROR: Please run this script as root."
        exit 1
    fi
}

# ==========================================================
# Validation
# ==========================================================

VALIDATE() {
    local STATUS=$1
    local MESSAGE=$2

    if [ "$STATUS" -eq 0 ]; then
        echo "$MESSAGE ... SUCCESS" >&3
        echo "$MESSAGE ... SUCCESS"
    else
        echo "$MESSAGE ... FAILED" >&3
        echo "$MESSAGE ... FAILED"
        exit 1
    fi
}

# ==========================================================
# Complete
# ==========================================================

COMPLETE() {
    echo "=================================================================="
    echo "Process Completed At : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "=================================================================="

    echo >&3
    echo "Process Completed Successfully." >&3
    echo "Log File : $LOG_FILE" >&3
}