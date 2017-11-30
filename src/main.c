#include "../include/main.h"

const char * usage_message = "Usage: compiler";
const char * help_message = "Compiler Help Message";

Symbol * table = NULL;
Quad * list = NULL;

int main(int argc, char ** argv) {
  if(argc != 2)
    failwith("Argument(s) mismatch");

  yyparse();
  sy_print(table);
  qu_print(list);

  FILE * output = fopen(argv[1], "w+");

  if(output == NULL)
    failwith("Failed to open assembly output file");

  qu_assemble(list, table, output);

  fclose(output);

  sy_free(table);
  qu_free(list);

  return 0;
}
