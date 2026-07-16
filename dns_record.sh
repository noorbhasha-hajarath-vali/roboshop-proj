#!/bin/bash

DOMAIN="ayri.fun"
SUBDOMAIN="test"          # Use "@" or leave empty for the root domain
IP_ADDRESS="13.233.100.200"

# ==========================
# Get Hosted Zone ID
# ==========================

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

# ==========================
# Record Name
# ==========================

if [ -z "$SUBDOMAIN" ] || [ "$SUBDOMAIN" = "@" ]; then
    RECORD_NAME="$DOMAIN"
else
    RECORD_NAME="$SUBDOMAIN.$DOMAIN"
fi

# ==========================
# Create Change Batch
# ==========================

cat > /tmp/record.json <<EOF
{
  "Comment": "Create/Update A Record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$SUBDOMAIN.$DOMAIN",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$IP_ADDRESS"
          }
        ]
      }
    }
  ]
}
EOF

# ==========================
# Create/Update DNS Record
# ==========================

aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch file:///tmp/record.json

echo "DNS record created/updated successfully."

aws route53 list-resource-record-sets \
    --hosted-zone-id "$ZONE_ID"