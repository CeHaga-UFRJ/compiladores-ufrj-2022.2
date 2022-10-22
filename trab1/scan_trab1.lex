%{
    #include <iostream>
    #include <string>
    string lexema;

    void printError(string error){
        cout << "Erro: Identificador inválido: " << error << endl;
    }
%}

/* Coloque aqui definições regulares */

/* Básicos */
LET [a-zA-Z_]
DIG [0-9]

/* Números */
INT 0|([1-9]{DIG}*)
FLOAT {INT}(\.{DIG}*)?([eE][+-]?{INT})?

/* Identificador válido */
ID ({LET}|"$")(({LET}|{DIG}|"@")*({LET}|{DIG})({LET}|{DIG}|"@")*)?
/* Identificador inválido 1 - Começa com @*/
ID_INV1 "@"({LET}|{DIG}|"@")*
/* Identificador inválido 2 - Contém apenas $ e @*/
ID_INV2 "$"("@")+
/* Identificador inválido 3 - Contém $ no meio*/
ID_INV3 ({LET}|{DIG}|"@"|"$")(({LET}|{DIG}|"@")*"$"({LET}|{DIG}|"@")*)+
/* Identificador inválido 4 - Começa com dígito*/
ID_INV4 {DIG}({LET}|{DIG}|"@")*
/* Junção dos identificadores inválidos */
ID_INV ({ID_INV1}|{ID_INV2}|{ID_INV3}|{ID_INV4})

/* Strings */
STR1DQ \"(\\.|\"\"|[^"])*\"
STR1SQ \'(\\.|\'\'|[^'])*\'

/* Comentários simples */
CMT1 \/\/.*

/* Comandos */
FOR [fF][oO][rR]
IF [iI][fF]
MAIG ">="
MEIG "<="
IG "=="
DIF "!="
WS	[ \t\n]

/* Estados */
%x X_CMT2
%x X_STR2
%x X_EXP_STR2

%%
    /* Padrões e ações. Nesta seção, comentários devem ter um tab antes */

    /* Comentários */
"/*"                { BEGIN(X_CMT2); lexema = yytext; /* Entra no estado de comentário */ }
<X_CMT2>"*/"        { BEGIN(INITIAL); lexema += yytext; return _COMENTARIO; /* Sai do estado de comentário e retorna */ }
<X_CMT2>.           { lexema += yytext; /* Salva os caracteres dentro do comentário */ }
<X_CMT2>{WS}        { lexema += yytext; /* Inclusive espaços em branco */ }
{CMT1}	            { lexema = yytext; return _COMENTARIO; /* Comentários simples */ } 

    /* Strings */
"`"                 { BEGIN(X_STR2); lexema = ""; /* Entra no estado de string e zera o lexema */ }
<X_STR2>"${"        { BEGIN(X_EXP_STR2); return _STRING2; /* Sai do estado de string para o estado de variável interna e retorna a string lida */ }
<X_STR2>"`"         { BEGIN(INITIAL); return _STRING2; /* Sai do estado de string e retorna a string lida */ }
<X_STR2>.           { lexema += yytext; /* Salva os caracteres dentro da string */ }
<X_STR2>{WS}        { lexema += yytext; /* Inclusive espaços em branco */ }
<X_EXP_STR2>{ID}    { lexema = yytext; return _EXPR; /* Retorna a variável lida */ }
<X_EXP_STR2>"}"     { BEGIN(X_STR2); lexema = ""; /* Volta para a string e apaga o lexema */ }
{STR1DQ}	        { lexema = yytext; lexema = lexema.substr(1, lexema.length() - 2); return _STRING; /* Strings simples com aspas duplas */ }
{STR1SQ}	        { lexema = yytext; lexema = lexema.substr(1, lexema.length() - 2); return _STRING; /* Strings simples com aspas simples */ }

    /* Números */
{INT}	            { lexema = yytext; return _INT; }
{FLOAT}	            { lexema = yytext; return _FLOAT; }

    /* Comandos */
{FOR}               { lexema = yytext; return _FOR; }
{IF}                { lexema = yytext; return _IF; }
{MAIG}              { lexema = yytext; return _MAIG; }
{MEIG}              { lexema = yytext; return _MEIG; }
{IG}                { lexema = yytext; return _IG; }
{DIF}               { lexema = yytext; return _DIF; }

{WS}	            { /* ignora espaços, tabs e '\n' */ } 

    /* Identificadores */
{ID_INV}            { printError(yytext); }
{ID}	            { lexema = yytext; return _ID; }

.                   { lexema = yytext; return *yytext; 
          /* Essa deve ser a última regra. Dessa forma qualquer caractere isolado será retornado pelo seu código ascii. */ }

%%

/* Não coloque nada aqui - a função main é automaticamente incluída na hora de avaliar e dar a nota. */
