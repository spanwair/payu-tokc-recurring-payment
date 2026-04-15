# Tutorial

## Dev Server (dummy_server) — Quick Start

### Prerequisites

- [Node.js](https://nodejs.org/) v14 or newer (no npm install needed — uses only built-in modules)

### Setup

1. Copy the example env file and fill in your credentials:

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and set `POS_ID` and `CLIENT_SECRET` from your PayU sandbox shop.

2. Start the server:

   ```bash
   node dummy_server/server.js
   ```

3. Open **http://localhost:3001** in your browser.

### What it does

The UI walks you through the full TOKC flow in three steps:

| Step | Action                                                                     |
| ---- | -------------------------------------------------------------------------- |
| 1    | Tokenize a card → get `TOK_TOKEN`                                          |
| 2    | Create an order with that token → get a 3DS redirect URL                   |
| 3    | After completing 3DS in the browser → retrieve the `TOKC_` recurring token |

A sandbox test card cheat sheet is shown directly on the page (copy buttons included).

---

## Sandbox - HOW TO GET TOKC

- shop on the PayU sandbox: https://merch-prod.snd.payu.com/cp/shops_list
- Add to shop POP with Api Resp ! NOT CLASSIC !
- copy POS_ID and CLIENT_SECRET to .env file (replace ... in the "...", example: `CLIENT_SECRET="HERE_WILL_BE_THE_TOKEN"`)
- run server from this folder, for example using http-server (python3 -m http.server), than open url with browser (default: 127.0.0.1:8000)
- to get TOK\_ (payment token), use `mini_payment_card.html` with Challenge card, in the server. From the testing website page: https://developers.payu.com/europe/docs/testing/sandbox/
  (example:
  num: 4245757666349685
  month: 12
  year: 29
  CVV: 123
  Challenge required.
  Positive authorization.
  )
- copy token from the FE to `payu_test_recuiring_token.sh` value `TOK_TOKEN` in `.env` file
- call `payu_test_recurring_token.sh`
- it will retrieve URL (click it) and agree using POSITIVE button
- OPTIONAL - call `payu_step2_retrieve_order.sh` (retrieve order, only check)
- call `payu_step3_retrieve_tokc.sh` >> This will response TOKC which is used for recurring payments

Reference:
TopicURLCharging a TOKC\_ tokenhttps://developers.payu.com/europe/docs/payment-solutions/cards/tokenization/charge-token/Creating tokenshttps://developers.payu.com/europe/docs/payment-solutions/cards/tokenization/create-token/Recurring paymentshttps://developers.payu.com/en/recurring.html
