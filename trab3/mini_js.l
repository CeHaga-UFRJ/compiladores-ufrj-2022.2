WS      [\t ]
DIGITO     [0-9]
LETRA     [a-zA-Z_]
DOUBLE  {DIGITO}+("."{DIGITO}+)?
ID      {LETRA}({LETRA}|{DIGITO})*
STR1DQ \"(\\.|\"\"|[^"])*\"
STR1SQ \'(\\.|\'\'|[^'])*\'

%%

{DOUBLE} { yylval.c = vector<string>(1, yytext); yylval.line = line; return NUM; }
{STR1DQ} { yylval.c = vector<string>(1, yytext); yylval.line = line; return STR; }
{STR1SQ} { yylval.c = vector<string>(1, yytext); yylval.line = line; return STR; }

"let"    { yylval.c = vector<string>(1, "&"); yylval.line = line; return LET; }
"="      { yylval.c = vector<string>(1, "="); yylval.line = line; return EQUAL; }
";"      { yylval.c = vector<string>(1, ";"); yylval.line = line; return SEMICOLON; }
","      { yylval.c = vector<string>(1, ","); yylval.line = line; return COMMA; }
"{}"     { yylval.c = vector<string>(1, "{}"); yylval.line = line; return EMPTY_OBJ; }
"[]"     { yylval.c = vector<string>(1, "[]"); yylval.line = line; return EMPTY_ARR; }

{WS}     { }
"\n"     { line++; }
{ID}     { yylval.c = vector<string>(1, yytext); yylval.line = line; return ID; }
.        { cerr << "Caractere invalido: " << (int)yytext[0] << endl; yylval.line = line; return yytext[0]; }

%%

