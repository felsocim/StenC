#include "../include/main.h"

const char * usage_message = "Usage: compiler";
const char * help_message = "Compiler Help Message";

Symbol * table = NULL;
Quad * list = NULL;

int main(void) {
  yyparse();
  sy_print(table);
  qu_print(list);
  sy_free(table);
  qu_free(list);

  return 0;
}
