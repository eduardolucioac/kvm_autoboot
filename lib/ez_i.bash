#!/bin/bash
: 'Trata-se de um módulo que oferece uma série de funcionalidades para 
criar um instalador usando "bash".

Version 1.2.0b

Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/
Copyright 2016 Eduardo Lúcio Amorim Costa
'

# NOTE: Obtêm a pasta do script atual para que seja usado como 
# caminho base/referência durante a instalação! By Questor
EZ_I_DIR_V="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# NOTE: Quando setado faz "ez_i" desabilitar algumas funções, 
# notadamente aquelas que envolvem "perguntas ao usuário" e as 
# gráficas! By Questor
EZ_I_SKIP_ON_V=0

# > --------------------------------------------------------------------------
# UTILITÁRIOS!
# --------------------------------------

C_PRINT_LONG_INSTRUCTIONS="
[ NAVIGATE: "$(echo -e '\U2193')" down arrow | "$(echo -e '\U2191')" up arrow | "$(echo -e '\U21DF')" page down | "$(echo -e '\U21DE')" page up | "$(echo -e '\U2195')" mouse wheel ]
[ CONTINUE: q ]
"

F_PRINT_LONG_STR_R=0
f_print_long_str() {
    : 'Paging text entries when they are larger than the terminal size.

    If the text entry is larger than the current size of the terminal then it will 
    page it.

    Args:
        STR_INPUT_P (str): Text to display.

    Returns:
        F_PRINT_LONG_STR_R (int): 0 - If is NOT a string (STR_INPUT_P) that needs 
    be paged; 1 - If is a string  (STR_INPUT_P) that needs be paged. NOTE: Useful 
    to control the execution of your script and allow you control the flow of printed 
    information on terminal.
    '

    STR_INPUT_P=$1
    INSTRUCTIONS_P=$2
    if [ -z "$INSTRUCTIONS_P" ] ; then
        INSTRUCTIONS_P=1
    fi

    STR_LENGTH=$(((${#C_PRINT_LONG_INSTRUCTIONS}+${#STR_INPUT_P})))
    STR_LINES=$(echo -n "$C_PRINT_LONG_INSTRUCTIONS$STR_INPUT_P" | grep -c '^')

    # NOTE: Get terminal ROWS*COLUMNS size! By Questor
    read CON_ROWS CON_COLS < <(stty size)
    CON_SIZE=$(( ($CON_ROWS - 1) * $CON_COLS ))

    # NOTE: Decide whether to use "less" or not to page the output! By Questor
    if [ ${STR_LENGTH} -gt ${CON_SIZE} ] || [ ${STR_LINES} -gt $(($CON_ROWS - 1)) ] ; then
        echo -n "$C_PRINT_LONG_INSTRUCTIONS$STR_INPUT_P" | less -F

        # NOTE: Keep the last printed content on the terminal screen. By Questor
        echo "$C_PRINT_LONG_INSTRUCTIONS$STR_INPUT_P"

        F_PRINT_LONG_STR_R=1

    else
        echo "$STR_INPUT_P"
        F_PRINT_LONG_STR_R=0
    fi

}

f_enter_to_cont() {
    : 'Solicitar ao usuário que pressione enter para continuar.

    Args:
        INFO_P (Optional[int]): Se informado apresenta uma mensagem ao 
    usuário. Padrão 0.
    '

    INFO_P=$1
    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi

    if [ ! -z "$INFO_P" ] ; then
        f_div_section
        echo "$INFO_P"
        f_div_section
    fi

    read -p "Press enter to continue..." nothing
}

GET_USR_INPUT_R=""
f_get_usr_input() {
    : 'Obter entradas digitadas pelo usuário.

    Permite autocomplete (tab). Enter para submeter a entrada.

    Args:
        QUESTION_P (str): Pergunta a ser feita ao usuário.
        ALLOW_EMPTY_P (Optional[int]): 0 - Não permite valor vazio; 1 - Permite 
    valor vazio. Padrão 0.
        IS_PWD_P (Optional[int]): 0 - O input NÃO é um password; 1 - O input é um 
    password. Padrão 0.

    Returns:
        GET_USR_INPUT_R (str): Entrada digitada pelo usuário.
    '

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    QUESTION_P=$1
    ALLOW_EMPTY_P=$2
    if [ -z "$ALLOW_EMPTY_P" ] ; then
        ALLOW_EMPTY_P=0
    fi
    IS_PWD_P=$3
    if [ -z "$IS_PWD_P" ] ; then
        IS_PWD_P=0
    fi
    GET_USR_INPUT_R=""
    f_print_long_str "$QUESTION_P"
    if [ ${IS_PWD_P} -eq 0 ] ; then
        read -e -r -p " (use enter to confirm): " RESP_V
    else

        # [Ref.: https://stackoverflow.com/a/3980904/3223785 ]
        read -s -e -r -p " (use enter to confirm): " RESP_V
        echo ""

    fi
    if [ -n "$RESP_V" ] ; then
        GET_USR_INPUT_R="$RESP_V"
    elif [ ${ALLOW_EMPTY_P} -eq 0 ] ; then
        f_get_usr_input "$QUESTION_P" 0 ${IS_PWD_P}
    fi
}

f_get_usr_input_mult() {
    : 'Obter determinada opção do usuário à partir de uma lista de 
    entrada.

    Permite autocomplete (tab). Enter para submeter a entrada.

    Args:
        QUESTION_P (str): Pergunta a ser feita ao usuário (as 
    opções são exibidas automaticamente).
        OPT_ARR_P (array): Array com a lista de opções possíveis. As posições 
    pares do array são as opções e as ímpares são a descrição dessas opções.
        ALLOW_EMPTY_P (Optional[int]): 0 - Não permite valor vazio; 1 - Permite 
    valor vazio. Padrão 0.

    Returns:
        GET_USR_INPUT_MULT_R (str): Entrada digitada pelo usuário.
        GET_USR_INPUT_MULT_V_R (str): Valor referente a entrada digitada pelo 
    usuário.
    '

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    QUESTION_P=$1
    OPT_ARR_P=("${!2}")
    TOTAL_0=${#OPT_ARR_P[*]}
    ALLOW_EMPTY_P=$3
    if [ -z "$ALLOW_EMPTY_P" ] ; then
        ALLOW_EMPTY_P=0
    fi
    USE_PIPE=""
    POSSIBLE_OPT="(select your option and press enter: "
    for (( i=0; i<=$(( $TOTAL_0 -1 )); i++ )) ; do
        if [ $((i%2)) -eq 0 ]; then
            # "even"
            POSSIBLE_OPT=$POSSIBLE_OPT${OPT_ARR_P[$i]}" - "
        else
            # "odd"
            if (( i <= $(( TOTAL_0 -2 )) )) ; then
                USE_PIPE=" | "
            else
                USE_PIPE=""
            fi
            POSSIBLE_OPT=$POSSIBLE_OPT${OPT_ARR_P[$i]}$USE_PIPE
        fi
    done
    POSSIBLE_OPT=$POSSIBLE_OPT")"
    GET_USR_INPUT_MULT_R=""
    GET_USR_INPUT_MULT_V_R=""
    read -e -r -p "$QUESTION_P 
$POSSIBLE_OPT: " RESP_V
    if [ -n "$RESP_V" ] ; then
        for (( o=0; o<=$(( $TOTAL_0 -1 )); o++ )) ; do
            if [ $((i%2)) -eq 0 ] && [ "$RESP_V" == "${OPT_ARR_P[$o]}" ] ; then
                # "even"
                # GET_USR_INPUT_MULT_R="$RESP_V"
                GET_USR_INPUT_MULT_R="${OPT_ARR_P[$o]}"
                # f=$[$f+1]
                GET_USR_INPUT_MULT_V_R="${OPT_ARR_P[$o+1]}"
                break
            fi
        done
        if [ -z "$GET_USR_INPUT_MULT_R" ] ; then
            f_get_usr_input_mult "$QUESTION_P" OPT_ARR_P[@] $ALLOW_EMPTY_P
        fi
    elif [ ${ALLOW_EMPTY_P} -eq 0 ] ; then
        f_get_usr_input_mult "$QUESTION_P" OPT_ARR_P[@] 0
    fi
}

F_POWER_SED_ECP_R=""
f_power_sed_ecp() {
    : 'Escape strings for the "sed" command.

    Args:
        F_VAL_TO_ECP (str): Value to be escaped.
        F_ECP_TYPE (int): 0 - For the TARGET value; 1 - For the REPLACE value.

    Returns:
        F_POWER_SED_ECP_R (str): Escaped value.
    '

    F_VAL_TO_ECP=$1
    F_ECP_TYPE=$2
    if [ ${F_ECP_TYPE} -eq 0 ] ; then
    # NOTE: For the TARGET value. By Questor

        F_POWER_SED_ECP_R=$(echo "x${F_VAL_TO_ECP}x" | sed 's/[]\/$*.^|[]/\\&/g' | sed 's/\t/\\t/g' | sed "s/'/\\\x27/g")
    else
    # NOTE: For the REPLACE value. By Questor

        F_POWER_SED_ECP_R=$(echo "x${F_VAL_TO_ECP}x" | sed 's/[]\/$*.^|[]/\\&/g' | sed 's/\t/\\t/g' | sed "s/'/\\\x27/g" | sed ':a;N;$!ba;s/\n/\\n/g')
    fi

    F_POWER_SED_ECP_R=${F_POWER_SED_ECP_R%?}
    F_POWER_SED_ECP_R=${F_POWER_SED_ECP_R#?}
}

F_POWER_SED_R=""
f_power_sed() {
    : 'Facilitate the use of the "sed" command. Replaces in files and strings.

    Args:
        F_TARGET (str): Value to be replaced by the value of F_REPLACE.
        F_REPLACE (str): Value that will replace F_TARGET.
        F_FILE (Optional[str]): File in which the replacement will be made.
        F_SOURCE (Optional[str]): String to be manipulated in case "F_FILE" was 
not informed.
        F_ALL_OCCUR (Optional[int]): 0 - Replace only on the first occurrence; 
1 - Replace every occurrence. Default 0.

    Returns:
        F_POWER_SED_R (str): Return if "F_FILE" is not informed.
    '

    F_TARGET=$1
    F_REPLACE=$2
    F_FILE=$3
    F_SOURCE=$4
    ALL_OCCUR=$5
    if [ -z "$F_ALL_OCCUR" ] ; then
        F_ALL_OCCUR=0
    fi
    f_power_sed_ecp "$F_TARGET" 0
    F_TARGET=$F_POWER_SED_ECP_R
    f_power_sed_ecp "$F_REPLACE" 1
    F_REPLACE=$F_POWER_SED_ECP_R
    if [ ${F_ALL_OCCUR} -eq 0 ] ; then
        SED_RPL="'0,/$F_TARGET/s//$F_REPLACE/g'"
    else
        SED_RPL="'s/$F_TARGET/$F_REPLACE/g'"
    fi
    if [ -z "$F_FILE" ] ; then
        F_EZ_SED_R=$(echo "x${F_SOURCE}x" | eval "sed $SED_RPL")
        F_POWER_SED_R=${F_POWER_SED_R%?}
        F_POWER_SED_R=${F_POWER_SED_R#?}
    else
        eval "sed -i $SED_RPL $F_FILE"
    fi
}

F_EZ_SED_ECP_R=""
f_ez_sed_ecp() {
    : '"Escapar" strings para o comando "sed".

    Como há muitas semelhanças entre o escape para "sed" ("f_ez_sed") e 
    escape para "grep" ("f_fl_cont_str") optei por colocar essa função 
    como utilitária para as outras duas.

    Args:
        VAL_TO_ECP (str): Valor a ser "escapado".
        DONT_ECP_NL (Optional[int]): 1 - Não "escapa" "\n" (quebra de 
    linha); 0 - "Escapa" "\n". Padrão 1.
        DONT_ECP_SQ (Optional[int]): 1 - Não "escapa" "'" (aspas 
    simples); 0 - "Escapa" "'". Padrão 1. NOTE: Usado apenas pela 
    função "f_fl_cont_str".

    Returns:
        F_EZ_SED_ECP_R (str): Valor "escapado".
    '

    VAL_TO_ECP=$1
    DONT_ECP_NL=$2
    if [ -z "$DONT_ECP_NL" ] ; then
        DONT_ECP_NL=1
    fi
    DONT_ECP_SQ=$3
    if [ -z "$DONT_ECP_SQ" ] ; then
        DONT_ECP_SQ=0
    fi
    F_EZ_SED_ECP_R=$VAL_TO_ECP

    # NOTE: Com essa intervenção conseguimos passar argumentos para um comando
    # "sed" mesmo que o texto tenha quebras de linha. Perceba que isso serve 
    # apenas para a string a ser usada na substituição! By Questor
    F_EZ_SED_ECP_R=$(echo -n "'${F_EZ_SED_ECP_R}'" | awk 'BEGIN {RS="dn"} {gsub("\n","\\n"); printf $0}')
    f_preserve_blank_lines "$F_EZ_SED_ECP_R"
    F_EZ_SED_ECP_R="$F_PRESERVE_BLANK_LINES_R"

    # NOTE: Para os casos onde "\n" faz parte dos argumentos. Nesses casos 
    # os argumentos possuem "\n" em vez de quebras de linha efetivamente. Se 
    # desabilitado "\n" será tratado como texto e não será convertido para 
    # quebras! By Questor
    if [ ${DONT_ECP_NL} -eq 1 ] ; then
        F_EZ_SED_ECP_R=$(echo "'${F_EZ_SED_ECP_R}'" | sed 's/\\n/C0673CECED2D4A8FBA90C9B92B9508A8/g')
        f_preserve_blank_lines "$F_EZ_SED_ECP_R"
        F_EZ_SED_ECP_R="$F_PRESERVE_BLANK_LINES_R"
    fi

    # NOTE: Escapa valores, principalmente, para serem aplicados como
    # argumentos em um comando de replace no "sed"! By Questor
    F_EZ_SED_ECP_R=$(echo "'${F_EZ_SED_ECP_R}'" | sed 's/[]\/$*.^|[]/\\&/g')
    f_preserve_blank_lines "$F_EZ_SED_ECP_R"
    F_EZ_SED_ECP_R="$F_PRESERVE_BLANK_LINES_R"

    if [ ${DONT_ECP_SQ} -eq 0 ] ; then
        F_EZ_SED_ECP_R=$(echo "x${F_EZ_SED_ECP_R}x" | sed "s/'/\\\x27/g")
        f_preserve_blank_lines "$F_EZ_SED_ECP_R"
        F_EZ_SED_ECP_R="$F_PRESERVE_BLANK_LINES_R"
    fi
    if [ ${DONT_ECP_NL} -eq 1 ] ; then
        F_EZ_SED_ECP_R=$(echo "'${F_EZ_SED_ECP_R}'" | sed 's/C0673CECED2D4A8FBA90C9B92B9508A8/\\n/g')
        f_preserve_blank_lines "$F_EZ_SED_ECP_R"
        F_EZ_SED_ECP_R="$F_PRESERVE_BLANK_LINES_R"
    fi
}

F_EZ_SED_R=""
f_ez_sed() {
    : 'Facilitar o uso da funcionalidade "sed". Faz replace em arquivos e em 
    strings.

    Args:
        TARGET (str): Valor a ser substituído por pelo valor de REPLACE.
        REPLACE (str): Valor que irá substituir TARGET.
        FILE (str): Arquivo no qual será feita a substituição.
        ALL_OCCUR (Optional[int]): 0 - Fazer replace apenas na primeira 
    ocorrência; 1 - Fazer replace em todas as ocorrências. Padrão 0.
        DONT_ESCAPE (Optional[int]): 0 - Faz escape das strings em 
    TARGET e REPLACE; 1 - Não faz escape das strings em TARGET e 
    REPLACE. Padrão 0.
        DONT_ECP_NL (Optional[int]): 1 - Não "escapa" "\n" (quebra de 
    linha); 0 - "Escapa" "\n". Padrão 1.
    NOTE: Para os casos onde "\n" faz parte dos argumentos. Nesses casos 
    os argumentos possuem "\n" em vez de quebras de linha efetivamente. Se 
    desabilitado "\n" será tratado como texto e não será convertido para 
    quebras;
        REMOVE_LN (Optional[int]): 1 - Remove a linha que possui o 
    valor em TARGET; 0 - Faz o replace convencional. Padrão 0.
        NTH_OCCUR (Optional[int]): Executará a operação escolhida 
    apenas sobre a ocorrência indicada (utilize 2 para fazer replace apenas 
    na 2 ocorrencia, por exemplo); Se -1, não executa. Padrão -1.
        SOURCE (Optional[str]): String a ser manipulada por caso "FILE" não 
    seja informado.

    Returns:
        F_EZ_SED_R (str): Retorno de sed caso "FILE" não seja informado.
    '

    echo "bundaaaa"

    FILE=$3
    ALL_OCCUR=$4
    if [ -z "$ALL_OCCUR" ] ; then
        ALL_OCCUR=0
    fi
    DONT_ESCAPE=$5
    if [ -z "$DONT_ESCAPE" ] ; then
        DONT_ESCAPE=0
    fi
    DONT_ECP_NL=$6
    if [ -z "$DONT_ECP_NL" ] ; then
        DONT_ECP_NL=1
    fi
    REMOVE_LN=$7
    if [ -z "$REMOVE_LN" ] ; then
        REMOVE_LN=0
    fi
    NTH_OCCUR=$8
    if [ -z "$NTH_OCCUR" ] ; then
        NTH_OCCUR=-1
    fi
    SOURCE=$9
    if [ -z "$SOURCE" ] ; then
        SOURCE=""
    fi
    if [ ${DONT_ESCAPE} -eq 1 ] ; then
        TARGET=$1
        REPLACE=$2
    else
        f_ez_sed_ecp "$1" $DONT_ECP_NL
        TARGET=$F_EZ_SED_ECP_R
        f_ez_sed_ecp "$2" $DONT_ECP_NL
        REPLACE=$F_EZ_SED_ECP_R
    fi
    if [ ${REMOVE_LN} -eq 1 ] ; then
        if [ ${ALL_OCCUR} -eq 0 ] ; then
            SED_RPL="'0,/$TARGET/{//d;}'"
        else
            SED_RPL="'/$TARGET/d'"
        fi
        if [ -z "$FILE" ] ; then
            F_EZ_SED_R=$(echo -n $SOURCE | eval "sed $SED_RPL")
        else
            eval "sed -i $SED_RPL $FILE"
        fi
    else
        if [ ${NTH_OCCUR} -gt -1 ] ; then

            # TODO: Tá TOSCO no último! Mas, não consegui uma forma de fazer 
            # replace em apenas determinada posição usando o "sed"! Para ser 
            # bem franco não sei se dá para fazer isso com o "sed"! By Questor
            ((NTH_OCCUR++))
            for (( i=0; i<$(( $NTH_OCCUR - 1 )); i++ )) ; do
                SED_RPL="'0,/$TARGET/s//C0673CECED2D4A8FBA90C9B92B9508A8/g'"
                if [ -z "$FILE" ] ; then
                    F_EZ_SED_R=$(echo -n $SOURCE | eval "sed $SED_RPL")
                else
                    eval "sed -i $SED_RPL $FILE"
                fi
            done
            SED_RPL="'0,/$TARGET/s//$REPLACE/g'"
            if [ -z "$FILE" ] ; then
                F_EZ_SED_R=$(echo -n $F_EZ_SED_R | eval "sed $SED_RPL")
            else
                eval "sed -i $SED_RPL $FILE"
            fi
            SED_RPL="'s/C0673CECED2D4A8FBA90C9B92B9508A8/$TARGET/g'"
            if [ -z "$FILE" ] ; then
                F_EZ_SED_R=$(echo -n $F_EZ_SED_R | eval "sed $SED_RPL")
            else
                eval "sed -i $SED_RPL $FILE"
            fi
        else
            if [ ${ALL_OCCUR} -eq 0 ] ; then
                SED_RPL="'0,/$TARGET/s//$REPLACE/g'"
            else
                SED_RPL="'s/$TARGET/$REPLACE/g'"
            fi
            if [ -z "$FILE" ] ; then
                F_EZ_SED_R=$(echo -n $SOURCE | eval "sed $SED_RPL")
            else
                eval "sed -i $SED_RPL $FILE"
            fi
        fi
    fi
}

FL_CONT_STR_R=0
f_fl_cont_str() {
    : 'Checar se um arquivo contêm determinada string.

    Args:
        STR_TO_CH (str): Valor de string a ser verificado.
        FILE (str): Arquivo no qual será feita a verificação.
        COND_MSG_P (Optional[str]): Mensagem a ser exibida se 
    verdadeira a verificação. Se vazio ou não informado não será 
    exibida mensagem.
        CHK_INVERT (Optional[int]): Inverter a lógica da checagem. 
    Padrão 0.
        DONT_ESCAPE (Optional[int]): 0 - Faz escape da string em 
    STR_TO_CH; 1 - Não faz escape das strings em STR_TO_CH. Padrão 0.
        DONT_ECP_NL (Optional[int]): 1 - Não "escapa" "\n" (quebra de 
    linha); 0 - "Escapa" "\n". Padrão 1.

    Returns:
        FL_CONT_STR_R (int): 1 - Se verdadeiro para a condição 
    analisada; 0 - Se falso para a condição analisada.
    '

    STR_TO_CH=$1
    FILE=$2
    COND_MSG_P=$3
    CHK_INVERT=$4
    DONT_ESCAPE=$5

    if [ -z "$DONT_ESCAPE" ] ; then
        DONT_ESCAPE=0
    fi
    if [ ${DONT_ESCAPE} -eq 0 ] ; then
        DONT_ECP_NL=$6
        if [ -z "$DONT_ECP_NL" ] ; then
            DONT_ECP_NL=1
        fi
        f_ez_sed_ecp "$STR_TO_CH" $DONT_ECP_NL 1
        STR_TO_CH=$F_EZ_SED_ECP_R
    fi

    if [ -z "$CHK_INVERT" ] ; then
        CHK_INVERT=0
    fi
    FL_CONT_STR_R=0
    if [ ${CHK_INVERT} -eq 0 ] ; then
        if grep -q "$STR_TO_CH" "$FILE"; then
            FL_CONT_STR_R=1
        fi
    else
        if ! grep -q "$STR_TO_CH" "$FILE"; then
            FL_CONT_STR_R=1
        fi
    fi
    if [ ${EZ_I_SKIP_ON_V} -eq 0 ] && [ ${FL_CONT_STR_R} -eq 1 ] && [ ! -z "$COND_MSG_P" ] ; then
        f_div_section
        echo "$COND_MSG_P"
        f_div_section
        f_enter_to_cont
    fi
}

CHK_FD_FL_R=0
f_chk_fd_fl() {
    : 'Verificar se determinado diretório ou arquivo existe.

    Args:
        TARGET (str): Diretório ou arquivo qual se quer verificar.
        CHK_TYPE (str): "d" - Checar por diretório; "f" - Checar por 
    arquivo.

    Returns:
        CHK_FD_FL_R (int): 1 - True; 0 - False.
    '

    CHK_FD_FL_R=0
    TARGET=$1
    CHK_TYPE=$2
    if [ "$CHK_TYPE" == "f" ] ; then
        if [ -f "$TARGET" ] ; then
            CHK_FD_FL_R=1
        fi
    fi
    if [ "$CHK_TYPE" == "d" ] ; then
        if [ -d "$TARGET" ] ; then
            CHK_FD_FL_R=1
        fi
    fi
}

F_PACK_IS_INST_R=0
f_pack_is_inst() {
    : 'Checar se um pacote está instalado.

    Args:
        PACKAGE_NM_P (str): Nome do pacote.
        PACK_MANAG (str): Tipo de gerenciador de pacotes. "yum", 
    "apt-get" e "zypper" são suportados. Em caso diverso o script 
    exibe erro e para.
        EXIST_MSG_P (Optional[str]): Mensagem a ser exibida se o 
    pacote já estiver instalado. Se vazio ou não informado não será 
    exibida mensagem.
        SKIP_MSG_P (Optional[int]): 1 - Omite a mensagem; 0 - Não omite a 
    mensagem. Padrão 1.

    Returns:
        F_PACK_IS_INST_R (int): 1 - Instalado; 0 - Não instalado.
    '

    PACKAGE_NM_P=$1
    PACK_MANAG=$2
    EXIST_MSG_P=$3
    SKIP_MSG_P=$4

    if [ -z "$SKIP_MSG_P" ] ; then
        SKIP_MSG_P=1
    fi
    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        SKIP_MSG_P=1
    fi

    F_PACK_IS_INST_R=0
    if [ "$PACK_MANAG" == "yum" ] ; then
        if yum list installed "$PACKAGE_NM_P" >/dev/null 2>&1; then
            if [ ${SKIP_MSG_P} -eq 0 ] && [ ! -z "$EXIST_MSG_P" ] ; then
                f_div_section
                echo "$EXIST_MSG_P"
                f_div_section
                f_enter_to_cont
            fi
            F_PACK_IS_INST_R=1
        else
            F_PACK_IS_INST_R=0
        fi
    elif [ "$PACK_MANAG" == "apt-get" ] ; then
        if dpkg -s "$PACKAGE_NM_P" &> /dev/null; then
            if [ ${SKIP_MSG_P} -eq 0 ] && [ ! -z "$EXIST_MSG_P" ] ; then
                f_div_section
                echo "$EXIST_MSG_P"
                f_div_section
                f_enter_to_cont
            fi
            F_PACK_IS_INST_R=1
        else
            F_PACK_IS_INST_R=0
        fi
    elif [ "$PACK_MANAG" == "zypper" ] ; then
        if zypper se -i --match-word "$PACKAGE_NM_P" > /dev/null 2>&1; then
            if [ ${SKIP_MSG_P} -eq 0 ] && [ ! -z "$EXIST_MSG_P" ] ; then
                f_div_section
                echo "$EXIST_MSG_P"
                f_div_section
                f_enter_to_cont
            fi
            F_PACK_IS_INST_R=1
        else
            F_PACK_IS_INST_R=0
        fi
    else
        f_div_section
        echo "ERROR! Not implemented for \"$PACK_MANAG\"!"
        f_div_section
        f_enter_to_cont
    fi
}

F_CHK_BY_PATH_HLP_R=0
f_chk_by_path_hlp() {
    : 'Checar se um aplicativo/pacote/arquivo está presente/instalado 
    verificando-o através do seu caminho físico informando.

    Args:
        PATH_VER_P (str): Caminho físico para o aplicativo/pacote.
        VER_TYPE_P (str): Se o caminho físico é para um diretório ("d") 
    ou arquivo ("f").
        EXIST_MSG_P (Optional[str]): Mensagem a ser "printada" caso o 
    aplicativo/pacote/arquivo/pasta exista. Se não informado ou vazio não 
    exibe a mensagem.
        SKIP_MSG_P (Optional[int]): Não exibir mensagem.

    Returns:
        F_CHK_BY_PATH_HLP_R (int): 0 - Não existe; 1 - Existe 
    ("printa" menssagem contida em EXIST_MSG_P).
    '

    PATH_VER_P=$1
    VER_TYPE_P=$2
    EXIST_MSG_P=$3
    SKIP_MSG_P=$4
    if [ -z "$SKIP_MSG_P" ] ; then
        SKIP_MSG_P=0
    fi
    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        SKIP_MSG_P=1
    fi

    F_CHK_BY_PATH_HLP_R=0
    f_chk_fd_fl "$PATH_VER_P" "$VER_TYPE_P"
    if [ ${CHK_FD_FL_R} -eq 0 ] ; then
        F_CHK_BY_PATH_HLP_R=0
    else
        if [ ${SKIP_MSG_P} -eq 0 ] && [ ! -z "$EXIST_MSG_P" ]; then
            f_div_section
            echo "$EXIST_MSG_P"
            f_div_section
            f_enter_to_cont
        fi
        F_CHK_BY_PATH_HLP_R=1
    fi
}

F_CHK_IPTABLES_R=0
f_chk_iptables() {
    : 'Fazer verificações usando "iptables".

    Trata-se de um utilitário para fazer verificações diversas usando o 
    comando "iptables" NORMALMENTE CHECAR DE DETERMINADA PORTA ESTÁ 
    ABERTA.

    Ex 1.: f_chk_iptables 80
    Ex 2.: f_chk_iptables 80 "Já está aberta!"
    Ex 3.: f_chk_iptables 80 "Já está aberta!" 0 "ACCEPT" "tcp" "NEW"
    Ex 4.: f_chk_iptables 80 "Já está aberta!" 0 "ACCEPT" "tcp" "NEW" 5

    Args:
        PORT_P (int): Porta a ser verificada.
        MSG_P (Optional[str]): Mensagem a ser exibida em caso de 
    verdadeiro para a verificação (normalmente porta aberta). Se vazio 
    ou não informado não será exibida mensagem.
        SKIP_MSG_P (Optional[int]): Não exibir mensagem. 
    Padrão 0.
        TARGET_P (Optional[str]): Padrão "ACCEPT".
        PROT_P (Optional[str]): Padrão "tcp".
        STATE_P (str): Padrão "".
        POS_IN_CHAIN_P (int): Padrão "".

    Returns:
        F_CHK_IPTABLES_R (int): 1 - Verdadeiro para a verificação; 
    0 - Falso para a verificação.
    '

    PORT_P=$1
    MSG_P=$2
    SKIP_MSG_P=$3

    if [ -z "$SKIP_MSG_P" ] ; then
        SKIP_MSG_P=0
    fi
    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        SKIP_MSG_P=1
    fi

    TARGET_P=$4
    if [ -z "$TARGET_P" ] ; then
        TARGET_P="ACCEPT"
    fi
    PROT_P=$5
    if [ -z "$PROT_P" ] ; then
        PROT_P="tcp"
    fi
    STATE_P=$6
    if [ -z "$STATE_P" ] ; then
        STATE_P=""
    else
        STATE_P="state $STATE_P "
    fi
    POS_IN_CHAIN_P=$7
    if [ -z "$POS_IN_CHAIN_P" ] ; then
        POS_IN_CHAIN_P=""
    else
        POS_IN_CHAIN_P=$(printf "%-9s" $POS_IN_CHAIN_P)
    fi
    GREP_OUT=$(iptables -vnL --line-numbers | grep "$POS_IN_CHAIN_P" | grep "$TARGET_P" | grep "$PROT_P" | grep "dpt:$PORT_P ")
    if [ $? -eq 1 ] ; then
        F_CHK_IPTABLES_R=1
    else
        if [ ${SKIP_MSG_P} -eq 0 ] && [ ! -z "$MSG_P" ] ; then
            f_div_section
            echo "$MSG_P"
            f_div_section
            f_enter_to_cont
        fi
        F_CHK_IPTABLES_R=0
    fi
}

F_IS_NOT_RUNNING_R=0
f_is_not_running() {
    : 'Checar de determinado processo (pode ser um serviço) está 
    rodando.

    Args:
        PROC_NM_P (str): Nome do processo (pode ser um serviço).
        COND_MSG_P (Optional[str]): Mensagem a ser exibida se 
    verdadeira a verificação. Se vazio ou não informado não será 
    exibida mensagem.
        CHK_INVERT (Optional[int]): Inverter a lógica da checagem. 
    Padrão 0.

    Returns:
        F_IS_NOT_RUNNING_R (int): 1 - Se verdadeiro para a condição 
    analisada; 0 - Se falso para a condição analisada.
    '

    PROC_NM_P=$1
    COND_MSG_P=$2
    CHK_INVERT=$3
    if [ -z "$CHK_INVERT" ] ; then
        CHK_INVERT=0
    fi
    F_IS_NOT_RUNNING_R=0

    # NOTE: A verificação "grep -v grep" é para que ele não dê positivo 
    # para o próprio comando grep! By Questor
    F_IS_NOT_RUNNING_R=0
    if [ ${CHK_INVERT} -eq 0 ] ; then
        if ! ps aux | grep -v "grep" | grep "$PROC_NM_P" > /dev/null ; then
            F_IS_NOT_RUNNING_R=1
        fi
    else
        if ps aux | grep -v "grep" | grep "$PROC_NM_P" > /dev/null ; then
            F_IS_NOT_RUNNING_R=1
        fi
    fi
    if [ ${EZ_I_SKIP_ON_V} -eq 0 ] && [ ${F_IS_NOT_RUNNING_R} -eq 1 ] && [ ! -z "$COND_MSG_P" ] ; then
        f_div_section
        echo "$COND_MSG_P"
        f_div_section
        f_enter_to_cont
    fi
}

F_GET_STDERR_R=""
F_GET_STDOUT_R=""
F_GET_EXIT_CODE_R=0
f_get_stderr_stdout() {
    : 'Run a command and capture output from stderr, stdout and exit code

    Args:
        CMD_TO_EXEC (str): Command to be executed.

    Returns:
        F_GET_STDERR_R (str): Output to stderr.
        F_GET_STDOUT_R (str): Output to stdout.
        F_GET_EXIT_CODE_R (int): Exit code.
        F_GET_STOUTERR (str): Unify the output for stdout and stderr into a single 
    string in that order. Useful as some applications often swap/merge/invert these 
    outputs.
    '

    CMD_TO_EXEC=$1
    F_GET_STDERR_R=""
    F_GET_STDOUT_R=""
    unset t_std t_err t_ret
    eval "$( eval "$CMD_TO_EXEC" 2> >(t_err=$(cat); typeset -p t_err) > >(t_std=$(cat); typeset -p t_std); t_ret=$?; typeset -p t_ret )"
    F_GET_STDERR_R=$t_err
    F_GET_STDOUT_R=$t_std
    F_GET_EXIT_CODE_R=$t_ret
    F_GET_STOUTERR=""
    USE_NEWLINE=""
    if [ ! -z "$F_GET_STDOUT_R" ] ; then
        F_GET_STOUTERR="$F_GET_STDOUT_R"
        USE_NEWLINE=$'\n'
    fi
    if [ ! -z "$F_GET_STDERR_R" ] ; then
        F_GET_STOUTERR="$F_GET_STOUTERR$USE_NEWLINE$F_GET_STDERR_R"
    fi

}

f_log_manager() {
    : 'Generate and manage output and error logs.
    TIP: If you want to create a new log file, make sure to delete one that may 
    already exist, otherwise the function will update the existing log.

    Args:
        VALUE_TO_INSERT (str): Value to insert into log file.
        LOG_TYPE (Optional[int]): 0 - Output log name; 1 - Error log name; OTHER - 
    The "OTHER" value will be used as a custom log name. NOTE: In that case "LOG_MODE" 
    and "PATH_TO_LOG" options will be ignored (use default values for then). "LOG_TYPE=OTHER" 
    take precedence over "LOG_MODE=OTHER"; Default 0.
        LOG_MODE (Optional[int]): 0 - Creates (or append to if it already exists) 
    a log file; 1 - Creates a log with a suffix as part of its name (e.g. 
    "output-D2020-01-29-T17-50-40.log"); OTHER - The "OTHER" value will be used as 
    a custom log prefix name plus a suffix (e.g. "my_prefix-D2020-01-29-T17-50-40.log"). 
    NOTE: In that case "LOG_TYPE" options will be ignored (use default value for
    it); Default 0.
        PATH_TO_LOG (Optional[str]): Folder path to create log file (without "/" 
    at the end). If empty will use the current folder path (value in "EZ_I_DIR_V").
        VAL_INS_ON_SCREEN (Optional[int]): 0 - Will NOT print "VALUE_TO_INSERT" 
    on screen; 1 - Will PRINT "VALUE_TO_INSERT" on screen. Default 0.

    Returns:
        F_LOG_MANAGER_R (str): It will return the name and path of the current log. 
        Useful when we want to update the same log several times and when we used 
        "LOG_MODE=1" or "LOG_MODE=OTHER" option on the first call to the function.
    '

    VALUE_TO_INSERT=$1
    LOG_TYPE=$2
    LOG_MODE=$3
    PATH_TO_LOG=$4
    VAL_INS_ON_SCREEN=$5

    if [ -z "$LOG_TYPE" ] ; then
        LOG_TYPE=0
    elif [[ "$LOG_TYPE" != "0" ]] && [[ "$LOG_TYPE" != "1" ]] ; then
        LOG_MODE=0
    fi
    if [ -z "$LOG_MODE" ] ; then
        LOG_MODE=0
    fi
    if [ -z "$PATH_TO_LOG" ] ; then
        PATH_TO_LOG="$EZ_I_DIR_V"
    fi
    if [ -z "$VAL_INS_ON_SCREEN" ] ; then
        VAL_INS_ON_SCREEN=0
    fi

    LOG_SUFFIX=""
    LOG_FILE_NAME=""
    case $LOG_MODE in
        0)
            case $LOG_TYPE in
                0)
                    LOG_FILE_NAME="$PATH_TO_LOG/output.log"
                ;;
                1)
                    LOG_FILE_NAME="$PATH_TO_LOG/error.log"
                ;;
                *)
                    LOG_FILE_NAME="$LOG_TYPE"
                ;;
            esac
        ;;
        1)
            LOG_SUFFIX=$(date +"-D%Y-%m-%d-T%H-%M-%S")
            case $LOG_TYPE in
                0)
                    LOG_FILE_NAME="$PATH_TO_LOG/output$LOG_SUFFIX.log"
                ;;
                1)
                    LOG_FILE_NAME="$PATH_TO_LOG/error$LOG_SUFFIX.log"
                ;;
            esac
        ;;
        *)
            LOG_SUFFIX=$(date +"-D%Y-%m-%d-T%H-%M-%S")
            LOG_FILE_NAME="$PATH_TO_LOG/$LOG_MODE$LOG_SUFFIX.log"
        ;;
    esac

    if [[ ${VAL_INS_ON_SCREEN} -eq 1 ]]; then
        echo "$VALUE_TO_INSERT"
    fi

    # [Ref.: https://www.tutorialkart.com/bash-shell-scripting/bash-date-format-options-examples/ ]
    # eval "echo \"$(date +"D%Y-%m-%d-T%H-%M-%S-%N") - $VALUE_TO_INSERT\" >> $LOG_FILE_NAME"
    echo "$(date +"D%Y-%m-%d-T%H-%M-%S-%N") - $VALUE_TO_INSERT" >> $LOG_FILE_NAME

    F_LOG_MANAGER_R="$LOG_FILE_NAME"
}

