*** Settings ***
Library      RPA.PDF
Library      String
Library      SeleniumLibrary
Library      DateTime
Library      RPA.Assistant
Library      OperatingSystem
Library      Collections
Variables    variables.yaml


*** Tasks ***
Processo Financeiro CEPEDI
    Operação Conexa
    #Extrair Dados Boleto
    #Operação Easonilo

*** Keywords ***
Operação Conexa
    [Documentation]    Loga no site da Conexa e realiza o download dos boletos.

    # Realiza o login no site Conexa

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
    Lógica Data
    ${elemento}=    Get WebElement    ${button_filtrar}
    Execute Javascript    arguments[0].click();    ARGUMENTS    ${elemento}

    # Seleciona todos os boletos filtrados (de uma só vez) e faz o download dos mesmos.

    Wait Until Element Is Visible    ${checkbox_cobranca}    15s
    Sleep    5s
    Click Element    ${checkbox_cobranca}
    Click Element    ${button_acoes_em_lote}
    Click Element    ${button_download}


    # ${visivel}    Run Keyword And Return Status    Wait Until Element Is Visible    ${button_confirmar}    timeout=3s

    # IF    ${visivel}
    #     Click Element    ${button_confirmar}
    # END    

    Assistente Operação

Assistente Operação
    [Documentation]    Realiza instruções a respeito do download dos boletos.

    Add heading    Ação necessária!
    Add text    Por motivos de segurança, este robô não acessa o seu e-mail.
    
    Add text    Siga os passos abaixo:
    Add text    1. Acesse seu e-mail
    Add text    2. Baixe os boletos recebidos
    Add text    3. Salve os arquivos na pasta "Boletos"

    Add text    Após finalizar, clique em "Continuar" para prosseguir.

    Add submit buttons    buttons=Continuar,Cancelar

    ${resposta}    Run dialog

    IF    "${resposta}" == "Cancelar"
        Fail    Processo cancelado pelo usuário
    END


Extrair Dados Boleto
    [Documentation]    Realiza a leitura e extração de dados dos boletos.

    ${arquivos}    List Files In Directory    path=${CURDIR}/Boletos

    ${boletos}    Create List

    FOR    ${arquivo}    IN    @{arquivos}

        ${caminho_pdf}    Set Variable    ${CURDIR}/Boletos/${arquivo}
        
        Open Pdf    ${caminho_pdf}

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
        ${valor}      Set Variable    ${valores}[-1]

        # Nome do pagador

        ${pagador}    Get Regexp Matches    ${texto}    [^\n\r]*CNPJ[^\n\r]+

        IF    ${pagador}
            ${pagador}        Strip String          ${pagador}[-1]
            ${nome_match}     Get Regexp Matches    ${pagador}        ^(.+?)\\s*-\\s*CNPJ    1
            ${nome_pagador}           Set Variable If       ${nome_match}     ${nome_match}[0]       ${pagador}
        ELSE
            ${pagador}    Set Variable    NAO_ENCONTRADO
            ${nome_pagador}       Set Variable    NAO_ENCONTRADO
        END

        # Vencimento

        ${venc_match}    Get Regexp Matches    ${texto}    Vencimento(\\d{2}/\\d{2}/\\d{4})    1

        IF    ${venc_match}
            ${vencimento}    Set Variable    ${venc_match}[0]
        ELSE
            ${vencimento}    Set Variable    NAO_ENCONTRADO
        END

        IF    ${venc_match}
            ${mes_vencimento}    Get Substring    ${vencimento}    3    5
        ELSE
            ${mes_vencimento}    Set Variable    NAO_ENCONTRADO
        END

        # Data do documento

        ${data_doc_match}    Get Regexp Matches    ${texto}    Data process\\.\\s*\\n\\S+\\s*(\\d{2}/\\d{2}/\\d{4})    1

        IF    ${data_doc_match}
            ${data_doc}    Set Variable    ${data_doc_match}[0]
        ELSE
            ${data_doc}    Set Variable    NAO_ENCONTRADO
        END

        Log    Arquivo: ${arquivo}
        Log    Nome do pagador: ${nome_pagador}
        Log    Documento: ${doc}
        Log    Vencimento: ${vencimento}
        Log    Parcela: ${mes_vencimento}
        Log    Data do documento: ${data_doc}
        Log    Valor: ${valor}
        Log    Pagador: ${pagador}

        # (estrutura dos dados)

        ${boleto}    Create Dictionary
        ...    arquivo=${arquivo}
        ...    nome_pagador=${nome_pagador}
        ...    doc=${doc}
        ...    vencimento=${vencimento}
        ...    parcela=${mes_vencimento}
        ...    data_doc=${data_doc}
        ...    valor=${valor}
        ...    pagador=${pagador}

        Append To List    ${boletos}    ${boleto}

    END

    Set Global Variable    ${boletos}


