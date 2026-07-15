#!/bin/bash

AMI_ID=ami-002192a70217ac181
SG_ID=sg-014ee579326daf5b9

for INSTANCE in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --key-name devops \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" \
    --query 'Instances[0].InstanceId' \
    --output text)
done

echo "$INSTANCE: $INSTANCE_ID"
