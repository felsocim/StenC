#include "main.h"

const char * usage_message = "Usage: compiler";
const char * help_message = "Compiler Help Message";

TOS * table_of_symbols = NULL;
ASTNode * AST = NULL;

int main(int argc, char ** argv) {
  if(argc != 2)
    failwith("Argument(s) mismatch");

  table_of_symbols = tos_alloc();

  yyin = fopen(argv[1], "r");

  if(!yyparse()) {
    ast_dump(AST);

    printf("AST verification %s\n", ast_verify(AST, table_of_symbols) ? "is OK!" : "failed!");

    printf("\nTABLE OF SYMBOLS FOLLOWS\n");
    tos_dump(table_of_symbols);

    // Clean-up
    tos_free(table_of_symbols);
    ast_node_free(AST);

    return 0;
  }

  return 1;
}