Operação Easonilo
    [Documentation]    Lógica para adicionar os contracheques previamente baixados.

    # Realiza o login no sistema Easonilo.

    Abrir Chrome Permitindo Conteudo Inseguro
    Maximize Browser Window
    Sleep    2s
    Wait Until Element Is Visible    ${form_easonilo}    60s
    Click Element    ${button_pag_cepedi}
    Wait Until Element Is Visible    ${form_login_cepedi}
    Input Text    ${input_login_easonilo}    ${login_easonilo}
    Input Password    ${input_senha_easonilo}    ${senha_easonilo}
    Wait Until Element Is Enabled    ${button_login_easonilo}    15s
    Click Element                    ${button_login_easonilo}
    

    # Faz a verificação se realizou o login e vai para a página do financeiro.

    Wait Until Element Is Not Visible    ${carregamento_login_easonilo}    30s
    Wait Until Element Is Visible    ${usuario_easonilo}    60s
    Click Element    ${button_financeiro}
    Wait Until Element Is Visible    ${button_movimentos}
    Click Element    ${button_movimentos}
    Wait Until Element Is Visible    ${button_receber_contas}
    Click Element    ${button_receber_contas}


    FOR    ${boleto}    IN    @{boletos}
    # Confere se realmente entrou na página e realiza o upload dos contracheques.

        Wait Until Element Is Visible    ${header_contas_a_receber}
        Click Element    ${button_adicionar}
        Wait Until Element Is Visible    ${header_novo_contas}
        Click Element    ${input_prefixo}

        Wait Until Element Is Visible    ${input_cli}
        Click Element    ${input_cli}
        Input Text    ${input_numero}    ${boleto}[doc]

        Input Text    ${parcela}    ${boleto}[parcela]
        Input Text    ${locator_valor}    ${boleto}[valor]

        Click Element    ${lupa_codigo_natureza}
        Wait Until Element Is Visible    ${locator_pesquisar}
        Input Text    ${locator_pesquisar}    ${valor_codigo_natureza}
        Wait Until Element Is Visible    ${button_codigo_natureza}
        Click Element    ${button_codigo_natureza}

        Wait Until Element Is Visible    ${lupa_tipo}
        Click Element    ${lupa_tipo}
        Wait Until Element Is Visible     ${select_boleto}
        Click Element    ${select_boleto}

        Wait Until Element Is Visible    ${emissao}
        Input Text    ${emissao}    ${boleto}[data_doc]

        Wait Until Element Is Visible    ${locator_vencimento}
        Input Text    ${locator_vencimento}    ${boleto}[vencimento]

        Wait Until Element Is Visible    ${vencimento_real}
        Input Text    ${vencimento_real}    ${boleto}[vencimento]

        Click Element    ${lupa_cliente}
        Wait Until Element Is Visible    ${locator_pesquisar}
        Input Text    ${locator_pesquisar}    ${boleto}[nome_pagador]
        Click Element    xpath=//mat-row[.//mat-cell[contains(@class,'mat-column-nome') and normalize-space()='${boleto}[nome_pagador]']]

        Wait Until Element Is Visible    ${lupa_centro_custo}
        Click Element    ${lupa_centro_custo}
        Wait Until Element Is Visible    ${locator_pesquisar}
        Input Text    ${locator_pesquisar}    ${nome_id_centro_custo}
        Wait Until Element Is Visible    ${button_id_centro_custo}
        Click Element    ${button_id_centro_custo}
        
        Input Text     ${locator_historico}    BOLETO MES ${boleto}[parcela]

        Wait Until Element Is Visible    ${button_adicionar_boletos}
        # Click Element     ${button_adicionar_boletos}

    END


Lógica Data
    [Documentation]    Preenche via JavaScript os campos de data com o primeiro e o último dia do mês atual.

    ${hoje}                Get Current Date
    ${primeiro_dia_iso}    Convert Date    ${hoje}    result_format=%Y-%m-01
    ${prox_mes_iso}        Add Time To Date    ${primeiro_dia_iso}    32 days    result_format=%Y-%m-01
    ${ultimo_dia_iso}      Subtract Time From Date    ${prox_mes_iso}    1 day    result_format=%Y-%m-%d

    ${primeiro_dia}    Convert Date    ${primeiro_dia_iso}    result_format=%d/%m/%Y
    ${ultimo_dia}      Convert Date    ${ultimo_dia_iso}    result_format=%d/%m/%Y

    Execute Javascript    document.getElementById('Cobranca_date_first').value = '${primeiro_dia}';
    Execute Javascript    document.getElementById('Cobranca_date_last').value = '${ultimo_dia}';
    Sleep    1s

Abrir Chrome Permitindo Conteudo Inseguro

    ${options}    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver

    Call Method    ${options}    add_argument    --allow-running-insecure-content
    Call Method    ${options}    add_argument    --disable-web-security
    Call Method    ${options}    add_argument    --ignore-certificate-errors

    Create Webdriver    Chrome    options=${options}

    Go To    ${url_easonilo}