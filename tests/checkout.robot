*** Settings ***
Library           Browser
Library           DateTime
Suite Setup       New Browser    chromium    headless=${HEADLESS}    channel=chrome    slowMo=${SLOW_MO}
Suite Teardown    Close Browser
Test Setup        New Context
Test Teardown     Finish Test

*** Variables ***
# ---------- Settings ----------
${HEADLESS}              ${False}
${BASE_URL}              https://aptest.29next.store
# Pause added after every browser action.
${SLOW_MO}               300ms
# How long the browser stays open after each test that can look at the page.
${END_PAUSE}             5s

# ---------- Test data ----------
${FIRST_NAME}            Chattramongkon
${LAST_NAME}             Test
${ADDRESS}               234 Test Ave
${CITY}                  Henderson
${STATE_NAME}            Kentucky
${STATE_CODE}            KY
${ZIP_CODE}              42301
${PHONE_NUMBER}          (201) 555-0123
${CARD_NAME}             Test User
${CARD_NUMBER}           6011111111111117
${BAD_CARD_NUMBER}       1234567812345678
${CARD_EXPIRY}           08/30
${CARD_MONTH}            08
${CARD_YEAR}             2030
${CARD_CVV}              123

# ---------- Locators: store pages ----------
${PRODUCT_LINK}          css=a[href*="/catalogue/"][href*="_"]:not([href*="category"]) >> nth=0
${ADD_TO_CART_BUTTON}    css=form#add-to-cart >> text=Add to cart
${POPUP_CLOSE_BUTTON}    css=button.klaviyo-close-form >> nth=0

# ---------- Locators: checkout form ----------
${EMAIL_FIELD}           css=input[type="email"]:visible, input[id="id_email"], input[name="email"], input[placeholder="Email Address"] >> nth=0
${FIRST_NAME_FIELD}      id=id_shipping-address-first_name
${LAST_NAME_FIELD}       css=input[name="shipping-address-last_name"]
${PHONE_FIELD}           css=input[name="shipping-address-phone_number"]
${COUNTRY_FIELD}         css=select[name="shipping-address-country"]
${ADDRESS_FIELD}         id=id_shipping-address-line1
${CITY_FIELD}            css=input[name="shipping-address-line4"], input[name="shipping-address-city"] >> nth=0
${STATE_FIELD}           css=select[name="shipping-address-state"], input[name="shipping-address-state"] >> nth=0
${ZIP_FIELD}             css=input[name="shipping-address-postcode"]

# ---------- Locators: credit card ----------
${CARD_NAME_FIELD}       css=input[autocomplete="cc-name"], input[name="full_name"] >> nth=0
${CARD_NUMBER_IFRAME}    css=iframe[id*="number" i], iframe[name*="number" i], iframe[title*="number" i], iframe[src*="number" i] >> nth=0
${CARD_CVV_IFRAME}       css=iframe[id*="cvv" i], iframe[name*="cvv" i], iframe[title*="cvv" i], iframe[src*="cvv" i] >> nth=0
${CARD_EXPIRY_FIELD}     css=input[autocomplete="cc-exp"], input[name*="expir" i] >> nth=0
${CARD_MONTH_FIELD}      css=input[name="month"], input[name*="exp_month" i], input[name*="expiry_month" i] >> nth=0
${CARD_YEAR_FIELD}       css=input[name="year"], input[name*="exp_year" i], input[name*="expiry_year" i] >> nth=0

# ---------- Locators: buttons and results ----------
${CARD_ERROR_MESSAGE}    css=#spreedly-error-block .notification-danger
${PLACE_ORDER_BUTTON}    role=button[name=/place order|complete order|pay now|submit order/i]

*** Test Cases ***
TC01 Order Is Created With Valid Details
    [Documentation]    Happy path: valid shipping details + valid card = order created.
    Add Product To Cart
    Go To Checkout
    Fill Shipping Details    last_name=${LAST_NAME}
    Fill Card Details    ${CARD_NUMBER}
    Place Order
    Order Should Be Created
    Click to Continue Shopping

TC02 Order Is Rejected When Last Name Is Missing
    [Documentation]    Negative: last name is empty, so no order is created and the cursor jumps to that box.
    Add Product To Cart
    Go To Checkout
    Fill Shipping Details    last_name=${EMPTY}
    Fill Card Details    ${CARD_NUMBER}
    Place Order
    Order Should Be Rejected
    Last Name Box Should Be Focused And Empty

TC03 Order Is Rejected When Card Number Is Invalid
    [Documentation]    Negative: an invalid card number shows an error and no order is created.
    Add Product To Cart
    Go To Checkout
    Fill Shipping Details    last_name=${LAST_NAME}
    Fill Card Details    ${BAD_CARD_NUMBER}
    Place Order
    Invalid Card Message Should Be Shown
    Order Should Be Rejected

*** Keywords ***
Finish Test
    [Documentation]    Keep the window open for a moment, then close it.
    Sleep    ${END_PAUSE}
    Close Context

Close Popup If Shown
    [Documentation]    The store shows a marketing popup that blocks clicks. Close it if it appears.
    TRY
        Wait For Elements State    ${POPUP_CLOSE_BUTTON}    visible    timeout=2s
        Click    ${POPUP_CLOSE_BUTTON}
    EXCEPT
        Log    No popup this time
    END

Add Product To Cart
    New Page    ${BASE_URL}/catalogue/
    Close Popup If Shown
    Click    ${PRODUCT_LINK}
    Wait For Elements State    ${ADD_TO_CART_BUTTON}    visible
    Close Popup If Shown
    Click    ${ADD_TO_CART_BUTTON}
    Sleep    2s    reason=wait for the cart to update

