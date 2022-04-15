# -*- coding: utf-8 -*-
*** Settings ***
Documentation      Orders robots from RobotSpareBin Industries Inc.
Library     RPA.Browser.Selenium
Library     RPA.HTTP
Library     RPA.Tables
Library     RPA.Dialogs
Library     RPA.PDF
Library     RPA.FileSystem
Library     RPA.Archive
Library     RPA.Robocloud.Secrets
Library     RPA.Robocorp.Vault
Variables   variables.py

*** Variables ***
#${url}            ${secret}[url]
#${input_url}       https://robotsparebinindustries.com/orders.csv
${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}  ${CURDIR}${/}output
${input_files}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_archive.zip

*** Keywords ***
Cleanup
    Log To Console      Cleaning up files from directory of previous robot run
    Empty Directory     ${img_folder}
    Empty Directory     ${pdf_folder}
    Empty Directory     ${output_folder}
    
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
    Create Directory    ${output_folder}

# +
*** Keywords ***
Ask user for the CSV File
    # Create Form     Please provide Orders file link    
    #Add Text Input    Orders File Link    csvFileLink   
    #&{response}   Request Response    
    #Log     ${response}    
    #[Return]    ${response["csvFileLink"]}  
 
    Add heading   User Input Dialog
    Add text input    input_file_url    label= Please Enter Input File URL
    ${response}=    Run dialog
    Log     ${response}
    [Return]    ${response.input_file_url}

Download input csv file
    ${input_url}=      Ask user for the CSV File
    Download    url=${input_url}  target_file=${input_files}   overwrite=True
    ${input_table}=    Read table from CSV    path=${input_files}    header=True
    [Return]    ${input_table}
    

# -

*** Keywords ***
Open the robot order website
    Open Available Browser    ${URL}
    Maximize Browser Window

*** Keywords ***
Close the annoying model
   Click Button    OK

*** Keywords ***
Fill the form
    [Arguments]     ${myrow}
    Wait Until Element Is Visible    head
    Wait Until Element Is Enabled    head
    Select From List By Value    head    ${myrow}[Head]
    
    Wait Until Element Is Enabled    body
    Select Radio Button    body    ${myrow}[Body]
    
    Wait Until Element Is Enabled    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${myrow}[Legs]
    
    Wait Until Element Is Enabled    //*[@id="address"]
    Input Text    //*[@id="address"]    ${myrow}[Address]

*** Keywords ***
Preview the robot
    Click Button   //*[@id="preview"]
    Wait Until Element Is Visible   //*[@id="robot-preview-image"] 

*** Keywords ***
Submit the order
    Click Button   //*[@id="order"]
    Page Should Contain Element    //*[@id="receipt"]

*** Keywords ***
Take a screenshot of each of the ordered robots
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]   #robot_preview_image
    Wait Until Element Is Visible    xpath:/html/body/div/div/div[1]/div/div[1]/div/div/p[1]   #order_id
    
    #Get order id of order

    ${order_id}=    Get Text    //*[@id="receipt"]/p[1]         #order_id
    Log    ${order_id}
    
    #Create screenshot file name
    Set Local Variable    ${screenshot_file_name}    ${img_folder}${/}${order_id}.png
    Sleep    2sec
    Log    Capturing robot screenshot to ${screenshot_file_name}
    Capture Element Screenshot    //*[@id="robot-preview-image"]    ${screenshot_file_name}
    [Return]    ${order_id}  ${screenshot_file_name}

*** Keywords ***
Store the receipt as a PDF file    
    [Arguments]        ${ORDER_NUMBER}
    Wait Until Element Is Visible   //*[@id="receipt"]
    Log                             Printing ${ORDER_NUMBER}
    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML
    Set Local Variable              ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf
    Html To Pdf                     content=${order_receipt_html}   output_path=${fully_qualified_pdf_filename}
    [Return]    ${fully_qualified_pdf_filename}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${IMG_FILE}     ${PDF_FILE}
    Log      Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}
    Open PDF        ${PDF_FILE}
    # Create the list of files that is to be added to the PDF (here, it is just one file)
    @{myfiles}=       Create List     ${IMG_FILE}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF_FILE}      ${PDF_FILE}

*** Keywords ***   
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${IMG_FILE}     ${PDF_FILE}
    Log      Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}
    Open PDF        ${PDF_FILE}
    # Create the list of files that is to be added to the PDF (here, it is just one file)
    @{myfiles}=       Create List     ${IMG_FILE}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF_FILE}      ${PDF_FILE}

*** Keywords ***
Go to order another robot
    # Define local variables for the UI elements
    Set Local Variable      ${btn_order_another_robot}      //*[@id="order-another"]
    Click Button            ${btn_order_another_robot}

*** Keywords ***  
Log Out And Close The Browser
    Close Browser

*** Keywords ***     
Create a ZIP archive of the PDF receipts
    Archive Folder With Zip      ${pdf_folder}    ${zip_file}

*** Keywords ***  
Display the success dialog
    [Arguments]   ${USER_NAME}
    Add icon      Success
    Add heading   Your orders have been processed
    Add text      Dear ${USER_NAME} - all orders have been processed. Have a nice day!
    Run dialog    title=Success
    #Close dialog

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    Cleanup
    Download input csv file

    Log    ${URL}
    Log    ${USER_NAME}
        
    Open the robot order website
    
    ${orders}=   Download input csv file
    FOR    ${row}    IN    @{orders}
        Close the annoying model
        Fill the form    ${row}
        Wait Until Keyword Succeeds     10x     2s    Preview the robot
        Wait Until Keyword Succeeds     10x     2s    Submit The Order
        ${order_id}  ${img_filename}=    Take a screenshot of each of the ordered robots
        ${pdf_filename}=    Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file     IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
        
    END
    Create a ZIP archive of the PDF receipts   
    Log Out And Close The Browser
    Display the success dialog  USER_NAME=${username}
