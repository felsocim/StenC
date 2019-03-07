/* C declarations */
%{
  #include <stdio.h>
  #include <string.h>
  #include "../include/common.h"
  #include "../include/ast.h"
  #include "../include/compiler.h"
%}

/* Token definitions */

%option nounput
%option noyywrap
%option noinput

identifier [a-zA-Z_][0-9a-zA-Z_]*
integer    0|([1-9][0-9]*)
string     \"[\'0-9a-zA-Z ]*\"

%%

return  { return RETURN; }
int     { return INT; }
stencil { return STENCIL; }
void    { return VOID; }
if      { return IF; }
else    { return ELSE; }
while   { return WHILE; }
for     { return FOR; }

{identifier} { yylval.string = strdup(yytext); printf("Pojeb sa\n"); return IDENTIFIER; }

{integer} { yylval.integer = atoi(yytext); return INTEGER; }

{string} { yylval.string = strdup(yytext); return STRING; }

\<   { return LESS; }
\<\= { return LESS_OR_EQUAL; }
\>   { return GREATER; }
\>\= { return GREATER_OR_EQUAL; }

\!   { return NOT; }
\&\& { return AND; }
\|\| { return OR; }
\=\= { return EQUALEQUAL; }

\+\+ { return PLUSPLUS; }
\-\- { return MINUSMINUS; }
\+   { return PLUS; }
\-   { return MINUS; }
\*   { return STAR; }
\/   { return SLASH; }
\$   { return DOLLAR; }
\=   { return EQUAL; }

\( { return LEFT_PARENTHESIS; }
\) { return RIGHT_PARENTHESIS; }
\[ { return LEFT_BRACKET; }
\] { return RIGHT_BRACKET; }
\{ { return LEFT_BRACE; }
\} { return RIGHT_BRACE; }

\, { return COMMA; }
\; { return COLON; }

[ \t\n] ; // Skip spaces.

. { printf("Syntax error: Could not recognize token '%s'!\n", yytext); } // Fail on unrecognized token.