YES_NO_R=0
f_yes_no() {
    : 'Questiona ao usuário "yes" ou "no" sobre determinado algo.

    Args:
        QUESTION_P (str): Questionamento a ser feito.
        WAIT_UNTIL_P (Optional[int]): Esperar até o intervalo informado 
            (em segundos). Padrão 0.
        WAIT_UNTIL_RTN_P (Optional[str]): Valor a ser assumido após o intervalo 
            em WAIT_UNTIL_P. 1 - Yes; 0 - No. Padrão 1.

    Returns:
        YES_NO_R (int): 1 - Yes; 0 - No.
    '

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    RESP_V=""
    YES_NO_R=0
    QUESTION_P=$1
    WAIT_UNTIL_P=$2
    WAIT_UNTIL_RTN_P=$3
    if [ -z "$WAIT_UNTIL_RTN_P" ] ; then
        WAIT_UNTIL_RTN_P=1
    fi
    if [ -z "$WAIT_UNTIL_P" ] ; then
        read -e -r -p "$QUESTION_P (y/n) " RESP_V
    else
        if [ ${WAIT_UNTIL_RTN_P} -eq 1 ] ; then
            AUT_ANSWER="y"
        elif [ ${WAIT_UNTIL_RTN_P} -eq 0 ] ; then
            AUT_ANSWER="n"
        fi

        # NOTE: O "|| echo \"\"" serve par dar uma quebra de linha se nenhuma
        # resposta foi informada! By Questor
        eval "read -e -t$WAIT_UNTIL_P -r -p \"$QUESTION_P (y/n) (\"$AUT_ANSWER\" in $WAIT_UNTIL_P seconds) \" RESP_V" || echo ""

    fi
    if [[ $RESP_V =~ ^([sS]|[yY])$ ]] || ( [ ${WAIT_UNTIL_RTN_P} -eq 1 ] && [ -z "$RESP_V" ] && [ -n "$WAIT_UNTIL_P" ] ) ; then
        YES_NO_R=1
    elif [[ $RESP_V =~ ^([nN])$ ]] || ( [ ${WAIT_UNTIL_RTN_P} -eq 0 ] && [ -z "$RESP_V" ] && [ -n "$WAIT_UNTIL_P" ] ) ; then
        if [ -n "$RESP_V" ] ; then
            echo "NO!"
        fi
        YES_NO_R=0
    else
        f_yes_no "$1" $2 $3
    fi
}

