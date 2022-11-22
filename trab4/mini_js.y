%{
    #include <string>
    #include <iostream>
    #include <vector>
    #include <map>

    #ifndef DEBUG
    #define DEBUG 0
    #endif

    using namespace std;
        
    struct Attributes{
        vector<string> c;
        int line;

        Attributes& operator=(const vector<string>& v){
            c = v;
            return *this;
        }
    };

    #define YYSTYPE Attributes

    int yylex();
    int yyparse();
    void yyerror(const char *s);

    vector<string> conc(vector<string> a, vector<string> b);
    Attributes operator*(Attributes a, Attributes b);
    Attributes operator*(Attributes a, string b);
    Attributes operator*(string a, Attributes b);
    Attributes operator*(string a, string b);
    vector<string> toVector(string a);
    void checkVariableNew(Attributes a);
    void checkVariableExists(Attributes a);
    string generateLabel( string prefix );
    vector<string> resolve_enderecos( vector<string> entrada );
    void addScope();
    void removeScope();

    void printCode(Attributes a);

    
    vector<map<string,int>> variables;
    struct Attributes functions;
    int line = 1;
    int actualScope = -1;
    int actualParam = 0;
    vector<int> totalParamsFunction;
    int functionCalling = -1;
%}

%token NUM ID LET VAR CONST SEMICOLON COMMA DOT FUNCTION RETURN
%token STR EMPTY_OBJ EMPTY_ARR
%token EQUAL PLUS MINUS MULT DIV PLUS_EQUAL PLUS_PLUS
%token GREATER LESS EQUAL_EQUAL
%token IF ELSE WHILE FOR
%token OPEN_PAR CLOSE_PAR OPEN_BRA CLOSE_BRA OPEN_CURLY CLOSE_CURLY

%start S

%left GREATER LESS EQUAL_EQUAL
%left PLUS MINUS
%left MULT DIV
%right PLUS_PLUS
%right EQUAL

%right CLOSE_PAR ELSE 

%%

S : CMDs { if(DEBUG) cerr << "S -> CMDs" << endl; printCode($1); }
    ;

CMDs : { if(DEBUG) cerr << "CMDs -> " << endl; $$ = vector<string>(); }
     | CMD CMDs { if(DEBUG) cerr << "CMDs -> CMD CMDs" << endl; $$ = $1 * $2; }
;

