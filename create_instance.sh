#!/bin/bash

AMI_ID=ami-0220d79f3f480ecf5
SG_ID=sg-014ee579326daf5b9

for INSTANCE in $@
do
# create instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t3.micro \
    --key-name devops \
    --security-group-ids sg-1a2b3c4d \
    --query 'Instances[0].InstanceId' \
    --output text)

echo $INSTANCE_ID
done

# add dns record
#track logs