F_BAK_PATH_R=""
F_BAK_MD_R=0
f_ez_mv_bak() {
    : 'Modifica o nome de um arquivo ou pasta para um nome de backup.

    Adiciona um sufixo ao nome no formato: "-D%Y-%m-%d-T%H-%M-%S_BAK".

    Args:
        TARGET (str): Caminho para o arquivo ou pasta alvo.
        CONF_MSG_P (Optional[str]): Verificar se o usuário deseja ou 
    não backup. Se vazio ou não informado não será exibida mensagem.
        SKIP_MSG_P (Optional[int]): 0 - Exibe a mensagem informada; 1 - Não 
    exibe a mensagem informada. Padrão 0.
        USE_COPY_P (Optional[int]): 0 - Define um novo nome para o alvo; 1 - 
    Faz uma cópia do alvo com um novo nome. Padrão 0.
        DONT_CONFIRM_IF_EXISTS_P (Optional[int]): 0 - Verifica; 1 - Não verifica. 
    Padrão 0.
        END_OF_SUFFIX (Optional[str]): Define o final do sufixo. Padrão "_BAK".

    Returns:
        F_BAK_PATH_R (str): Caminho para o arquivo ou pasta alvo com o 
    novo nome.
        F_BAK_NAME_R (str): Nome do arquivo recém criado.
        F_BAK_MD_R (int): 1 - Backup realizado; 0 - Backup não 
    realizado.
    '

    TARGET=$1
    CONF_MSG_P=$2
    SKIP_MSG_P=$3
    if [ -z "$SKIP_MSG_P" ] ; then
        SKIP_MSG_P=0
    fi
    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        SKIP_MSG_P=1
    fi
    USE_COPY_P=$4
    if [ -z "$USE_COPY_P" ] ; then
        USE_COPY_P=0
    fi
    DONT_CONFIRM_IF_EXISTS_P=$5
    if [ -z "$DONT_CONFIRM_IF_EXISTS_P" ] ; then
        DONT_CONFIRM_IF_EXISTS_P=0
    fi
    END_OF_SUFFIX=$6
    if [ -z "$END_OF_SUFFIX" ] ; then
        END_OF_SUFFIX="_BAK"
    fi
    MK_BAK=1
    F_BAK_PATH_R=""
    F_BAK_NAME_R=""
    F_BAK_MD_R=0

    if [[ -e $TARGET ]]; then
        if [ ${SKIP_MSG_P} -eq 0 ] && [ ! -z "$CONF_MSG_P" ] ; then
            f_div_section
            f_yes_no "$CONF_MSG_P"
            f_div_section
            MK_BAK=$YES_NO_R
        fi
        if [ ${MK_BAK} -eq 1 ] ; then
            SUFFIX=$(date +"-D%Y-%m-%d-T%H-%M-%S$END_OF_SUFFIX")
            NEW_NAME="$TARGET$SUFFIX"
            if [ ${USE_COPY_P} -eq 0 ] ; then
                mv "$TARGET" "$NEW_NAME"
            elif [ ${USE_COPY_P} -eq 1 ] ; then
                cp -r "$TARGET" "$NEW_NAME"
            fi
            F_BAK_PATH_R=$NEW_NAME
            F_BAK_NAME_R="${NEW_NAME##*/}"
            F_BAK_MD_R=1
        fi
    else
        if [ ${DONT_CONFIRM_IF_EXISTS_P} -eq 0 ] ; then
            f_enter_to_cont "ERROR! The target does not exist!"
        fi
    fi
}

