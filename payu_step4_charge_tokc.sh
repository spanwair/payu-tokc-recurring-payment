#!/bin/bash
# Step 4 — Charge a TOKC_ token (recurring STANDARD, no user interaction needed)
# Usage: bash payu_step4_charge_tokc.sh
# Reads TOKC_TOKEN and CHARGE_AMOUNT from .env

source .env

AMOUNT="${CHARGE_AMOUNT:-1000}"   # default 10.00 CZK (amounts are in lowest denomination)

echo "POS_ID=$POS_ID"
echo "TOKC_TOKEN=$TOKC_TOKEN"
echo "CHARGE_AMOUNT=$AMOUNT"
echo ""

# 1. Get client_credentials bearer token
TOKEN=$(curl -s -X POST "https://secure.snd.payu.com/pl/standard/user/oauth/authorize" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${POS_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "ERROR: Could not obtain bearer token. Check POS_ID / CLIENT_SECRET."
  exit 1
fi
echo "TOKEN=$TOKEN"
echo ""

# 2. Create STANDARD recurring order — no 3DS, no redirect, pure server-side
RESPONSE=$(curl -s -X POST "https://secure.snd.payu.com/api/v2_1/orders" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  --no-location \
  -d '{
    "notifyUrl": "https://random1776157771099.com/notify",
    "customerIp": "127.0.0.1",
    "merchantPosId": "'"${POS_ID}"'",
    "recurring": "STANDARD",
    "description": "Recurring charge",
    "currencyCode": "CZK",
    "totalAmount": "'"${AMOUNT}"'",
    "extOrderId": "std-rec-'"$(date +%s)"'",
    "products": [{ "name": "Recurring charge", "unitPrice": "'"${AMOUNT}"'", "quantity": "1" }],
    "buyer": { "extCustomerId": "'"${EXT_CUSTOMER_ID}"'", "email": "'"${EXT_EMAIL}"'", "firstName": "John", "lastName": "Doe", "language": "en" },
    "payMethods": {
      "payMethod": {
        "value": "'"${TOKC_TOKEN}"'",
        "type": "CARD_TOKEN"
      }
    }
  }')

echo "RAW_RESPONSE=$RESPONSE"
echo ""

ORDER_ID=$(echo "$RESPONSE" | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)
STATUS=$(echo "$RESPONSE"   | grep -o '"status":{"statusCode":"[^"]*"' | grep -o '"statusCode":"[^"]*"' | cut -d'"' -f4)
STATUS_DESC=$(echo "$RESPONSE" | grep -o '"statusDesc":"[^"]*"' | cut -d'"' -f4)

echo "ORDER_ID=$ORDER_ID"
echo "STATUS=$STATUS"
echo "STATUS_DESC=$STATUS_DESC"
