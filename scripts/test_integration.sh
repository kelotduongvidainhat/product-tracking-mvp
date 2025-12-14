#!/bin/bash

# Script to test the full integration flow (API -> Kafka -> Worker -> Fabric -> DB)

API_URL="http://localhost:8081/products"
PRODUCT_ID="PROD-INT-$(date +%s)"
PRODUCT_NAME="Integration-Test-Product"
PRODUCER="Vinamilk-VN"
DATE=$(date -I)
HASH="sha256:integration-test-hash"

echo "----------------------------------------------------------------"
echo "FULL SYSTEM INTEGRATION TEST"
echo "----------------------------------------------------------------"

# 1. Create Product (API)
echo "1. Sending POST request to API..."
echo "   Product ID: $PRODUCT_ID"

RESPONSE=$(curl -s -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{
    "id": "'$PRODUCT_ID'",
    "name": "'$PRODUCT_NAME'",
    "producer_id": "'$PRODUCER'",
    "manufacture_date": "'$DATE'",
    "cert_hash": "'$HASH'"
  }')

echo "   Response: $RESPONSE"

if [[ $RESPONSE == *"Product creation requested"* ]]; then
    echo "✅ API Request Accepted!"
else
    echo "❌ API Request Failed!"
    exit 1
fi

echo "----------------------------------------------------------------"
echo "Waiting for background processing (Kafka -> Worker -> Blockchain)..."
# Give it some time for the worker to pick up and invoke chaincode
for i in {1..10}; do
    echo -n "."
    sleep 2
done
echo ""

# 2. Verify Status (API)
echo "2. Checking Product Status via API..."
GET_RESPONSE=$(curl -s -X GET "$API_URL/$PRODUCT_ID")
echo "   Response: $GET_RESPONSE"

STATUS=$(echo $GET_RESPONSE | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

if [[ "$STATUS" == "VERIFIED" ]]; then
    echo "✅ SUCCESS! Product status is VERIFIED."
    echo "   (Data has flowed: API -> DB(Pending) -> Kafka -> Worker -> Fabric -> DB(Verified))"
elif [[ "$STATUS" == "PENDING" ]]; then
    echo "⚠️  WARNING! Product status is still PENDING."
    echo "   (Worker might be slow or stuck, or Kafka consumer not reading)"
else
    echo "❌ FAILED! Status is $STATUS or request failed."
fi
echo "----------------------------------------------------------------"
