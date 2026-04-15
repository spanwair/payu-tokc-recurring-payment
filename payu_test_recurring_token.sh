#!/bin/bash

source .env

echo "$POS_ID"

TOKEN=$(curl -s -X POST "https://secure.snd.payu.com/pl/standard/user/oauth/authorize" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${POS_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

echo "TOKEN=$TOKEN"

RESPONSE=$(curl -s -X POST "https://secure.snd.payu.com/api/v2_1/orders" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  --no-location \
  -d '{
    "notifyUrl": "https://random1776157771099.com/notify",
    "customerIp": "127.0.0.1",
    "merchantPosId": "'"${POS_ID}"'",
    "recurring": "FIRST",
    "description": "Test subscription",
    "currencyCode": "CZK",
    "totalAmount": "1000",
    "extOrderId": "test-rec-'"$(date +%s)"'",
    "products": [{ "name": "Monthly subscription", "unitPrice": "1000", "quantity": "1" }],
    "buyer": { "extCustomerId": "'"${EXT_CUSTOMER_ID}"'", "email": "'"${EXT_EMAIL}"'", "firstName": "John", "lastName": "Doe", "language": "en" },
    "payMethods": {
      "payMethod": {
        "value": "'"${TOK_TOKEN}"'",
        "type": "CARD_TOKEN"
      }
    },
    "threeDsAuthentication": { "recurring": { "frequency": "30", "expiry": "2027-12-31T00:00:00Z" } }
  }')

ORDER_ID=$(echo $RESPONSE | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)
REDIRECT=$(echo $RESPONSE | grep -o '"redirectUri":"[^"]*"' | cut -d'"' -f4)

echo ""
echo "ORDER_ID=$ORDER_ID"
echo ""
echo ">>> Open this URL in your browser and complete 3DS:"
echo "$REDIRECT"
echo ""
echo ">>> Then run: bash payu_step2_retrieve.sh $TOKEN $ORDER_ID"
