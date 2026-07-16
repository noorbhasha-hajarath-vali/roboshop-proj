#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

AMI_ID="ami-002192a70217ac181"
SG_ID="sg-014ee579326daf5b9"
DOMAIN="ayri.fun"

for INSTANCE in "$@"
do
    echo "Creating Instance : $INSTANCE" >&3
    echo "Creating Instance : $INSTANCE"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --key-name devops \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    VALIDATE $? "Create EC2 Instance"

    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
    VALIDATE $? "Wait for Instance"

    if [ "$INSTANCE" = "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)

        RECORD_NAME="$DOMAIN"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)

        RECORD_NAME="$INSTANCE.$DOMAIN"
    fi

    VALIDATE $? "Get Instance IP"

    ZONE_ID=$(aws route53 list-hosted-zones-by-name \
        --dns-name "$DOMAIN" \
        --query "HostedZones[?Name=='$DOMAIN.'].Id | [0]" \
        --output text)

    if [ "$ZONE_ID" = "None" ]; then
        ZONE_ID=$(aws route53 create-hosted-zone \
            --name "$DOMAIN" \
            --caller-reference "$(date +%s)" \
            --query "HostedZone.Id" \
            --output text)
    fi

    ZONE_ID=${ZONE_ID#/hostedzone/}

    cat >/tmp/record.json <<EOF
{
  "Comment": "UPSERT A Record",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$RECORD_NAME",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{
        "Value": "$IP"
      }]
    }
  }]
}
EOF

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch file:///tmp/record.json

    VALIDATE $? "Create DNS Record"
done

COMPLETE