f_okay_exit() {
    : '"Printa" uma mensagem de finalização e encerra o processo.

    Args:
        EXIT_CAUSE_P (Optional[str]): Causa da finalização.
    '

    EZ_I_S_ON_HOLDER=$EZ_I_SKIP_ON_V
    EZ_I_SKIP_ON_V=0
    EXIT_CAUSE_P=$1
    echo ""
    f_open_section "I N F O R M A T I O N !"
    EXIT_MSG_NOW_P="THE EXECUTION WAS TERMINATED!"
    if [ ! -z "$EXIT_CAUSE_P" ] ; then
        EXIT_MSG_NOW_P="$EXIT_MSG_NOW_P
CAUSE: $EXIT_CAUSE_P"
    fi
    echo "$EXIT_MSG_NOW_P"
    echo ""
    f_close_section
    EZ_I_SKIP_ON_V=$EZ_I_S_ON_HOLDER
    exit 0
}

f_error_exit() {
    : '"Printa" uma mensagem de erro e encerra o processo.

    Args:
        ERROR_CAUSE_P (Optional[str]): Causa do erro.
    '

    EZ_I_S_ON_HOLDER=$EZ_I_SKIP_ON_V
    EZ_I_SKIP_ON_V=0
    ERROR_CAUSE_P=$1
    echo ""
    f_open_section "E R R O R !"
    ERROR_MSG_NOW_P="AN ERROR OCCURRED AND THE EXECUTION WAS TERMINATED!"
    if [ ! -z "$ERROR_CAUSE_P" ] ; then
        ERROR_MSG_NOW_P="$ERROR_MSG_NOW_P ERROR: \"$ERROR_CAUSE_P\""
    fi
    echo "$ERROR_MSG_NOW_P"
    echo ""
    f_close_section
    EZ_I_SKIP_ON_V=$EZ_I_S_ON_HOLDER
    exit 1
}