Go To Checkout
    Go To    ${BASE_URL}/checkout/
    Wait For Elements State    ${FIRST_NAME_FIELD}    visible
    Close Popup If Shown

Fill Shipping Details
    [Arguments]    ${last_name}
    # The store needs a unique email for every order, so I add the current time for it.
    ${now}=    Get Current Date    result_format=%Y%m%d%H%M%S
    ${email}=    Set Variable    dev+uat${now}@29next.com
    Set Test Variable    ${EMAIL_USED}    ${email}
    Fill Text    ${EMAIL_FIELD}         ${email}
    Press Keys    ${EMAIL_FIELD}    Tab
    Sleep    1s    reason=let the page react to the email
    Get Property    ${EMAIL_FIELD}    value    ==    ${email}
    Fill Text    ${FIRST_NAME_FIELD}    ${FIRST_NAME}
    Fill Text    ${LAST_NAME_FIELD}     ${last_name}
    Fill Text    ${PHONE_FIELD}         ${PHONE_NUMBER}
    ${has_country}=    Get Element Count    ${COUNTRY_FIELD}
    IF    ${has_country} > 0
        Select Options By    ${COUNTRY_FIELD}    value    US
        Sleep    1s    reason=the page may update after the country changes
    END
    Fill Text    ${ADDRESS_FIELD}       ${ADDRESS}
    Fill Text    ${CITY_FIELD}          ${CITY}
    # State can be a dropdown or a text box, so check which one it is.
    ${tag}=    Get Property    ${STATE_FIELD}    tagName
    IF    $tag == 'SELECT'
        Select Options By    ${STATE_FIELD}    label    ${STATE_NAME}
    ELSE
        Fill Text    ${STATE_FIELD}    ${STATE_NAME}
    END
    Fill Text    ${ZIP_FIELD}           ${ZIP_CODE}

Fill Card Details
    [Arguments]    ${card_number}
    ${has_name}=    Get Element Count    ${CARD_NAME_FIELD}
    IF    ${has_name} > 0
        Fill Text    ${CARD_NAME_FIELD}    ${CARD_NAME}
    END

    Wait For Elements State    ${CARD_NUMBER_IFRAME}    visible    timeout=30s
    Wait For Elements State    ${CARD_CVV_IFRAME}       visible    timeout=30s
    
    Type Text    ${CARD_NUMBER_IFRAME} >>> css=input    ${card_number}    delay=50ms
    Type Text    ${CARD_CVV_IFRAME} >>> css=input       ${CARD_CVV}       delay=50ms
    Fill Card Expiry

Click to Continue Shopping
    [Documentation]    Click a Continue Shopping button.
    Click    css=a.button-next_link
    Get Url    ==    ${BASE_URL}/

Fill Card Expiry
    [Documentation]    Expiry is either one box (MM/YY) or two boxes (month and year).
    ${one_box}=    Get Element Count    ${CARD_EXPIRY_FIELD}
    IF    ${one_box} > 0
        Type Text    ${CARD_EXPIRY_FIELD}    ${CARD_EXPIRY}    delay=50ms
    ELSE
        Fill Text    ${CARD_MONTH_FIELD}    ${CARD_MONTH}
        Fill Text    ${CARD_YEAR_FIELD}     ${CARD_YEAR}
    END

Place Order
    Close Popup If Shown
    # Safety check: the page must still show our email, otherwise the store refuses the order.
    ${current_email}=    Get Property    ${EMAIL_FIELD}    value
    IF    '${current_email}' == ''
        Log    Email box was empty before placing the order, filling it again    level=WARN
        Fill Text    ${EMAIL_FIELD}    ${EMAIL_USED}
        Press Keys    ${EMAIL_FIELD}    Tab
        Sleep    1s
    END
    Click    ${PLACE_ORDER_BUTTON}

Order Should Be Created
    [Documentation]    After a successful order the store shows the order-status page with the order number and our email.
    ${old_retry}=    Set Retry Assertions For    30s
    TRY
        Get Url    contains    /order-status/
        Get Text    css=body    contains    Order #
        Get Text    css=body    contains    ${EMAIL_USED}
        Take Screenshot    filename=order-confirmed
    EXCEPT
        ${url}=    Get Url
        ${page_text}=    Get Text    css=body
        Take Screenshot    filename=order-not-created
        Log To Console    \nURL: ${url}\nPAGE TEXT:\n${page_text}
        Fail    Order was not created. Browser is still on ${url}
    FINALLY
        Set Retry Assertions For    ${old_retry}
    END

Order Should Be Rejected
    [Documentation]    No order was created: the browser is still on the checkout page.
    Sleep    3s    reason=give the page time to react
    Get Url    contains    /checkout
    Get Text    css=body    not contains    Order #
    Take Screenshot    filename=order-rejected-{index}

Invalid Card Message Should Be Shown
    Wait For Elements State    ${CARD_ERROR_MESSAGE}    visible    timeout=15s
    Get Text    ${CARD_ERROR_MESSAGE}    contains    Invalid card number

Last Name Box Should Be Focused And Empty
    [Documentation]    The store shows no message. It moves the cursor to the empty required last name box.
    ${active_name}=    Evaluate JavaScript    ${None}    () => document.activeElement.name
    Should Be Equal    ${active_name}    shipping-address-last_name
    ${empty_and_required}=    Evaluate JavaScript    ${LAST_NAME_FIELD}    (el) => el.required && el.value === ''
    Should Be True    ${empty_and_required}
