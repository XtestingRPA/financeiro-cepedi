*** Settings ***
Library    RPA.PDF
Library    String
Library    RPA.Browser.Selenium
Library    DateTime


*** Variables ***

${url_conexa}                         https://hubbsalvador.conexa.app/index.php?r=site/login
${login_conexa}                       vanderleia
${senha_conexa}                       Financeiro@2026
${form_login_conexa}                  css:form[id="login-form"]
${input_login_conexa}                 css:input[id="LoginForm_username"]
${input_senha_conexa}                 css:input[id="LoginForm_password"]
${button_login_conexa}                css:button[id="loginButton"]
${modal_conexa}                       css:a[class="btn btn btn-fechar"]
${button_menu_financeiro}             css:li[class="dropdown menu-financeiro"]
${button_contas_a_receber}            css:a[href="/index.php?r=cobranca/admin"]
${button_busca_avancada}              css:button[class="btn btn-secondary label-left busca-avancada"]
${input_cobranca_data_inicial}        css:input[id="Cobranca_date_first"]
${input_cobranca_data_final}          css:input[id="Cobranca_date_last"]
${data_dia1}                          xpath=//a[@class="ui-state-default" and text()="1"]
${seletor_mes}                        css:select[class="ui-datepicker-month"]
${seletor_ano}                        css:select[class="ui-datepicker-year"]
${button_filtrar}                     css:button[class="btn btn-primary"]
${checkbox_cobranca}                  css:input[id="cobranca-grid_c0_all"]
${button_acoes_em_lote}               css:a[class="btn dropdown-toggle"]
${button_download}                    css:a[onclick="javascript:vueApp.displayModal()"]
${button_continuar}                   css:button[class="btn btn-close btn-primary"]

*** Tasks ***
Processo CEPEDI
    Operação Conexa
    # Extrair Dados Boletos


*** Keywords ***
Operação Conexa
    [Documentation]    Loga no site da Conexa e realiza o download dos boletos.

    # Realiza o login no site Coneza
    Open Browser    ${url_conexa}    browser=chrome
    Maximize Browser Window
    Wait Until Element Is Visible    ${form_login_conexa}
    Input Text    ${input_login_conexa}    ${login_conexa}
    Input Text    ${input_senha_conexa}    ${senha_conexa}
    Click Element    ${button_login_conexa}
    
    # Fecha o modal.
    ${visivel}    Run Keyword And Return Status    Wait Until Element Is Visible    ${modal_conexa}    timeout=3s

    IF    ${visivel}
        Click Element    ${modal_conexa}
    END

    # Vai até a página contas a receber
    Mouse Over    ${button_menu_financeiro}
    Sleep    2s
    Wait Until Element Is Visible    ${button_menu_financeiro}
    Click Element    ${button_menu_financeiro}
    Sleep    2s
    Scroll Element Into View    ${button_contas_a_receber}
    Wait Until Element Is Visible    ${button_contas_a_receber}
    Click Element    ${button_contas_a_receber}

    # Realiza a filtragem dos boletos
    Wait Until Element Is Visible    ${button_busca_avancada}
    Click Element    ${button_busca_avancada}
    Sleep    1s
    Scroll Element Into View    ${input_cobranca_data_inicial}
    Click Element    ${input_cobranca_data_inicial}
    Lógica Data
    Click Element    ${data_dia1}
    Click Element    ${input_cobranca_data_final}
    ${data_ultimo_dia_mes}    Set Variable    xpath=//td[not(contains(@class,"ui-datepicker-other-month"))]//a[normalize-space(.)="${ultimo_dia_mes}"]
    Wait Until Element Is Visible    ${data_ultimo_dia_mes}    15s
    Click Element    ${data_ultimo_dia_mes}
    Wait Until Element Is Visible    ${button_filtrar}
    Click Element    ${button_filtrar}

    # Seleciona todos os boletos filtrados (de uma só vez) e faz o download dos mesmos.
    Wait Until Element Is Visible    ${checkbox_cobranca}    15s
    Click Element    ${checkbox_cobranca}
    Click Element    ${button_acoes_em_lote}
    Click Element    ${button_download}

    ${visivel}    Run Keyword And Return Status    Wait Until Element Is Visible    ${button_continuar}    timeout=3s

    IF    ${visivel}
        Click Element    ${button_continuar}
    END    
Extrair Dados Boleto
    [Documentation]    Realiza a leitura e extração de dados dos boletos.
    Open Pdf    boletoteste.pdf

    ${texto_dict}    Get Text From Pdf
    Close Pdf

    ${texto}    Set Variable    ${EMPTY}
    FOR    ${pagina}    IN    @{texto_dict.values()}
        ${texto}    Catenate    SEPARATOR=\n    ${texto}    ${pagina}
    END

    Log    ${texto}

    # Número do documento
    ${doc_full}    Get Regexp Matches    ${texto}    (\\d{4})\\d{10,}\\d{2}/\\d{2}/\\d{4}    
    IF    ${doc_full}
    ${doc}    Get Substring    ${doc_full[0]}    0    4
    ELSE
        ${doc}    Set Variable    NAO_ENCONTRADO
    END
    

    # Valor do boleto
    ${valores}    Get Regexp Matches    ${texto}    \\d{1,3}(?:\\.\\d{3})*,\\d{2}
    ${valor}    Set Variable    ${valores}[-1]    
    
    # Nome do pagador
    ${pagador}    Get Regexp Matches    ${texto}    (?i)Pagador\\s*(?:\\[[^\\]]+\\]\\s*)?[\\r\\n]+(?:\\[[^\\]]+\\]\\s*)?([^\\r\\n]+)
    ${pagador}    Set Variable    ${pagador}[1]
    
    ${pagador}    Replace String    ${pagador}    Pagador    ${EMPTY}
    ${pagador}    Strip String    ${pagador}
  

    Log    Documento:${doc}
    Log    Valor:${valor}
    Log    Pagador:${pagador}

Lógica Data 
    [Documentation]    Lógica para pegar o último dia do mês atua e conferir se o mês e ano selecionados estão corretos.

    ${hoje}          Get Current Date
    ${primeiro_dia}  Convert Date    ${hoje}    result_format=%Y-%m-01
    ${proximo_mes}   Add Time To Date    ${primeiro_dia}    32 days
    ${primeiro_prox}    Convert Date    ${proximo_mes}    result_format=%Y-%m-01
    ${ultimo_dia_mes}    Subtract Time From Date    ${primeiro_prox}    1 day    result_format=%d
    Set Global Variable    ${ultimo_dia_mes}

    ${ano_atual}        Get Current Date    result_format=%Y
    ${mes_atual_label}  Get Current Date    result_format=%b

    ${mes_selecionado}    Get Selected List Label    ${seletor_mes}
    ${ano_selecionado}    Get Selected List Value    ${seletor_ano}

    # Ajusta ano
    IF    '${ano_selecionado}' != '${ano_atual}'
        Select From List By Value    ${seletor_ano}    ${ano_atual}
    END

    # Ajusta mês
    IF    '${mes_selecionado}' != '${mes_atual_label}'
        Select From List By Label    ${seletor_mes}    ${mes_atual_label}
    END