f_warning_msg() {
    : '"Printa" uma mensagem de aviso.

    Args:
        WARNING_P (str): aviso.
        ASK_FOR_CONT_P (Optional[int]): 1 - Checa se o usuário deseja 
    continuar com a instalação; 0 - Solicita que pressione "enter". 
    Padrão 0.
    '

    EZ_I_S_ON_HOLDER=$EZ_I_SKIP_ON_V
    EZ_I_SKIP_ON_V=0
    WARNING_P=$1
    ASK_FOR_CONT_P=$2
    if [ -z "$ASK_FOR_CONT_P" ] ; then
        ASK_FOR_CONT_P=0
    fi
    echo ""
    f_open_section "W A R N I N G !"
    echo "$WARNING_P"
    echo ""
    f_close_section
    if [ ${ASK_FOR_CONT_P} -eq 0 ] ; then
        f_enter_to_cont
    else
        f_continue
    fi
    EZ_I_SKIP_ON_V=$EZ_I_S_ON_HOLDER
}

f_continue() {
    : 'Questionar ao usuário se deseja continuar ou parar a instalação.

    Args:
        NOTE_P (Optional[str]): Informações adicionais ao usuário.
    '

    NOTE_P=$1
    f_div_section
    if [ -z "$NOTE_P" ] ; then
        NOTE_P=""
    else
        NOTE_P=" (NOTE: \"$NOTE_P\")"
    fi

    f_yes_no "CONTINUE? (USE \"n\" TO STOP THIS INSTALLER)$NOTE_P"
    f_div_section
    if [ ${YES_NO_R} -eq 0 ] ; then
        exit 0
    fi
}

