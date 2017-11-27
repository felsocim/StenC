%{
  // YACC
  #include "../include/common.h"
  #include "../include/tos.h"
  #include "../include/quad.h"
  int yylex();
  void yyerror(char*);
  const char * usage_message = "Usage: compiler";
  const char * help_message = "Compiler Help Message";
%}

%union{
int valeur;
}

%token <valeur> NUMBER ID INT TAB MAIN END
//%type <valeur> addition soustraction multiplication division
%left '+' '-'

%%

init:
	INT MAIN '(' ')' '{'  S END ';' '}' {printf("reconnaissance du main...\n");}
	;

// Symbole de depart

S:
	S S
	| INT V ';'
	| A ';'
	| M ';'
	;

// declaration de variable;

V:
	 ID '=' A
	|  ID T
	| ID ',' I
	;

I:
	I ',' I
	| ID
	;

// tableau

T:
	TAB
	| TAB T
	;

// expressiosn arithmetiques
A:
	A '+' A {printf("addition de deux termes\n");}
	| A '-' A {printf("soustracion\n");}
	| A '*' A {printf("multiplication\n");}
	| A '/' A {printf("division\n");}
	| '(' A ')'
	| NUMBER
	| ID
	;
// affectation

M:
	ID '=' A
	| ID T '=' A {printf("test fatigue\n");}
%%

int main(){
printf("Debut de l'analyse syntaxique !\n");
return yyparse();
}
