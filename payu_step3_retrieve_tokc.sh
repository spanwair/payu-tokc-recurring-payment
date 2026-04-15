#!/bin/bash

source .env

# Get trusted_merchant token (scoped to the customer)
RESPONSE=$(curl -s -X POST "https://secure.snd.payu.com/pl/standard/user/oauth/authorize" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=trusted_merchant" \
  -d "client_id=${POS_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "email=${EXT_EMAIL}" \
  -d "ext_customer_id=${EXT_CUSTOMER_ID}")

echo "RESPONSE=$RESPONSE"

TM_TOKEN=$(echo $RESPONSE | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

# Fetch stored payment methods (includes TOKC_)
# curl -s -X GET "https://secure.snd.payu.com/api/v2_1/paymethods" \
#   -H "Authorization: Bearer $TM_TOKEN" \
#   | python3 -m json.tool

curl -s -X GET "https://secure.snd.payu.com/api/v2_1/paymethods" \
  -H "Authorization: Bearer $TM_TOKEN" \
  | grep -o '"value":"TOKC_[^"]*"' | cut -d'"' -f4