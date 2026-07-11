#!/bin/bash

AMI_ID=ami-002192a70217ac181
SG_ID=sg-014ee579326daf5b9


for INSTANCE in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --key-name devops --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" --query 'Instances[0].InstanceId' --output text)

    if [ $INSTANCE != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text) # get private instance id
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text) # get public instance id
    fi

    echo $INSTANCE: $IP
done