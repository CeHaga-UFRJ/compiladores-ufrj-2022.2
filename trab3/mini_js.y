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

    map<string,int> variables;
    int line = 1;

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

    void printCode(Attributes a);
%}

%token NUM ID LET EQUAL SEMICOLON COMMA STR EMPTY_OBJ EMPTY_ARR

%start S

%right EQUAL

%%

S : CMDs { if(DEBUG) cerr << "S -> CMDs" << endl; printCode($1); }
    ;

CMDs : { if(DEBUG) cerr << "CMDs -> " << endl; $$ = vector<string>(); }
     | CMD SEMICOLON CMDs { if(DEBUG) cerr << "CMDs -> CMD SEMICOLON CMDs" << endl; $$ = $1 * $3; }
;

CMD : LET DECLs { if(DEBUG) cerr << "CMD -> LET DECLs" << endl; $$ = $2; }
    | ATR { if(DEBUG) cerr << "CMD -> ATR" << endl; $$ = $1; }
    ;

DECLs : DECL { if(DEBUG) cerr << "DECLs -> DECL" << endl; $$ = $1; }
      | DECLs COMMA DECL { if(DEBUG) cerr << "DECLs -> DECL COMMA DECLs" << endl; $$ = $1 * $3; }
     ;

DECL : ID { if(DEBUG) cerr << "DECL -> ID" << endl; checkVariableExists($1); $$ = $1 * "&"; }
     | ID EQUAL RVALUE { if(DEBUG) cerr << "DECL -> ID EQUAL RVALUE" << endl; checkVariableExists($1); $$ = $1 * "&" * $1 * $3 * $2 * "^"; }
     ;

ATR : ID EQUAL RVALUE { if(DEBUG) cerr << "ATR -> ID EQUAL RVALUE" << endl; checkVariableNew($1); $$ = $1 * $3 * $2 * "^"; }
    ;
LVALUE : ID { if(DEBUG) cerr << "LVALUE -> ID" << endl; $$ = $1; }
       ;

RVALUE : EXPR { if(DEBUG) cerr << "RVALUE -> EXPR" << endl; $$ = $1; }
       | LVALUE { if(DEBUG) cerr << "RVALUE -> LVALUE" << endl; $$ = $1; }
       | ID EQUAL RVALUE { if(DEBUG) cerr << "RVALUE -> ID EQUAL RVALUE" << endl; checkVariableNew($1); $$ = $1 * $3 * $2; } 
       ;

EXPR : NUM { if(DEBUG) cerr << "EXPR -> NUM" << endl; $$ = $1; }
     | STR { if(DEBUG) cerr << "EXPR -> STR" << endl; $$ = $1; }
     | EMPTY_ARR { if(DEBUG) cerr << "EXPR -> EMPTY_ARR" << endl; $$ = $1; }
     | EMPTY_OBJ { if(DEBUG) cerr << "EXPR -> EMPTY_OBJ" << endl; $$ = $1; }
%%

#include "lex.yy.c"

int main(){
    yyparse();
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
    for(string s : a.c){
        cout << s << endl;
    }
    cout << "." << endl;
}

void checkVariableNew(Attributes a){
    if(variables.find(a.c[0]) == variables.end()){
        cout << "Erro: a variável '" << a.c[0] << "' não foi declarada." << endl;
        exit(1);
    }
}

void checkVariableExists(Attributes a){
    if(variables.find(a.c[0]) != variables.end()){
        cout << "Erro: a variável '" << a.c[0] << "' já foi declarada na linha " << variables[a.c[0]] << "." << endl;
        exit(1);
    }
    variables[a.c[0]] = a.line;
}