F_PRESERVE_BLANK_LINES_R=""
f_preserve_blank_lines() {
    : 'Remove "single quotes" used to prevent blank lines being erroneously 
    removed.

    "single quotes" is used at the beginning and end of the strings to prevent 
    blank lines with no other characters in the sequence being erroneously 
    removed! We do not know the reason for this side effect! This problem 
    occurs, for example, in commands that involve "sed" and "awk". When the 
    text entry for "sed" ("sed -i") is a file the problem addressed here does 
    not occur.

    Args:
        STR_TO_TREAT_P (str): String to be treated.

    Returns:
        F_PRESERVE_BLANK_LINES_R (str): String treated.
    '

    F_PRESERVE_BLANK_LINES_R=""
    STR_TO_TREAT_P=$1
    STR_TO_TREAT_P=${STR_TO_TREAT_P%?}
    F_PRESERVE_BLANK_LINES_R=${STR_TO_TREAT_P#?}
}

# [Ref.: https://stackoverflow.com/a/48551138/3223785 ]
F_SPLIT_R=()
f_split() {
    : 'It does a "split" into a given string and returns an array.

    Args:
        TARGET_P (str): Target string to "split".
        DELIMITER_P (Optional[str]): Delimiter used to "split". If not 
    informed the split will be done by spaces.

    Returns:
        F_SPLIT_R (array): Array with the provided string separated by the 
    informed delimiter.
    '

    F_SPLIT_R=()
    TARGET_P=$1
    DELIMITER_P=$2
    if [ -z "$DELIMITER_P" ] ; then
        DELIMITER_P=" "
    fi

    REMOVE_N=1
    if [ "$DELIMITER_P" == "\n" ] ; then
        REMOVE_N=0
    fi

    # NOTE: This was the only parameter that has been a problem so far! 
    # By Questor
    # [Ref.: https://unix.stackexchange.com/a/390732/61742 ]
    if [ "$DELIMITER_P" == "./" ] ; then
        DELIMITER_P="[.]/"
    fi

    if [ ${REMOVE_N} -eq 1 ] ; then

        # NOTE: Due to bash limitations we have some problems getting the 
        # output of a split by awk inside an array and so we need to use 
        # "line break" (\n) to succeed. Seen this, we remove the line breaks 
        # momentarily afterwards we reintegrate them. The problem is that if 
        # there is a line break in the "string" informed, this line break will 
        # be lost, that is, it is erroneously removed in the output! 
        # By Questor
        TARGET_P=$(awk 'BEGIN {RS="dn"} {gsub("\n", "3F2C417D448C46918289218B7337FCAF"); printf $0}' <<< "${TARGET_P}")

    fi

    # NOTE: The replace of "\n" by "3F2C417D448C46918289218B7337FCAF" results 
    # in more occurrences of "3F2C417D448C46918289218B7337FCAF" than the 
    # amount of "\n" that there was originally in the string (one more 
    # occurrence at the end of the string)! We can not explain the reason for 
    # this side effect. The line below corrects this problem! By Questor
    TARGET_P=${TARGET_P%????????????????????????????????}

    SPLIT_NOW=$(awk -F "$DELIMITER_P" '{for(i=1; i<=NF; i++){printf "%s\n", $i}}' <<< "${TARGET_P}")

    while IFS= read -r LINE_NOW ; do
        if [ ${REMOVE_N} -eq 1 ] ; then
            LN_NOW_WITH_N=$(awk 'BEGIN {RS="dn"} {gsub("3F2C417D448C46918289218B7337FCAF", "\n"); printf $0}' <<< "'${LINE_NOW}'")
            f_preserve_blank_lines "$LN_NOW_WITH_N"
            LN_NOW_WITH_N="$F_PRESERVE_BLANK_LINES_R"
            F_SPLIT_R+=("$LN_NOW_WITH_N")
        else
            F_SPLIT_R+=("$LINE_NOW")
        fi
    done <<< "$SPLIT_NOW"
}

F_ABOUT_DISTRO_R=()
f_about_distro() {
    : 'Obter informações sobre a distro.

    Returns:
        F_ABOUT_DISTRO_R (array): Array com informações sobre a 
    distro na seguinte ordem: NAME, VERSION, BASED e ARCH.
    '

    F_ABOUT_DISTRO_R=()
    f_get_stderr_stdout "cat /etc/*-release"
    ABOUT_INFO=$F_GET_STDOUT_R

    if [[ $ABOUT_INFO == *"ID=debian"* ]] ; then
        f_split "$ABOUT_INFO" "\n"
        F_SPLIT_R_0=("${F_SPLIT_R[@]}")
        TOTAL_0=${#F_SPLIT_R_0[*]}
        for (( i=0; i<=$(( $TOTAL_0 -1 )); i++ )) ; do
            f_split "${F_SPLIT_R_0[$i]}" "="
            F_SPLIT_R_1=("${F_SPLIT_R[@]}")
            TOTAL_1=${#F_SPLIT_R_1[*]}
            for (( o=0; o<=$(( $TOTAL_1 -1 )); o++ )) ; do
                p=$[$o+1]
                case "${F_SPLIT_R_1[$o]}" in
                    "NAME")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_2=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_2[1]}")
                    ;;
                    "VERSION_ID")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_3=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_3[1]}")
                    ;;
                    *)
                        
                    ;;
                esac
            done
        done
        F_ABOUT_DISTRO_R+=("Debian")
    elif [[ $ABOUT_INFO == *"ID=\"sles\""* ]] ; then
        f_split "$ABOUT_INFO" "\n"
        F_SPLIT_R_0=("${F_SPLIT_R[@]}")
        TOTAL_0=${#F_SPLIT_R_0[*]}
        for (( i=0; i<=$(( $TOTAL_0 -1 )); i++ )) ; do
            f_split "${F_SPLIT_R_0[$i]}" "="
            F_SPLIT_R_1=("${F_SPLIT_R[@]}")
            TOTAL_1=${#F_SPLIT_R_1[*]}
            for (( o=0; o<=$(( $TOTAL_1 -1 )); o++ )) ; do
                p=$[$o+1]
                case "${F_SPLIT_R_1[$o]}" in
                    "NAME")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_2=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_2[1]}")
                    ;;
                    "VERSION_ID")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_3=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_3[1]}")
                    ;;
                    *)
                        
                    ;;
                esac
            done
        done
        F_ABOUT_DISTRO_R+=("Suse")
    elif [[ $ABOUT_INFO == *"ID=opensuse"* ]] || 
        [[ $ABOUT_INFO == *"ID_LIKE=\"suse\""* ]] ; then
        f_split "$ABOUT_INFO" "\n"
        F_SPLIT_R_0=("${F_SPLIT_R[@]}")
        TOTAL_0=${#F_SPLIT_R_0[*]}
        for (( i=0; i<=$(( $TOTAL_0 -1 )); i++ )) ; do
            f_split "${F_SPLIT_R_0[$i]}" "="
            F_SPLIT_R_1=("${F_SPLIT_R[@]}")
            TOTAL_1=${#F_SPLIT_R_1[*]}
            for (( o=0; o<=$(( $TOTAL_1 -1 )); o++ )) ; do
                p=$[$o+1]
                case "${F_SPLIT_R_1[$o]}" in
                    "NAME")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_1[$p]}")
                    ;;
                    "VERSION_ID")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_3=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_3[1]}")
                    ;;
                    *)
                        
                    ;;
                esac
            done
        done
        F_ABOUT_DISTRO_R+=("Suse")
    elif [[ $ABOUT_INFO == *"DISTRIB_ID=Ubuntu"* ]] || 
        [[ $ABOUT_INFO == *"ID_LIKE=debian"* ]] ; then
        f_split "$ABOUT_INFO" "\n"
        F_SPLIT_R_0=("${F_SPLIT_R[@]}")
        TOTAL_0=${#F_SPLIT_R_0[*]}
        for (( i=0; i<=$(( $TOTAL_0 -1 )); i++ )) ; do
            f_split "${F_SPLIT_R_0[$i]}" "="
            F_SPLIT_R_1=("${F_SPLIT_R[@]}")
            TOTAL_1=${#F_SPLIT_R_1[*]}
            for (( o=0; o<=$(( $TOTAL_1 -1 )); o++ )) ; do
                p=$[$o+1]
                case "${F_SPLIT_R_1[$o]}" in
                    "DISTRIB_ID")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_1[$p]}")
                    ;;
                    "DISTRIB_RELEASE")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_1[$p]}")
                    ;;
                    *)
                        
                    ;;
                esac
            done
        done
        F_ABOUT_DISTRO_R+=("Debian")
    elif [[ $ABOUT_INFO == *"CentOS release 6"* ]] ; then
        # NOTE: Para a geração CentOS 6.X! By Questor

        f_split "$ABOUT_INFO" "\n"
        F_SPLIT_R_0=("${F_SPLIT_R[1]}")
        f_split "${F_SPLIT_R_0[0]}" " "
        F_SPLIT_R_1=("${F_SPLIT_R[@]}")
        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_1[0]}")
        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_1[2]}")
        F_ABOUT_DISTRO_R+=("RedHat")
    elif [[ $ABOUT_INFO == *"CentOS Linux release 7"* ]] ; then
        # NOTE: Para a geração CentOS 7.X! By Questor

        f_split "$ABOUT_INFO" "\n"
        F_SPLIT_R_0=("${F_SPLIT_R[@]}")
        TOTAL_0=${#F_SPLIT_R_0[*]}
        for (( i=0; i<=$(( $TOTAL_0 -1 )); i++ )) ; do
            f_split "${F_SPLIT_R_0[$i]}" "="
            F_SPLIT_R_1=("${F_SPLIT_R[@]}")
            TOTAL_1=${#F_SPLIT_R_1[*]}
            for (( o=0; o<=$(( $TOTAL_1 -1 )); o++ )) ; do
                p=$[$o+1]
                case "${F_SPLIT_R_1[$o]}" in
                    "NAME")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_2=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_2[1]}")
                    ;;
                    "VERSION_ID")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_3=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_3[1]}")
                    ;;
                    *)
                        
                    ;;
                esac
            done
        done
        F_ABOUT_DISTRO_R+=("RedHat")
    elif [[ $ABOUT_INFO == *"Red Hat Enterprise Linux Server"* ]] || 
            [[ $ABOUT_INFO == *"VERSION_ID=\"7."* ]]; then
        # NOTE: Para a geração RHEL 7.X! By Questor

        f_split "$ABOUT_INFO" "\n"
        F_SPLIT_R_0=("${F_SPLIT_R[@]}")
        TOTAL_0=${#F_SPLIT_R_0[*]}
        for (( i=0; i<=$(( $TOTAL_0 -1 )); i++ )) ; do
            f_split "${F_SPLIT_R_0[$i]}" "="
            F_SPLIT_R_1=("${F_SPLIT_R[@]}")
            TOTAL_1=${#F_SPLIT_R_1[*]}
            for (( o=0; o<=$(( $TOTAL_1 -1 )); o++ )) ; do
                p=$[$o+1]
                case "${F_SPLIT_R_1[$o]}" in
                    "NAME")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_2=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_2[1]}")
                    ;;
                    "VERSION_ID")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_3=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_3[1]}")
                    ;;
                    *)
                        
                    ;;
                esac
            done
        done
        F_ABOUT_DISTRO_R+=("RedHat")
    elif [[ $ABOUT_INFO == *"Red Hat Enterprise Linux Server release "* ]] ; then
        f_split "$ABOUT_INFO" "\n"
        F_SPLIT_R_0=("${F_SPLIT_R[1]}")
        f_split "${F_SPLIT_R_0[0]}" " "
        F_SPLIT_R_1=("${F_SPLIT_R[@]}")
        F_ABOUT_DISTRO_R+=("Red Hat Enterprise Linux Server")
        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_1[6]}")
        F_ABOUT_DISTRO_R+=("RedHat")
    elif [[ $ABOUT_INFO == *"ID=fedora"* ]] ; then    
        f_split "$ABOUT_INFO" "\n"
        F_SPLIT_R_0=("${F_SPLIT_R[@]}")
        TOTAL_0=${#F_SPLIT_R_0[*]}
        for (( i=0; i<=$(( $TOTAL_0 -1 )); i++ )) ; do
            f_split "${F_SPLIT_R_0[$i]}" "="
            F_SPLIT_R_1=("${F_SPLIT_R[@]}")
            TOTAL_1=${#F_SPLIT_R_1[*]}
            for (( o=0; o<=$(( $TOTAL_1 -1 )); o++ )) ; do
                p=$[$o+1]
                case "${F_SPLIT_R_1[$o]}" in
                    "NAME")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_2=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_2[1]}")
                    ;;
                    "VERSION_ID")
                        f_split "${F_SPLIT_R_1[$p]}" "\""
                        F_SPLIT_R_3=("${F_SPLIT_R[@]}")
                        F_ABOUT_DISTRO_R+=("${F_SPLIT_R_3[1]}")
                    ;;
                    *)
                        
                    ;;
                esac
            done
        done
        F_ABOUT_DISTRO_R+=("RedHat")
    else
        F_ABOUT_DISTRO_R+=("Unknown")
        F_ABOUT_DISTRO_R+=("Unknown")
        F_ABOUT_DISTRO_R+=("Unknown")
    fi
    F_ABOUT_DISTRO_R+=($(arch))
}

F_IS_ROOT_R=1
f_is_root() {
    : 'Checar se o usuário é root.

    Args:
        CHK_ONLY_P (Optional[int]): 0 - Se não for root emite erro e encerra a execução; 
    1 - Apenas verifica e retorna o resultado. Padrão 0.

    Returns:
        F_IS_ROOT_R (int): 1 - É root; 0 - Não é root.
    '

    CHK_ONLY_P=$1
    if [ -z "$CHK_ONLY_P" ] ; then
        CHK_ONLY_P=0
    fi

    F_IS_ROOT_R=1
    if [[ $EUID -ne 0 ]]; then
        F_IS_ROOT_R=0
        if [ ${CHK_ONLY_P} -eq 0 ] ; then
            f_error_exit "You need to be root!"
        fi
    fi
}