CMD : LET DECLs SEMICOLON { if(DEBUG) cerr << "CMD -> LET DECLs SEMICOLON" << endl; $$ = $2; }
    | VAR DECLs SEMICOLON { if(DEBUG) cerr << "CMD -> VAR DECLs SEMICOLON" << endl; $$ = $2; }
    | CONST DECLs SEMICOLON { if(DEBUG) cerr << "CMD -> CONST DECLs SEMICOLON" << endl; $$ = $2; }
    | ATR SEMICOLON { if(DEBUG) cerr << "CMD -> ATR SEMICOLON" << endl; $$ = $1; }
    | EXPR SEMICOLON { if(DEBUG) cerr << "CMD -> EXPR SEMICOLON" << endl; $$ = $1 * "^"; }
    | RETURN RVALUE SEMICOLON { if(DEBUG) cerr << "CMD -> RETURN RVALUE SEMICOLON" << endl; $$ = $2 * "'&retorno'" * "@" * "~"; }
    | IF OPEN_PAR EXPR CLOSE_PAR CMD {
        if(DEBUG) cerr << "CMD -> IF OPEN_PAR EXPR CLOSE_PAR CMD" << endl;
        string labelIf = generateLabel("LABEL_IF");
        string labelEndIf = generateLabel("LABEL_END_IF");
        $$ = $3 * labelIf * "?" * labelEndIf * "#" * (":" + labelIf) * $5 * (":" + labelEndIf);
    }
    | IF OPEN_PAR EXPR CLOSE_PAR CMD ELSE CMD {
        if(DEBUG) cerr << "CMD -> IF OPEN_PAR EXPR CLOSE_PAR CMD ELSE CMD" << endl;
        string labelIf = generateLabel("LABEL_IF");
        string labelElse = generateLabel("LABEL_ELSE");
        string labelEndIf = generateLabel("LABEL_END_IF");
        $$ = $3 * labelIf * "?" * labelElse * "#" * (":" + labelIf) * $5 * labelEndIf * "#" * (":" + labelElse) * $7 * (":" + labelEndIf);
    }
    | WHILE OPEN_PAR EXPR CLOSE_PAR CMD {
        if(DEBUG) cerr << "CMD -> WHILE OPEN_PAR EXPR CLOSE_PAR CMD" << endl;
        string labelStartWhile = generateLabel("LABEL_START_WHILE");
        string labelEndWhile = generateLabel("LABEL_END_WHILE");
        string labelCodeWhile = generateLabel("LABEL_CODE_WHILE");
        $$ = (":" + labelStartWhile) * $3 * labelCodeWhile * "?" * labelEndWhile * "#" * (":" + labelCodeWhile) * $5 * labelStartWhile * "#" * (":" + labelEndWhile);
    }
    | FOR OPEN_PAR ATRs SEMICOLON EXPR SEMICOLON ATR CLOSE_PAR CMD {
        if(DEBUG) cerr << "CMD -> FOR OPEN_PAR ATRs SEMICOLON EXPR SEMICOLON ATR CLOSE_PAR CMD" << endl;
        string labelStartFor = generateLabel("LABEL_START_FOR");
        string labelEndFor = generateLabel("LABEL_END_FOR");
        string labelCodeFor = generateLabel("LABEL_CODE_FOR");
        $$ = $3 * (":" + labelStartFor) * $5 * labelCodeFor * "?" * labelEndFor * "#" * (":" + labelCodeFor) * $9 * $7 * labelStartFor * "#" * (":" + labelEndFor);
    }
    | FOR OPEN_PAR LET DECLs SEMICOLON EXPR SEMICOLON ATR CLOSE_PAR CMD {
        if(DEBUG) cerr << "CMD -> FOR OPEN_PAR LET DECLs SEMICOLON EXPR SEMICOLON ATR CLOSE_PAR CMD" << endl;
        string labelStartFor = generateLabel("LABEL_START_FOR");
        string labelEndFor = generateLabel("LABEL_END_FOR");
        string labelCodeFor = generateLabel("LABEL_CODE_FOR");
        $$ = $4 * (":" + labelStartFor) * $6 * labelCodeFor * "?" * labelEndFor * "#" * (":" + labelCodeFor) * $10 * $8 * labelStartFor * "#" * (":" + labelEndFor);
    }
    | FUNCTION ID OPEN_PAR { actualParam = 0; checkVariableExists($2); addScope(); } PARAMS CLOSE_PAR OPEN_CURLY CMDs CLOSE_CURLY {
        if(DEBUG) cerr << "CMD -> FUNCTION ID OPEN_PAR PARAMS CLOSE_PAR OPEN_CURLY " << endl;
        string labelStartFunction = generateLabel("LABEL_START_FUNCTION");
        functions = functions * (":" + labelStartFunction) * $5 * $8 * "undefined" * "@" * "'&retorno'" * "@" * "~";
        $$ = $2 * "&" * $2 * "{}" * "=" * "'&funcao'" * labelStartFunction * "[=]" * "^";
        removeScope();
    }
    | BLOCK { if(DEBUG) cerr << "CMD -> BLOCK" << endl; $$ = $1; }
    | SEMICOLON { if(DEBUG) cerr << "CMD -> SEMICOLON" << endl; $$ = vector<string>(); }
    ;

PARAMS : PARAMS_LIST { if(DEBUG) cerr << "PARAMS -> PARAMS_LIST" << endl; $$ = $1; }
       | { if(DEBUG) cerr << "PARAMS -> " << endl; $$ = vector<string>(); }
       ;

