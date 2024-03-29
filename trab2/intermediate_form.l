%{
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <map>

using namespace std;

int token;
string lexema;

void CMD();
void CMDs();
void P();
void A();
void E();
void T();
void F();
void E_linha();
void T_linha();
void EXP();
void EXP_linha();

void casa( int );

enum { tk_id = 256, tk_cte_num, tk_print, tk_str };

map<int,string> nome_tokens = {
  { tk_id, "nome de identificador" },
  { tk_cte_num, "constante inteira" }
};

%}

WS	[ \n\t]
DIGITO	[0-9]
LETRA	[A-Za-z_]

NUM	{DIGITO}+(\.{DIGITO}+)?
ID	{LETRA}({LETRA}|{DIGITO})*

STR1DQ \"(\\.|\"\"|[^"])*\"

PRINT [pP][rR][iI][nN][tT]

%%

{WS}  		{ }
{NUM} 		{ lexema = strdup(yytext); return tk_cte_num; }

{STR1DQ}	{ lexema = strdup(yytext); return tk_str; }

{PRINT}		{ lexema = strdup(yytext); return tk_print; }

{ID}		{ lexema = strdup(yytext); return tk_id; }

.		{ return yytext[0]; }

%%

// Funcoes auxiliares
int next_token() {
  return yylex();
}

void print( string s ) {
  cout << s << " ";
}

void erro( string s ) {
  cerr << "Erro: " << s << endl;
  exit(1);
}

string nome_token( int token ) {
  if( nome_tokens.find( token ) != nome_tokens.end() )
    return nome_tokens[token];
  else {
    string r;
    
    r = token;
    return r;
  }
}

int fatorial( int n ) {
  if( n == 0 )
    return 1;
  else
    return n * fatorial( n - 1 );
}

// Funcoes do analisador sintatico
void CMDs(){
  if(token){
    CMD();
    CMDs();
  }
}

void CMD(){
  switch(token){
    case tk_id: A(); casa( ';' ); break;
    case tk_print: casa( tk_print ); E(); casa( ';' ); print( "print #" ); break;
    default: erro( "nao e atribuicao ou print" );
  }
}

// Parametros de funcao
void PARAMS(){
  if(token != ')'){
    E();
    if(token == ','){
      casa( ',' );
      PARAMS();
    }
  }
}

// Atribuicao
void A() {
  string temp = lexema; 
  casa( tk_id );
  print( temp );
  casa( '=' );
  E();
  print( "=" );
}

// Soma e subtracao
void E() {
  T();
  E_linha();
}

void E_linha() {
  switch( token ) {
    case '+' : casa( '+' ); T(); print( "+" ); E_linha(); break;
    case '-' : casa( '-' ); T(); print( "-" ); E_linha(); break;
  }
}

// Multiplicacao e divisao
void T() {
  EXP();
  T_linha();
}

void T_linha() {
  switch( token ) {
    case '*' : casa( '*' ); EXP(); print( "*" ); T_linha(); break;
    case '/' : casa( '/' ); EXP(); print( "/" ); T_linha(); break;
  }
}

// Potenciacao
void EXP(){
  F();
  EXP_linha();
}

void EXP_linha(){
  switch( token ){
    case '^' : casa( '^' ); F(); EXP_linha(); print( "^" ); break;
  }
}

// Formula
void F() {
  string temp;
  switch( token ) {
    // Se id
    case tk_id:
      temp = lexema;
      casa( tk_id );
      if(token == '('){ // Se funcao
        casa( '(' );
        PARAMS();
        casa( ')' );
        print( temp + " #" );
      }else{ // Se variavel
        print( temp + " @" );
      }
      break;
    case tk_cte_num: // Se numero
      temp = lexema;
      casa( tk_cte_num ); print( temp );
      break;
    case tk_str: // Se string
      temp = lexema;
      casa( tk_str ); print( temp );
      break;
    case '(': casa( '(' ); E(); casa( ')' ); break;
    case '+': casa( '+' ); F(); break;
    case '-': // Menos unario
      casa( '-' );
      print( "0" );
      F();
      if(token == '^'){ // Se tem um expoente depois do menos unario
        casa('^');
        F();
        print( "^" );
      }
      print( "-" );
      break;
    default:
      erro( "Operando esperado, encontrado " + lexema );
  }
  if(token == '!'){ // Se tem fatorial
    casa( '!' );
    print( "fat #" );
  }
}


void casa( int esperado ) {
  if( token == esperado )
    token = next_token();
  else {
      cout << "Esperado " << nome_token( esperado ) 
	   << " , encontrado: " << nome_token( token ) << endl;
    exit( 1 );
  }
}

int main() {
  token = next_token();
  CMDs();
  return 0;
}