F_CHK_DISTRO_STATUS_R=""
f_chk_distro_status() {
    : 'Verifica se a distro informada está subscrita e/ou registrada 
    e/ou ativa perante os recursos informados.

    Args:
        DISTRO_NAME_P (str): Nome da distro sobre a qual será executada 
    verificação.
        RESOURCES_ARR_P (array): Array com a lista de recursos a serem 
    verificados na distro alvo.

    Returns:
        F_CHK_DISTRO_STATUS_R (str): Possui a saída do comando de 
    verificação executado.
    '

    F_CHECK_RHEL_R=""
    DISTRO_NAME_P=$1
    RESOURCES_ARR_P=("${!2}")
    TOTAL_2=${#RESOURCES_ARR_P[*]}
    RES_OK_ARR=()
    REDHAT_ACTV=0

    CHK_RES_CMD=""
    if [ "$DISTRO_NAME_P" == "RedHat" ] ; then
        CHK_RES_CMD="subscription-manager list --consumed"
        f_get_stderr_stdout "$CHK_RES_CMD"
        F_CHK_DISTRO_STATUS_R=$F_GET_STDOUT_R

        # NOTE: To debug! By Questor
#         F_GET_STDOUT_R="No consumed subscription pools to list
# "

        if [[ $F_GET_STDOUT_R == *"No consumed subscription pools to list"* ]] ; then
            f_get_stderr_stdout "yum repolist"
            F_CHK_DISTRO_STATUS_R=$F_GET_STDOUT_R

            # NOTE: To debug! By Questor
#             F_GET_STDOUT_R="Loaded plugins: product-id, rhnplugin, security, subscription-manager
# This system is receiving updates from RHN Classic or RHN Satellite.
# repo id                            repo name                              status
# epel                               Extra Packages for Enterprise Linux 6  12125
# rhel-x86_64-server-6               Red Hat Enterprise Linux Server (v. 6  14725
# rhel-x86_64-server-optional-6      RHEL Server Optional (v. 6 64-bit x86_  8257
# rhel-x86_64-server-supplementary-6 RHEL Server Supplementary (v. 6 64-bit   483
# repolist: 35590
# "

            if [[ $F_GET_STDOUT_R == *"RHN Classic or Red Hat Satellite"* ]] ; then
                WAR_MSGS_STR="THE REDHAT IS APPARENTLY USING \"RHN Classic\" OR \"Red Hat Satellite\" TO ACCESS ITS RESOURCES!
THIS INSTALLER WILL NOT VALIDATE THESE RESOURCES!"
                WAR_MSGS_STR+=$'\n\n'"FOR MORE INFORMATION TRY: \"yum repolist\"."
                f_warning_msg "$WAR_MSGS_STR" 1
                return 0
            fi
        else
            f_split "$F_GET_STDOUT_R" "Subscription Name:"
        fi
    elif [ "$DISTRO_NAME_P" == "SLES" ] ; then
        CHK_RES_CMD="zypper sl"
        f_get_stderr_stdout "$CHK_RES_CMD"
        f_split "$F_GET_STDOUT_R" "\n"
        F_CHK_DISTRO_STATUS_R=$F_GET_STDOUT_R
    fi

    F_SPLIT_R_0=("${F_SPLIT_R[@]}")
    TOTAL_0=${#F_SPLIT_R_0[*]}
    for (( i=0; i<=$(( $TOTAL_0 -1 )); i++ )) ; do
        if [[ "$DISTRO_NAME_P" == "RedHat" ]] ; then
            f_split "${F_SPLIT_R_0[$i]}" "\n"
            F_SPLIT_R_1=("${F_SPLIT_R[@]}")
            TOTAL_1=${#F_SPLIT_R_1[*]}
            CHK_ACTV=0
            for (( o=0; o<=$(( $TOTAL_1 -1 )); o++ )) ; do
                if [[ "${F_SPLIT_R_1[$o]}" == "Provides:"* ]] ; then
                    CHK_ACTV=1
                fi
                if [ ${CHK_ACTV} -eq 1 ] ; then
                    for (( w=0; w<=$(( $TOTAL_2 -1 )); w++ )) ; do
                        if [[ "${F_SPLIT_R_1[$o]}" == *"${RESOURCES_ARR_P[$w]}" ]] ; then
                            RES_OK_ARR+=($w)
                            break
                        fi
                    done
                    if [ ${REDHAT_ACTV} -eq 0 ] && 
                            [[ "${F_SPLIT_R_1[$o]}" == "Active:"* ]] && 
                            [[ "${F_SPLIT_R_1[$o]}" == *"True" ]] ; then
                        REDHAT_ACTV=1
                    fi
                fi
            done
        elif [[ "$DISTRO_NAME_P" == "SLES" ]] ; then
            REDHAT_ACTV=1
            f_split "${F_SPLIT_R_0[$i]}" "|"
            F_SPLIT_R_1=("${F_SPLIT_R[@]}")
            for (( w=0; w<=$(( $TOTAL_2 -1 )); w++ )) ; do
                if [[ "${F_SPLIT_R_1[1]}" == *"${RESOURCES_ARR_P[$w]}"* ]] ; then
                    if [[ "${F_SPLIT_R_1[3]}" == *"Yes"* ]] ; then
                        if [[ "${F_SPLIT_R_1[5]}" == *"Yes"* ]] ; then
                            RES_OK_ARR+=($w)
                            break
                        fi
                    fi
                fi
            done
        fi
    done

    WARNINGS_MSGS=()
    TOTAL_3=${#RES_OK_ARR[*]}
    for (( z=0; z<=$(( $TOTAL_2 -1 )); z++ )) ; do
        RES_OK_NOW=1
        for (( t=0; t<=$(( $TOTAL_3 -1 )); t++ )) ; do
            if (( ${RES_OK_ARR[$t]} == $z )); then
                RES_OK_NOW=0
                break
            fi
        done
        if (( $RES_OK_NOW == 1 )); then
            WARNINGS_MSGS+=("$DISTRO_NAME_P does not have access to this resource: \"${RESOURCES_ARR_P[$z]}\".")
        fi
    done

    # NOTE: Essa verificação é específica para o SLES. Não encontrei uma forma 
    # melhor de fazê-la... mas funciona bem! By Questor
    if [[ "$DISTRO_NAME_P" == "SLES" ]] ; then
        CHK_RES_CMD=""
        f_get_stderr_stdout "zypper --non-interactive se hfsdfsdufnmfdns"
        f_split "$F_GET_STDERR_R" "\n"
        F_SPLIT_R_2=("${F_SPLIT_R[@]}")
        if [[ "${F_SPLIT_R_2[0]}" == *"Permission to access "* ]] && [[ "${F_SPLIT_R_2[0]}" == *" denied."* ]] ; then
            WARNINGS_MSGS+=("${F_SPLIT_R_2[0]}")
        fi
    fi

    TOTAL_4=${#WARNINGS_MSGS[*]}
    WAR_MSGS_STR=""
    USE_NEWLINE=""
    if [ ! $TOTAL_4 -eq 0 ] || [ $REDHAT_ACTV -eq 0 ]; then
        WAR_MSGS_STR="SOME PROBLEM APPEAR TO HAVE BEEN DETECTED ON"
        if [[ "$DISTRO_NAME_P" == "RedHat" ]] ; then
            WAR_MSGS_STR+=" REDHAT SUBSCRIPTION! "
        elif [[ "$DISTRO_NAME_P" == "SLES" ]] ; then
            WAR_MSGS_STR+=" SLES REGISTRATION! "
        fi
        WAR_MSGS_STR+="PLEASE CHECK IT!"
        for (( y=0; y<=$(( $TOTAL_4 -1 )); y++ )) ; do
            if (( $y == 0 )); then
                WAR_MSGS_STR+=$'\n\n'
            else
                USE_NEWLINE=$'\n'
            fi
            WAR_MSGS_STR+="$USE_NEWLINE -> ${WARNINGS_MSGS[$y]}"
        done
        if [ ! -z "$CHK_RES_CMD" ] ; then
            WAR_MSGS_STR+=$'\n\n'"FOR MORE INFORMATION TRY: \"$CHK_RES_CMD\"."
        fi
        f_warning_msg "$WAR_MSGS_STR" 1
    fi
}

F_STR_TRIM_R=""
f_str_trim(){
    : 'Remover caracteres em branco (espaços) antes e/ou depois da string 
    informada.

    Args:
        STR_VAL_P (str): String a ser ajustada.
        TRIM_MODE_P (Optional[int]): 0 - Remove à esquerda (leading); 1 - 
    Remove à direita (trailing); 2 - Remove em ambos os lados. Padrão 0.

    Returns:
        F_STR_TRIM_R (str): String ajustada.
    '

    STR_VAL_P=$1
    TRIM_MODE_P=$2
    if [ -z "$TRIM_MODE_P" ] ; then
        TRIM_MODE_P=0
    fi

    case $TRIM_MODE_P in
        0)
            STR_VAL_P="${STR_VAL_P#"${STR_VAL_P%%[![:space:]]*}"}"
        ;;
        1)
            STR_VAL_P="${STR_VAL_P%"${STR_VAL_P##*[![:space:]]}"}"
        ;;
        2)
            STR_VAL_P="${STR_VAL_P#"${STR_VAL_P%%[![:space:]]*}"}"
            STR_VAL_P="${STR_VAL_P%"${STR_VAL_P##*[![:space:]]}"}"
        ;;
    esac
    F_STR_TRIM_R="$STR_VAL_P"
}

F_SRV_MEMORY_R=0
f_srv_memory() {
    : 'Informar sobre a memória do servidor.

    Returns:
        F_SRV_MEMORY_R (int): Quantidade de memória RAM do servidor em KB.
    '

    f_get_stderr_stdout "cat /proc/meminfo"
    f_split "$F_GET_STDOUT_R" "\n"
    f_split "${F_SPLIT_R[0]}" "MemTotal:"
    f_split "${F_SPLIT_R[1]}" "kB"
    f_str_trim "${F_SPLIT_R[0]}" 2
    F_SRV_MEMORY_R=$F_STR_TRIM_R
}

F_GET_PERCENT_FROM_R=0
f_get_percent_from() {
    : 'Obter percentagem de um valor informado.

    Args:
        VAL_GET_PERCENT_P (int): Valor a partir do qual será obtida a 
            percentagem.
        PERCENT_VAL_P (int): Valor de percentagem a ser obtido.
        REM_FLOAT_POINT_P (Optional[int]): 0 - Não remove ponto flutuante; 1 - 
            Remove ponto flutuante (se o valor obtido for maior ou igual a 1). 
            2 - Remove ponto flutuante (se o valor obtido for maior ou igual a 
            1) e arredonda para o último dígito significativo. Padrão 1.

    Returns:
        F_GET_PERCENT_FROM_R (int): Porcentagem obtida.
    '

    VAL_GET_PERCENT_P=$1
    PERCENT_VAL_P=$2
    REM_FLOAT_POINT_P=$3
    if [ -z "$REM_FLOAT_POINT_P" ] ; then
        REM_FLOAT_POINT_P=1
    fi

    # NOTA: A estratégia abaixo foi utilizada pq o bash por padrão não 
    # permite cálculo de ponto flutuante! By Questor
    F_GET_PERCENT_FROM_R=$(awk '{printf("%.5f\n",($1*($2/100)))}' <<<" $VAL_GET_PERCENT_P $PERCENT_VAL_P ")

    F_GET_PERCENT_FROM_R=${F_GET_PERCENT_FROM_R}
    if [ ${REM_FLOAT_POINT_P} -ge 1 ] ; then

        # NOTA: Técnica para comparar valores com ponto flutuante! By Questor
        if [ $(awk '{printf($1 >= $2) ? 1 : 0}' <<<" $VAL_GET_PERCENT_P 1 ") -eq 1 ] ; then
            if [ ${REM_FLOAT_POINT_P} -eq 1 ] ; then

                # NOTA: A estratégia abaixo foi utilizada remover o ponto
                # flutuante (truncar)! By Questor
                F_GET_PERCENT_FROM_R=${F_GET_PERCENT_FROM_R%\.*}

            elif [ ${REM_FLOAT_POINT_P} -eq 2 ] ; then

                # NOTA: A estratégia abaixo foi utilizada para arredondar o
                # valor (Ex.: 10.7 -> 11, 10.5 -> 10, 10.4 -> 10...)!
                # By Questor
                F_GET_PERCENT_FROM_R=$(awk '{printf("%.0f\n", $1);}' <<<" $F_GET_PERCENT_FROM_R ")

            fi
        fi
    fi
}

F_BYTES_N_UNITS_R=0
f_bytes_n_units() {
    : 'Converter bytes entre suas diversas unidades.

    Args:
        F_VAL_TO_CONV (int): Valor em bytes a se convertido.
        F_FROM_UNIT (str): Unidade em que o valor está (B, KB, MB, GB, TB e PB).
        F_TO_UNIT (str): Unidade para a qual se quer converter o valor (B, KB, 
            MB, GB, TB e PB).

    Returns:
        F_BYTES_N_UNITS_R (int/float): Valor convertido para a unidade desejada.
    '

    # NOTE:
    # Unit               Equivalent
    # 1 kilobyte (KB)    1,024 bytes
    # 1 megabyte (MB)    1,048,576 bytes
    # 1 gigabyte (GB)    1,073,741,824 bytes
    # 1 terabyte (TB)    1,099,511,627,776 bytes
    # 1 petabyte (PB)    1,125,899,906,842,624 bytes
    # By Questor

    F_VAL_TO_CONV=$1
    F_FROM_UNIT=$2
    F_TO_UNIT=$3

    CONV_LOOPS=0
    UNIT_FACTOR_0=0
    while [ ${CONV_LOOPS} -le 1 ] ; do
        UNIT_FACTOR=0
        if [ ${CONV_LOOPS} -eq 0 ] ; then
            UNIT_NOW=$F_FROM_UNIT
        else
            UNIT_NOW=$F_TO_UNIT
        fi
        case "$UNIT_NOW" in
            B)
                UNIT_FACTOR=0
            ;;
            KB)
                UNIT_FACTOR=1
            ;;
            MB)
                UNIT_FACTOR=2
            ;;
            GB)
                UNIT_FACTOR=3
            ;;
            TB)
                UNIT_FACTOR=4
            ;;
            PB)
                UNIT_FACTOR=5
            ;;
        esac
        if [ ${CONV_LOOPS} -eq 0 ] ; then
            UNIT_FACTOR_0=$UNIT_FACTOR
        else
            UNIT_FACTOR=$(awk '{printf($1-$2)}' <<<" $UNIT_FACTOR_0 $UNIT_FACTOR ")
            F_VAL_TO_CONV=$(awk '{printf("%.5f\n",($1*(1024^$2)))}' <<<" $F_VAL_TO_CONV $UNIT_FACTOR ")
        fi
        ((CONV_LOOPS++))
    done

    # NOTE: Remover zeros denecessários (Ex.: 0.05000 -> 0.05)! By Questor
    F_VAL_TO_CONV=$(echo $F_VAL_TO_CONV | sed 's/0\{1,\}$//')

    # NOTE: Remover ponto flutuante quando não necessário (Ex.: 5.00000 -> 5)! 
    # By Questor
    if [ $(echo $F_VAL_TO_CONV | awk '$0-int($0){print 0;next}{print 1}') -eq 1 ] ; then
        F_VAL_TO_CONV=${F_VAL_TO_CONV%\.*}
    fi

    F_BYTES_N_UNITS_R=$F_VAL_TO_CONV
}

