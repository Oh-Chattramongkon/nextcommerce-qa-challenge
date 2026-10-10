# Next Commerce QA Code Challenge

Automated UAT checkout tests for https://aptest.29next.store using **Robot Framework + Browser library (Playwright)**.

## Test cases (`tests/checkout.robot`)
| ID | Type | What it checks |
|----|------|----------------|
| TC01 | Positive | Valid shipping details + valid credit card -> order is created |
| TC02 | Negative | Last name missing -> order is NOT created and the cursor jumps to the last name box |
| TC03 | Negative | Invalid card number -> "Invalid card number" message shown, order is NOT created |

## Setup
Requires Python 3, Node.js and Google Chrome.

    python3 -m venv .venv && source .venv/bin/activate
    pip install -r requirements.txt
    rfbrowser init

## Run
    robot -d results tests/                      # run everything (browser visible)
    robot -d results -v HEADLESS:True tests/     # run without opening a window
    robot -d results -t "TC01*" tests/           # run one test

Reports: `results/report.html` and `results/log.html`.

## Notes
- Everything is in one file: data, locators, tests and keywords.
- A unique email (`dev+uat<timestamp>@29next.com`) is generated for each order because the store requires unique emails.
- Negative tests check that no order was created (still on /checkout, no order number). TC02 also checks that focus moves to the empty last name box, because the store shows no message for it.
