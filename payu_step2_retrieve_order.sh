#!/bin/bash
TOKEN=$1
ORDER_ID=$2

echo ">>> Retrieving order $ORDER_ID..."
curl -s "https://secure.snd.payu.com/api/v2_1/orders/${ORDER_ID}" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -m json.tool