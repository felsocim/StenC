/* C declarations */
%{
  #include <stdio.h>
  #include <string.h>
  #include "../include/common.h"
  #include "../include/value.h"
  #include "../include/tos.h"
  #include "../include/quad.h"
  #include "../include/qlist.h"
  #include "../include/tab.h"
  #include "../include/slist.h"
  #include "../include/compiler.h"
%}

/* Token definitions */

%option nounput
%option noyywrap
%option noinput

identifier        [a-zA-Z_]+[0-9a-zA-Z_]* { identifier } { yylval.string = strdup(yytext); return IDENTIFIER; }
integer            0|([1-9][0-9]*) { integer } { yylval.integer = atoi(yytext); return INTEGER; }
array_initializer \{([ \t\n]*{integer}[ \t\n]*,)*([ \t\n]*{integer})[ \t\n]*\} { array_initializer } { return ARRAY_INITIALIZER; }
string            \"[\'0-9a-zA-Z ]*\" { string } { yylval.string = strdup(yytext); return STRING; }

%%

return  { return RETURN; }
int     { return INT; }
stencil { return STENCIL; }
if      { return IF; }
else    { return ELSE; }
while   { return WHILE; }
for     { return FOR; }

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
