*** Settings ***
Documentation       Order robots from robotsparebin industries
...                 Save the receipt HTML in a pdf file
...                 Take screenshot of robot and attach in pdf file
...                 Zip the all receipts

Library             RPA.Browser
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.HTTP
Library             RPA.Archive
Library             Dialogs
Library             RPA.Robocloud.Secrets
Library             RPA.core.notebook
# 1. Open the website
# 2. Open a dialogbox asking for the url of csv file
# 3. Use the csv file and each row to create the robot details in website
# 4. After dataentry operations, save the reciept in pdf file format
# 5. Take the screenshot of the robot and add it to a pdf file.
# 6. Zip all receipts in output directory
# 7. Close the website


*** Tasks ***
Order Processing Bot
    Intializing steps
    Download the csv file
    ${data}=    Read the order file
    Open the website
    Processing the orders    ${data}
    Zip the receipts folder
    [Teardown]    Close Browser


*** Keywords ***
Open the website
    ${website}=    Get Secret    websitedata
    Open Available Browser    ${website}[url]
    Maximize Browser Window

# +

Remove and add empty directory
    [Arguments]    ${folder}
    Remove Directory    ${folder}    True
    Create Directory    ${folder}

# -

Intializing steps
    ${reciept_folder}=    Does Directory Exist    ${CURDIR}${/}receipts
    ${robots_folder}=    Does Directory Exist    ${CURDIR}${/}robots
    IF    '${reciept_folder}'=='True'
        Remove and add empty directory    ${CURDIR}${/}receipts
    ELSE
        Create Directory    ${CURDIR}${/}receipts
    END
    IF    '${robots_folder}'=='True'
        Remove and add empty directory    ${CURDIR}${/}robots
    ELSE
        Create Directory    ${CURDIR}${/}robots
    END

Read the order file
    ${data}=    Read Table From Csv    ${CURDIR}${/}orders.csv    header=True
    RETURN    ${data}

Data Entry for each order
    [Arguments]    ${row}
    Wait Until Page Contains Element    //button[@class="btn btn-dark"]
    Click Button    //button[@class="btn btn-dark"]
    Select From List By Value    //select[@name="head"]    ${row}[Head]
    Click Element    //input[@value="${row}[Body]"]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    //input[@placeholder="Shipping address"]    ${row}[Address]
    Click Button    //button[@id="preview"]
    Wait Until Page Contains Element    //div[@id="robot-preview-image"]
    Sleep    5 seconds
    Click Button    //button[@id="order"]
    Sleep    5 seconds

Close and start Browser prior to another transaction
    Close Browser
    Open the website
    Continue For Loop

Checking Receipt data processed or not
    FOR    ${i}    IN RANGE    ${100}
        ${alert}=    Is Element Visible    //div[@class="alert alert-danger"]
        IF    '${alert}'=='True'    Click Button    //button[@id="order"]
        IF    '${alert}'=='False'    BREAK
    END

    IF    '${alert}'=='True'
        Close and start Browser prior to another transaction
    END

Processing Receipts in final
    [Arguments]    ${row}
    Sleep    5 seconds
    ${reciept_data}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
    Html To Pdf    ${reciept_data}    ${CURDIR}${/}receipts${/}${row}[Order number].pdf
    Screenshot    //div[@id="robot-preview-image"]    ${CURDIR}${/}robots${/}${row}[Order number].png
    Add Watermark Image To Pdf
    ...    ${CURDIR}${/}robots${/}${row}[Order number].png
    ...    ${CURDIR}${/}receipts${/}${row}[Order number].pdf
    ...    ${CURDIR}${/}receipts${/}${row}[Order number].pdf
    Click Button    //button[@id="order-another"]

Processing the orders
    [Arguments]    ${data}
    FOR    ${row}    IN    @{data}
        Data Entry for each order    ${row}
        Checking Receipt data processed or not
        Processing Receipts in final    ${row}
    END

# +

Download the csv file
    ${file_url}=    Get Value From User
    ...    Please enter the csv file url
    ...    https://robotsparebinindustries.com/orders.csv
    Download    ${file_url}    orders.csv    overwrite=True
    Sleep    2 seconds

# -

Zip the receipts folder
    Archive Folder With Zip    ${CURDIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip
