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
    int line = 1;
    int actualScope = -1;
%}

%token NUM ID LET VAR CONST SEMICOLON COMMA DOT
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
    | EXPR SEMICOLON { if(DEBUG) cerr << "CMD -> EXPR SEMICOLON" << endl; $$.c = vector<string>(); }
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
    | BLOCK { if(DEBUG) cerr << "CMD -> BLOCK" << endl; $$ = $1; }
    | SEMICOLON { if(DEBUG) cerr << "CMD -> SEMICOLON" << endl; $$ = vector<string>(); }
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

ATR : ID EQUAL RVALUE { if(DEBUG) cerr << "ATR -> ID EQUAL RVALUE" << endl; checkVariableNew($1); $$ = $1 * $3 * $2 * "^"; }
    | ID PLUS_EQUAL RVALUE { if(DEBUG) cerr << "ATR -> ID PLUS_EQUAL RVALUE" << endl; checkVariableNew($1); $$ = $1 * $1 * "@" * $3 * $2 * "^"; }
    | ID FIELDS PLUS_EQUAL RVALUE { if(DEBUG) cerr << "ATR -> ID FIELDS PLUS_EQUAL RVALUE" << endl; checkVariableNew($1); $$ = $1 * "@" * $2 * $1 * "@" * $2 * "[@]" * $4 * "+" * "[=]" * "^"; }
    | ID FIELDS EQUAL RVALUE { if(DEBUG) cerr << "ATR -> ID FIELDS EQUAL RVALUE" << endl; checkVariableNew($1); $$ = $1 * "@" * $2 * $4 * "[=]" * "^"; }
    ;

RVALUE : EXPR { if(DEBUG) cerr << "RVALUE -> EXPR" << endl; $$ = $1; }
       | ID EQUAL RVALUE { if(DEBUG) cerr << "RVALUE -> ID EQUAL RVALUE" << endl; checkVariableNew($1); $$ = $1 * $3 * $2; } 
       | ID FIELDS EQUAL RVALUE { if(DEBUG) cerr << "RVALUE -> ID FIELDS EQUAL RVALUE" << endl; checkVariableNew($1); $$ = $1 * "@" * $2 * $4 * "[=]"; }
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
%%

#include "lex.yy.c"

int main(){
    addScope();
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
    vector<string> output = resolve_enderecos(a.c);
    for(string s : output){
        cout << s << endl;
    }
    cout << "." << endl;
}

void checkVariableNew(Attributes a){
    if(variables[actualScope].find(a.c[0]) == variables[actualScope].end()){
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