F_PROCS_QTT_R=0
f_procs_qtt() {
    : 'Determine the amount of processes on a server.

    Args:
        F_MULT_FACTOR (Optional[int]): Multiplying factor over the number of 
    processes on the server. Default 1.

    Returns:
        F_PROCS_QTT_R (int): Number of server processes multiplied by a factor 
    if informed.
    '

    F_MULT_FACTOR=$1
    if [ -z "$F_MULT_FACTOR" ] ; then
        F_MULT_FACTOR=1
    fi
    f_get_stderr_stdout "nproc"
    if [[ $F_GET_STDERR_R == "" ]]; then
        F_PROCS_QTT_R=$(( F_GET_STDOUT_R * F_MULT_FACTOR ))
    else
        f_enter_to_cont "An error occurred when trying to determine an appropriate amount of processes to use on this server! ERROR: \"$F_GET_STDERR_R$F_GET_STDOUT_R\"."
        f_error_exit
    fi
}

F_GET_UUID_R=""
f_get_uuid() {
    : 'Gerar e retornar um UUID.

    Args:
        REM_DASH_P (Optional[int]): 0 - Não remove os "-" (traços); 1 - 
    Remove os "-" (traços). Padrão 0.

    Returns:
        F_GET_UUID_R (str): UUID gerado.
    '

    REM_DASH_P=$1
    if [ -z "$REM_DASH_P" ] ; then
        REM_DASH_P=0
    fi
    F_GET_UUID_R=$(cat /proc/sys/kernel/random/uuid)
    if [ ${REM_DASH_P} -eq 1 ] ; then
        F_GET_UUID_R="${F_GET_UUID_R//-}"
    fi
}

# < --------------------------------------------------------------------------

# > --------------------------------------------------------------------------
# GRAFICO!
# --------------------------------------

f_indent() {
    : 'Definir uma tabulação para uma string informada.

    Exemplo de uso: echo "<STR_VALUE>" | f_indent 4

    Args:
        LEVEL_P (int): 2, 4 ou 8 espaços.
    '

    LEVEL_P=$1
    if [ ${LEVEL_P} -eq 2 ] ; then
        sed 's/^/  /';
    fi
    if [ ${LEVEL_P} -eq 4 ] ; then
        sed 's/^/    /';
    fi
    if [ ${LEVEL_P} -eq 8 ] ; then
        sed 's/^/        /';
    fi
}

f_open_main_section() {
    : 'Printar abertura de uma seção principal (agrupa outras seções).'

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    TITLE_P=$1
    echo "> =================================================================="
    if [ -n "$TITLE_P" ] ; then
        echo "$TITLE_P"
        f_div_section
        echo ""
    fi
}

f_close_main_section() {
    : 'Printar fechamento de uma seção principal (agrupa outras seções).'

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    echo "< =================================================================="
    echo ""
}

f_open_section() {
    : 'Printar abertura de uma seção.'

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    TITLE_P=$1
    echo "> ------------------------------------------------"
    if [ -n "$TITLE_P" ] ; then
        echo "$TITLE_P"
        f_div_section
        echo ""
    fi
}

f_close_section() {
    : 'Printar fechamento de uma seção.'

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    echo "< ------------------------------------------------"
    echo ""
}

f_div_section() {
    : 'Printar divisão em uma seção.'

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    echo "----------------------------------"
}

f_sub_section() {
    : 'Printar uma subseção.

    Args:
        TITLE_P (str): Título da subseção.
        TEXT_P (str): Texto da subseção.
    '

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    TITLE_P=$1
    TEXT_P=$2
    echo "> $TITLE_P" | f_indent 2
    echo ""
    echo "$TEXT_P" | f_indent 4
    echo ""
}

# < --------------------------------------------------------------------------

# > --------------------------------------------------------------------------
# APRESENTAÇÃO!
# --------------------------------------

F_BEGIN_R=0
f_begin() {
    : 'Printar uma abertura/apresentação para o instalador do produto.

    Usar no início da instalação.

    Args:
        TITLE_P (str): Título.
        VERSION_P (str): Versão do produto.
        ABOUT_P (str): Sobre o produto.
        WARNINGS_P (str): Avisos antes de continuar.
        COMPANY_P (str): Informações sobre a empresa.

    Returns:
        F_BEGIN_R (int): 0 - If is NOT a string that needs be paged; 1 - If is a 
    string that needs be paged. NOTE: Useful to control the execution of your script 
    and allow you control the flow of printed information on terminal.
    '

    clear
    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    TITLE_P=$1
    VERSION_P=$2
    ABOUT_P=$3
    WARNINGS_P=$4
    COMPANY_P=$5
    BEGIN_STR=$(f_open_section "$TITLE_P ($VERSION_P)"
    f_sub_section "ABOUT:" "$ABOUT_P"
    f_sub_section "WARNINGS:" "$WARNINGS_P"
    f_div_section
    echo "$COMPANY_P"
    f_close_section)
    f_print_long_str "$BEGIN_STR"
    if [ ${F_PRINT_LONG_STR_R} -eq 1 ] ; then
        clear
    fi
    F_BEGIN_R=$F_PRINT_LONG_STR_R
}

f_end() {
    : 'Printar uma fechamento/encerramento para o instalador do produto.

    Usar no final da instalação.

    Args:
        TITLE_P (str): Título.
        USEFUL_INFO_P (str): Informações úteis (uso básico etc...).
    '

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    TITLE_P=$1
    USEFUL_INFO_P=$2
    END_STR=$(f_open_section "$TITLE_P"
    f_sub_section "USEFUL INFORMATION:" "$USEFUL_INFO_P"
    f_close_section)
    f_print_long_str "$END_STR"
}

f_terms_licen() {
    : 'Printar os termos de licença/uso do produto.

    Pede que o usuário concorde com os termos.

    Args:
        TERMS_LICEN_P (str): Termos de licença/uso do produto.
    '

    clear
    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    TERMS_LICEN_P=$1
    TERMS_LICEN_P=$(
        f_open_section "LICENSE/TERMS:"
        echo "$TERMS_LICEN_P" | f_indent 2
    )
    f_print_long_str "$TERMS_LICEN_P"
    f_div_section
    TITLE_F="BY ANSWERING YES (y) YOU WILL AGREE WITH TERMS AND CONDITIONS "\
"PRESENTED! PROCEED?"
    f_yes_no "$TITLE_F"
    TITLE_F=""
    f_close_section
    sleep 1
    if [ ${YES_NO_R} -eq 0 ] ; then
        exit 0
    fi

}

F_INSTRUCT_R=0
f_instruct() {
    : 'Printar instruções sobre o produto.

    Args:
        INSTRUCT_P (str): Instruções sobre o produto.

    Returns:
        F_INSTRUCT_R (int): 0 - If is NOT a string that needs be paged; 1 - If is a 
    string that needs be paged. NOTE: Useful to control the execution of your script 
    and allow you control the flow of printed information on terminal.
    '

    if [ ${EZ_I_SKIP_ON_V} -eq 1 ] ; then
        return 0
    fi
    INSTRUCT_P=$1
    INSTRUCT_STR=$(f_open_section "INSTRUCTIONS:"
    echo "$INSTRUCT_P" | f_indent 2
    echo ""
    f_close_section)
    clear
    f_print_long_str "$INSTRUCT_STR"
    if [ ${F_PRINT_LONG_STR_R} -eq 1 ] ; then
        clear
    fi
    F_INSTRUCT_R=$F_PRINT_LONG_STR_R
}

# < --------------------------------------------------------------------------
