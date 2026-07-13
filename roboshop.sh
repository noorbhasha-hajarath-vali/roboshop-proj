#!/bin/bash

AMI_ID=ami-002192a70217ac181
SG_ID=sg-014ee579326daf5b9
ZONE_ID=Z09974681JREIYBUXFTO2

for INSTANCE in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --key-name devops --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" --query 'Instances[0].InstanceId' --output text)

    if [ INSTANCE != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    fi

    aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"$INSTANCE.ayri.fun\",
        \"Type\": \"A\",
        \"TTL\": 1,
        \"ResourceRecords\": [{
          \"Value\": \"$IP\"
        }]
      }
    }]
  }"
done