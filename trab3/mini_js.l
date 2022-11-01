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
"if"     { yylval.c = vector<string>(); yylval.line = line; return IF; }
"else"   { yylval.c = vector<string>(); yylval.line = line; return ELSE; }
"while"  { yylval.c = vector<string>(); yylval.line = line; return WHILE; }
"for"    { yylval.c = vector<string>(); yylval.line = line; return FOR; }
"="      { yylval.c = vector<string>(1, "="); yylval.line = line; return EQUAL; }
";"      { yylval.c = vector<string>(1, ";"); yylval.line = line; return SEMICOLON; }
","      { yylval.c = vector<string>(1, ","); yylval.line = line; return COMMA; }
"{}"     { yylval.c = vector<string>(1, "{}"); yylval.line = line; return EMPTY_OBJ; }
"[]"     { yylval.c = vector<string>(1, "[]"); yylval.line = line; return EMPTY_ARR; }
"("      { yylval.c = vector<string>(1, "("); yylval.line = line; return OPEN_PAR; }
")"      { yylval.c = vector<string>(1, ")"); yylval.line = line; return CLOSE_PAR; }
"["      { yylval.c = vector<string>(1, "["); yylval.line = line; return OPEN_BRA; }
"]"      { yylval.c = vector<string>(1, "]"); yylval.line = line; return CLOSE_BRA; }
"{"      { yylval.c = vector<string>(1, "{"); yylval.line = line; return OPEN_CURLY; }
"}"      { yylval.c = vector<string>(1, "}"); yylval.line = line; return CLOSE_CURLY; }
"."      { yylval.c = vector<string>(1, "."); yylval.line = line; return DOT; }
"+"      { yylval.c = vector<string>(1, "+"); yylval.line = line; return PLUS; }
"-"      { yylval.c = vector<string>(1, "-"); yylval.line = line; return MINUS; }
"*"      { yylval.c = vector<string>(1, "*"); yylval.line = line; return MULT; }
"+="     { yylval.c = vector<string>{"+", "="}; yylval.line = line; return PLUS_EQUAL; }
"++"     { yylval.c = vector<string>(); yylval.line = line; return PLUS_PLUS; }
">"      { yylval.c = vector<string>(1, ">"); yylval.line = line; return GREATER; }
"<"      { yylval.c = vector<string>(1, "<"); yylval.line = line; return LESS; }
"=="     { yylval.c = vector<string>(1, "=="); yylval.line = line; return EQUAL_EQUAL; }

{WS}     { }
"\n"     { line++; }
{ID}     { yylval.c = vector<string>(1, yytext); yylval.line = line; return ID; }
.        { cerr << "Caractere invalido: " << (int)yytext[0] << endl; yylval.line = line; return yytext[0]; }

%%

