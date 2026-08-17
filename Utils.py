def buscar_codigo_cliente(nome_pagador, clientes):
    """Encontra o código do cliente em `clientes` cuja chave (nome truncado pela
    listagem do sistema) é prefixo do nome completo do pagador extraído do boleto.

    Retorna 'NAO_ENCONTRADO' quando nenhuma chave bate.
    """
    nome_upper = (nome_pagador or "").upper()

    for chave in sorted(clientes, key=len, reverse=True):
        if nome_upper.startswith(chave.upper()):
            return clientes[chave]

    return "NAO_ENCONTRADO"
