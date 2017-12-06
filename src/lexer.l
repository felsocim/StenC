/* Declaration C */
%{

#include <stdio.h>
#include <string.h>
#include "../include/common.h"
#include "../include/value.h"
#include "../include/tos.h"
#include "../include/quad.h"
#include "../include/qlist.h"
#include "../include/compiler.h"
%}

/* Declaration Lex */

%option nounput
%option noyywrap
%option noinput

identifier [a-zA-Z_]+[0-9a-zA-Z_]*
number     0|([1-9][0-9]*)
tab			\[[0-9]+\]


%%
main { return MAIN; }

return[ \t]0 { return END; }

int	{return INT; }

printi { return PRINTI; }

if { return IF; }		//STRUCTURE DE CONTROLE
else { return ELSE; }
while { return WHILE; }

{tab}	{	return TAB;}

{identifier} { yylval.name = strdup(yytext); return ID; }

{number} { yylval.value = atoi(yytext); return NUMBER; }

[\=\(\)\+\-\*]([\=]?) {
  if(strlen(yytext) > 1) {
    yylval.operator = stobo(yytext); printf ("Operator --> %s\n", yytext); return BOP_COMPARISON;
  }
  return yytext[0];
}

[ \t\n]	; //ignore les espaces et tabs

[,;{}] {return yytext[0];}

([\<\>\!])([\=]?) {
  printf("OP len %lu\n", strlen(yytext));
  if(strlen(yytext) == 1 && yytext[0] == '!') {
    printf ("Operator --> %s\n", yytext);
    return BOP_NOT;
  }
  yylval.operator = stobo(yytext); printf ("Operator --> %s\n", yytext); return BOP_COMPARISON;
}

\|\| { return BOP_OR; }

\&\& { return BOP_AND; }

. { printf("caractère %s non reconnu \n", yytext); } //<<EOF>> {return 0;}