PARAMS_LIST : ID COMMA { checkVariableExists($1); actualParam++; } PARAMS {
            if(DEBUG) cerr << "PARAMS_LIST -> ID COMMA PARAMS_LIST" << endl;
            actualParam--;
            $$ = $1 * "&" * $1 * "arguments" * "@" * to_string(actualParam) * "[@]" * "=" * "^" * $4;
        }
       | ID {
            if(DEBUG) cerr << "PARAMS_LIST -> ID" << endl;
            checkVariableExists($1);
            $$ = $1 * "&" * $1 * "arguments" * "@" * to_string(actualParam) * "[@]" * "=" * "^";
        }
       ;

BLOCK : OPEN_CURLY {addScope();} CMD CMDs CLOSE_CURLY {
            if(DEBUG) cerr << "BLOCK -> OPEN_CURLY CMD CMDs CLOSE_CURLY" << endl;
            $$ = "<{" * $3 * $4 * "}>";
            removeScope();
        }
      ;

DECLs : DECL { if(DEBUG) cerr << "DECLs -> DECL" << endl; $$ = $1; }
      | DECLs COMMA DECL { if(DEBUG) cerr << "DECLs -> DECL COMMA DECLs" << endl; $$ = $1 * $3; }
     ;

DECL : ID { if(DEBUG) cerr << "DECL -> ID" << endl; checkVariableExists($1); $$ = $1 * "&"; }
     | ID EQUAL RVALUE { if(DEBUG) cerr << "DECL -> ID EQUAL RVALUE" << endl; checkVariableExists($1); $$ = $1 * "&" * $1 * $3 * $2 * "^"; }
     | ID FIELDS { if(DEBUG) cerr << "DECL -> ID FIELDS" << endl; checkVariableExists($1); $$ = $1 * "@"; }
     | ID FIELDS EQUAL RVALUE { if(DEBUG) cerr << "DECL -> ID FIELDS EQUAL RVALUE" << endl; checkVariableExists($1); $$ = $1 * "@" * $1 * $3 * $2 * "^"; }
     ;

FIELDS : DOT ID { if(DEBUG) cerr << "FIELDS -> DOT ID" << endl; $$ = $2; }
       | OPEN_BRA RVALUE CLOSE_BRA { if(DEBUG) cerr << "FIELDS -> OPEN_BRA RVALUE CLOSE_BRA" << endl; $$ = $2; }
       | DOT ID FIELDS { if(DEBUG) cerr << "FIELDS -> DOT ID FIELDS" << endl; $$ = $2 * "[@]" * $3; }
       | OPEN_BRA RVALUE CLOSE_BRA FIELDS { if(DEBUG) cerr << "FIELDS -> OPEN_BRA RVALUE CLOSE_BRA FIELDS" << endl; $$ = $2 * "[@]" * $4; }
       ;

ATRs : ATR { if(DEBUG) cerr << "ATRs -> ATR" << endl; $$ = $1; }
     | ATRs COMMA ATR { if(DEBUG) cerr << "ATRs -> ATR COMMA ATRs" << endl; $$ = $1 * $3; }
    ;

ATR : LVALUE EQUAL RVALUE { if(DEBUG) cerr << "ATR -> LVALUE EQUAL RVALUE" << endl; $$ = $1 * $3 * "=" * "^"; }
    | LVALUE PLUS_EQUAL RVALUE { if(DEBUG) cerr << "ATR -> LVALUE PLUS_EQUAL RVALUE" << endl; $$ = $1 * $1 * "@" * $3 * "+" * "=" * "^"; }
    | LVALUEPROP PLUS_EQUAL RVALUE { if(DEBUG) cerr << "ATR -> LVALUEPROP PLUS_EQUAL RVALUE" << endl; $$ = $1 * $1 * "[@]" * $3 * "+" * "[=]" * "^"; }
    | LVALUEPROP EQUAL RVALUE { if(DEBUG) cerr << "ATR -> LVALUEPROP EQUAL RVALUE" << endl; $$ = $1 * $3 * "[=]" * "^"; }
    ;

