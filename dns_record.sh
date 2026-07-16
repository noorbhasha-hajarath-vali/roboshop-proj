#!/bin/bash

# Get Hosted Zone ID
ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name "$DOMAIN" \
    --query "HostedZones[?Name=='$DOMAIN.'].Id | [0]" \
    --output text)

if [ "$ZONE_ID" = "None" ]; then
    echo "Hosted Zone not found."
    echo "Creating Hosted Zone..."

    ZONE_ID=$(aws route53 create-hosted-zone \
        --name "$DOMAIN" \
        --caller-reference "$(date +%s)" \
        --query "HostedZone.Id" \
        --output text)

    echo "Hosted Zone created."
else
    echo "Hosted Zone already exists."
fi

# Remove "/hostedzone/" prefix
ZONE_ID=${ZONE_ID#/hostedzone/}

echo "Hosted Zone ID: $ZONE_ID"

cat >/tmp/record.json <<EOF
{
  "Comment": "Create/Update A Record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch file:///tmp/record.json

echo "DNS record created/updated successfully."

aws route53 list-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --query "ResourceRecordSets[*].[Name,ResourceRecords[*].Value]" \
    --output table