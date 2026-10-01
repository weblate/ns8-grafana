*** Settings ***
Library    SSHLibrary
Resource    api.resource

*** Variables ***
${ADMIN_USER}    admin
${ADMIN_PASSWORD}    Nethesis,1234
${SCENARIO}    install
${grafana_host}    grafana.dom.test
${grafana_url}    https://127.0.0.1
${grafana_auth}    admin:admin

*** Keywords ***
Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${ADMIN_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${ADMIN_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

Add module
    [Arguments]    ${image}
    ${output}  ${rc} =    Execute Command    add-module ${image} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    RETURN    ${output}

Grafana API
    [Arguments]    ${path}    ${method}=GET    ${body}=${EMPTY}    ${auth}=${grafana_auth}
    ${data} =    Set Variable If    '''${body}''' != ''    -H "Content-Type: application/json" -d '${body}'    ${EMPTY}
    ${out} =    Execute Command    curl -sk -X ${method} -u '${auth}' -H "Host: ${grafana_host}" ${data} ${grafana_url}${path}
    ${response} =    Evaluate    json.loads($out)    modules=json
    RETURN    ${response}

Grafana is healthy
    ${health} =    Grafana API    /api/health
    Should Be Equal    ${health['database']}    ok

The admin logs in
    ${user} =    Grafana API    /api/user
    Should Be Equal    ${user['login']}    admin
    ${code} =    Execute Command    curl -sk -o /dev/null -w "\%{http_code}" -u admin:wrong-password -H "Host: ${grafana_host}" ${grafana_url}/api/user
    Should Be Equal    ${code}    401

The dashboard is stored
    ${response} =    Grafana API    /api/dashboards/uid/upgradetest
    Should Be Equal    ${response['dashboard']['title']}    Upgrade test

*** Test Cases ***
Check if grafana is installed correctly
    # The update scenario starts from the NS8 stable release, then upgrades it below.
    # grafana is published in NethForge, which a new node has disabled.
    IF    '${SCENARIO}' == 'update'
        Run task    cluster/alter-repository    {"name":"nethforge","status":true}
        ${output} =    Wait Until Keyword Succeeds    5 times    10 seconds    Add module    grafana
    ELSE
        ${output} =    Add module    ${IMAGE_URL}
    END
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if grafana can be configured
    Run task    module/${module_id}/configure-module    {"host":"${grafana_host}","http2https":false,"lets_encrypt":false}
    ${config} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${config['host']}    ${grafana_host}

Check if grafana works as expected
    Wait Until Keyword Succeeds    30 times    5 seconds    Grafana is healthy
    The admin logs in

Create a dashboard
    ${response} =    Grafana API    /api/dashboards/db    POST    {"dashboard":{"uid":"upgradetest","title":"Upgrade test","panels":[]},"overwrite":false}
    Should Be Equal    ${response['status']}    success
    The dashboard is stored

Update grafana to the image under test
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    ${rc} =    Execute Command
    ...    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check grafana works after the update
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    Wait Until Keyword Succeeds    30 times    5 seconds    Grafana is healthy
    The admin logs in
    ${config} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${config['host']}    ${grafana_host}

Check the dashboard survives the update
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    The dashboard is stored

Take screenshots
    [Tags]    ui
    Import Library    Browser
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True
    Login to cluster-admin
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}
    Wait For Elements State    iframe >>> h2 >> text="Status"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/1._Status.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=settings
    Wait For Elements State    iframe >>> h2 >> text="Settings"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/2._Settings.png
    Close Browser

Check if grafana is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
