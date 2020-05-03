/* C declarations */
%{
  #include <stdio.h>
  #include <string.h>
  #include "../include/common.h"
  #include "../include/ast.h"
  #include "../include/compiler.h"

  void consume_multiline_comment(void);
%}

/* Token definitions */

%option nounput
%option noyywrap
%option never-interactive

identifier        [a-zA-Z_][0-9a-zA-Z_]*
integer           0|([1-9][0-9]*)
string            \"(\\.|[^\\"])*\"
oneline_comment   \/\/[^\n]*
multiline_comment \/\*

%%

#define { ECHO; return DEFINE; }

return  { ECHO; return RETURN; }
int     { ECHO; return INT; }
stencil { ECHO; return STENCIL; }
void    { ECHO; return VOID; }
if      { ECHO; return IF; }
else    { ECHO; return ELSE; }
while   { ECHO; return WHILE; }
for     { ECHO; return FOR; }

{oneline_comment}   { ECHO; }

{multiline_comment} { consume_multiline_comment(); }

{identifier}        { ECHO; yylval.string = strdup(yytext); return IDENTIFIER; }

{integer}           { ECHO; yylval.integer = atoi(yytext); return INTEGER; }

{string}            { ECHO; yylval.string = strdup(yytext); return STRING; }

\<   { ECHO; return LESS; }
\<\= { ECHO; return LESS_OR_EQUAL; }
\>   { ECHO; return GREATER; }
\>\= { ECHO; return GREATER_OR_EQUAL; }

\!   { ECHO; return NOT; }
\&\& { ECHO; return AND; }
\|\| { ECHO; return OR; }
\!\= { ECHO; return NOTEQUAL; }
\=\= { ECHO; return EQUALEQUAL; }

\+\+ { ECHO; return PLUSPLUS; }
\-\- { ECHO; return MINUSMINUS; }
\+   { ECHO; return PLUS; }
\-   { ECHO; return MINUS; }
\*   { ECHO; return STAR; }
\/   { ECHO; return SLASH; }
\$   { ECHO; return DOLLAR; }
\=   { ECHO; return EQUAL; }

\( { ECHO; return LEFT_PARENTHESIS; }
\) { ECHO; return RIGHT_PARENTHESIS; }
\[ { ECHO; return LEFT_BRACKET; }
\] { ECHO; return RIGHT_BRACKET; }
\{ { ECHO; return LEFT_BRACE; }
\} { ECHO; return RIGHT_BRACE; }

\, { ECHO; return COMMA; }
\; { ECHO; return COLON; }

[ \t\n] { ECHO; } // Skip spaces.

. { printf("Syntax error: Could not recognize token '%s'!\n", yytext); } // Fail on any unrecognized token.

%%

void consume_multiline_comment(void) {
  char current;
  while((current = input()) != '*' && current != '\0') {}

  if(current == '\0' || input() == '/') {
    return;
  } else {
    consume_multiline_comment();
  }
}