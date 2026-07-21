#!/bin/bash

AMI_ID=ami-0220d79f3f480ecf5
SG_ID=sg-014ee579326daf5b9
ZONE_ID=Z0531989124USCH6EH8I9
DOMAIN_NAME=ayri.fun

for INSTANCE in $@
do
# create instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --key-name devops \
    --security-group-ids $SG_ID \
     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$INSTANCE'}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance Created Successfully, Instance ID is: $INSTANCE_ID"

if [ $INSTANCE != "frontend" ]; then
    IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].PrivateIpAddress" \
    --output text)
    RECORD_NAME=$INSTANCE.$DOMAIN_NAME
else
    IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --output text)
    RECORD_NAME=$DOMAIN_NAME
fi

aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch '
    {
  "Comment": "Updating an A record for the main website",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'$RECORD_NAME'",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "'$IP'"
          }
        ]
      }
    }
  ]
}
'
done