/* Declaration C */
%{

#include <stdio.h>
#include <string.h>
#include "../include/common.h"
#include "../include/tos.h"
#include "../include/quad.h"
#include "../include/compiler.h"
%}

/* Declaration Lex */

%option nounput
%option noyywrap
%option noinput

identifier [a-zA-Z_]+[0-9a-zA-Z_]*
number     [1-9][0-9]*
tab			\[[0-9]+\]


%%
main {return MAIN;}

return[ \t]0 {return END;}

int	{return INT;}

print	{	return PRINT;}

if {	printf("if lu merci lex\n");
	return IF;}		//STRUCTURE DE CONTROLE
else	{return ELSE;}
while {return WHILE;}

{tab}	{	return TAB;}

{identifier} { yylval.name = strdup(yytext);
				return ID; }

{number}    { yylval.value = atoi(yytext);
                 return NUMBER; }

[=()+\-\*]     { return yytext[0]; }

[ \t\n]	; //ignore les espaces et tabs

[,;{}] {return yytext[0];}

== {printf("test a la con\n");
	return OPBOOL; }

[(==)(<=)(>=)(!=)<>] {printf("opbool lu %s\n",yytext);
			if (strlen(yytext) == 2){
				//yylval.value= yytext[0] + yytext[1];	
				return  OPBOOL;}
			else{
				//yylval.value= yytext[0];
				return OPBOOL;}
			} 

.           { printf("caractère %s non reconnu \n", yytext); } //<<EOF>> {return 0;}

