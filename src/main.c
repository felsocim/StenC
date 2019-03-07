#include "../include/main.h"

const char * usage_message = "Usage: compiler";
const char * help_message = "Compiler Help Message";

TOS * table_of_symbols = NULL;
ASTNode * AST = NULL;

int main(int argc, char ** argv) {
  if(argc != 2)
    failwith("Argument(s) mismatch");

  table_of_symbols = tos_alloc();

  yyin = fopen(argv[1], "r");

  yyparse();
  
  tos_free(table_of_symbols);
  ast_node_free(AST);

  return 0;
}