LVALUE : ID { if(DEBUG) cerr << "LVALUE -> ID" << endl; checkVariableNew($1); $$ = $1; }
       ;

LVALUEPROP : ID FIELDS { if(DEBUG) cerr << "LVALUEPROP -> ID FIELDS" << endl; checkVariableNew($1); $$ = $1 * "@" * $2; }
           ;

RVALUE : EXPR { if(DEBUG) cerr << "RVALUE -> EXPR" << endl; $$ = $1; }
       | LVALUE EQUAL RVALUE { if(DEBUG) cerr << "RVALUE -> LVALUE EQUAL RVALUE" << endl; $$ = $1 * $3 * $2; } 
       | LVALUEPROP EQUAL RVALUE { if(DEBUG) cerr << "RVALUE -> LVALUEPROP EQUAL RVALUE" << endl; $$ = $1 * $3 * "[=]"; }
       ;

EXPR : NUM { if(DEBUG) cerr << "EXPR -> NUM" << endl; $$ = $1; }
     | STR { if(DEBUG) cerr << "EXPR -> STR" << endl; $$ = $1; }
     | EMPTY_ARR { if(DEBUG) cerr << "EXPR -> EMPTY_ARR" << endl; $$ = $1; }
     | EMPTY_OBJ { if(DEBUG) cerr << "EXPR -> EMPTY_OBJ" << endl; $$ = $1; }
     | ID { if(DEBUG) cerr << "EXPR -> LVALUE" << endl; checkVariableNew($1); $$ = $1 * "@"; }
     | ID PLUS_PLUS { if(DEBUG) cerr << "EXPR -> ID PLUS_PLUS" << endl; $$ = $1 * $1 * "@" * "1" * "+" * "=" * "1" * "-"; }
     | ID FIELDS { if(DEBUG) cerr << "EXPR -> ID FIELDS" << endl; checkVariableNew($1); $$ = $1 * "@" * $2 * "[@]"; }
     | EXPR PLUS EXPR { if(DEBUG) cerr << "EXPR -> EXPR PLUS EXPR" << endl; $$ = $1 * $3 * $2; }
     | EXPR MINUS EXPR { if(DEBUG) cerr << "EXPR -> EXPR MINUS EXPR" << endl; $$ = $1 * $3 * $2; }
     | EXPR MULT EXPR { if(DEBUG) cerr << "EXPR -> EXPR MULT EXPR" << endl; $$ = $1 * $3 * $2; }
     | EXPR DIV EXPR { if(DEBUG) cerr << "EXPR -> EXPR DIV EXPR" << endl; $$ = $1 * $3 * $2; }
     | OPEN_PAR EXPR CLOSE_PAR { if(DEBUG) cerr << "EXPR -> OPEN_PAR EXPR CLOSE_PAR" << endl; $$ = $2; }
     | MINUS EXPR { if(DEBUG) cerr << "EXPR -> MINUS EXPR" << endl; $$ = "0" * $2 * "-"; }
     | EXPR GREATER EXPR { if(DEBUG) cerr << "EXPR -> EXPR GREATER EXPR" << endl; $$ = $1 * $3 * $2; }
     | EXPR LESS EXPR { if(DEBUG) cerr << "EXPR -> EXPR LESS EXPR" << endl; $$ = $1 * $3 * $2; }
     | EXPR EQUAL_EQUAL EXPR { if(DEBUG) cerr << "EXPR -> EXPR EQUAL_EQUAL EXPR" << endl; $$ = $1 * $3 * $2; }
     | FUNCTION_CALL { if(DEBUG) cerr << "EXPR -> FUNCTION_CALL" << endl; $$ = $1; }
     ;

FUNCTION_CALL : ID OPEN_PAR {checkVariableNew($1); functionCalling++; totalParamsFunction.push_back(0);} FUNCTION_CALL_PARAMS CLOSE_PAR {
                    if(DEBUG) cerr << "FUNCTION_CALL -> ID OPEN_PAR FUNCTION_CALL_PARAMS CLOSE_PAR" << endl;
                    $$ = $4 * to_string(totalParamsFunction[functionCalling]) * $1 * "@" * "$";
                    functionCalling--;
                    totalParamsFunction.pop_back();
                }
              ;

