#!/bin/bash

AMI_ID="ami-002192a70217ac181"
SG_ID="sg-014ee579326daf5b9"
DOMAIN="ayri.fun"

for INSTANCE in "$@"
do
    echo "Creating instance: $INSTANCE"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --key-name devops \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    echo "Instance ID: $INSTANCE_ID"

    # Wait until instance is running
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    if [ "$INSTANCE" != "frontend" ]; then
        while true
        do
            IP=$(aws ec2 describe-instances \
                --instance-ids "$INSTANCE_ID" \
                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                --output text)

            [ "$IP" != "None" ] && break
            sleep 2
        done

        RECORD_NAME="$INSTANCE.$DOMAIN"

    else
        while true
        do
            IP=$(aws ec2 describe-instances \
                --instance-ids "$INSTANCE_ID" \
                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                --output text)

            [ "$IP" != "None" ] && break
            sleep 2
        done

        RECORD_NAME="$DOMAIN"
    fi

    export DOMAIN
    export RECORD_NAME
    export IP

    sh dns_record.sh

done