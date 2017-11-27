/* Declaration C */
%{

#include <stdio.h>
#include <string.h>
#include "../include/compiler.h"
%}

/* Declaration Lex */

%option nounput
%option noyywrap

identifier [a-zA-Z_]+[0-9a-zA-Z_]*
number     [1-9][0-9]*
tab			\[[0-9]+\]

%%
main {printf ("indentificateur special main\n");
		return MAIN;}

return[ \t]0 { printf("fin du main\n");
			return END;}

int	{printf("identificateur special int\n") ;
		return INT;}

{tab}	{
			printf("tableau de %u elements\n", (unsigned int) yytext[1]);
			return TAB;}

{identifier} { printf("identificateur : %s \n", yytext);
				return ID; }

{number}    { printf("integer : %d \n", atoi(yytext));
		yylval.valeur = atoi(yytext);
                 return NUMBER; }

[=()+\-\*]     { printf("operator number : %d \n", yytext[0] );
               return yytext[0]; }

[ \t\n]	; //ignore les espaces et tabs

[,;{}] {return yytext[0];}

.           { printf("caractère %s non reconnu \n", yytext); } //<<EOF>> {return 0;}