FUNCTION_CALL_PARAMS : FUNCTION_CALL_PARAMS_LIST { if(DEBUG) cerr << "FUNCTION_CALL_PARAMS -> FUNCTION_CALL_PARAMS_LIST" << endl; $$ = $1; }
                     | { if(DEBUG) cerr << "FUNCTION_CALL_PARAMS -> " << endl; $$ = vector<string>(); totalParamsFunction[functionCalling] = 0; }
                     ;

FUNCTION_CALL_PARAMS_LIST : RVALUE { if(DEBUG) cerr << "FUNCTION_CALL_PARAMS_LIST -> RVALUE" << endl; $$ = $1; totalParamsFunction[functionCalling]++; }
                          | RVALUE COMMA FUNCTION_CALL_PARAMS_LIST { if(DEBUG) cerr << "FUNCTION_CALL_PARAMS_LIST -> RVALUE COMMA FUNCTION_CALL_PARAMS_LIST" << endl; $$ = $1 * $3; totalParamsFunction[functionCalling]++; }
                          ;
%%

#include "lex.yy.c"

int main(){
    addScope();
    functions.c = vector<string>();
    yyparse();
    removeScope();
    return 0;
}

void yyerror(const char *s){
    cout << "Error: " << s << endl;
}

vector<string> conc(vector<string> a, vector<string> b){
    vector<string> c;
    for(string s : a){
        c.push_back(s);
    }
    for(string s : b){
        c.push_back(s);
    }
    return c;
}

Attributes operator*(Attributes a, Attributes b){
    Attributes c;
    c.c = conc(a.c, b.c);
    return c;
}

Attributes operator*(Attributes a, string b){
    Attributes c;
    c.c = conc(a.c, toVector(b));
    return c;
}

Attributes operator*(string a, Attributes b){
    Attributes c;
    c.c = conc(toVector(a), b.c);
    return c;
}

Attributes operator*(string a, string b){
    Attributes c;
    c.c = conc(toVector(a), toVector(b));
    return c;
}

vector<string> toVector(string a){
    return vector<string>(1, a);
}

void printCode(Attributes a){
    Attributes finalCode = a * "." * functions;
    vector<string> output = resolve_enderecos(finalCode.c);
    for(string s : output){
        cout << s << endl;
    }
}

void checkVariableNew(Attributes a){
    bool found = false;
    for(int i = actualScope; i >= 0; i--){
        if(variables[i].find(a.c[0]) != variables[i].end()){
            found = true;
            break;
        }
    }
    if(!found){
        cout << "Erro: a variável '" << a.c[0] << "' não foi declarada." << endl;
        exit(1);
    }
}

void checkVariableExists(Attributes a){
    if(DEBUG) cerr << actualScope << endl;
    if(variables[actualScope].find(a.c[0]) != variables[actualScope].end()){
        cout << "Erro: a variável '" << a.c[0] << "' já foi declarada na linha " << variables[actualScope][a.c[0]] << "." << endl;
        exit(1);
    }
    variables[actualScope][a.c[0]] = a.line;
}

void addScope(){
    actualScope++;
    variables.push_back(map<string, int>());
}

void removeScope(){
    actualScope--;
    variables.pop_back();
}

string generateLabel( string prefix ) {
  static int n = 0;
  return prefix + "_" + to_string( ++n ) + ":";
}

vector<string> resolve_enderecos( vector<string> entrada ) {
  map<string,int> label;
  vector<string> saida;
  for( int i = 0; i < entrada.size(); i++ ) 
    if( entrada[i][0] == ':' ) 
        label[entrada[i].substr(1)] = saida.size();
    else
      saida.push_back( entrada[i] );
  
  for( int i = 0; i < saida.size(); i++ ) 
    if( label.count( saida[i] ) > 0 )
        saida[i] = to_string(label[saida[i]]);
    
  return saida;
}
