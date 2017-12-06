#include "../include/tos.h"

Symbol * sy_alloc(void) {
  Symbol * table = (Symbol *) malloc(sizeof(struct s_table_of_symbols));

  if(table == NULL)
    failwith("Failed to reserve memory for a new entry of table of symbols");

  table->identifier = NULL;
  table->constant = false;
  table->type = TYPE_INTEGER;
  table->value = NULL;
  table->next = NULL;

  return table;
}

Symbol * sy_add_variable(Symbol * table, const char * identifier, bool constant, Type type, Value * value) {
  Symbol * symbol = sy_alloc();

  symbol->identifier = strdup(identifier);

  if(symbol->identifier == NULL)
    failwith("Failed to copy the identifier for a new entry of given table of symbols");

  symbol->constant = constant;
  symbol->type = type;
  symbol->value = value;
  symbol->next = table;

  return symbol;
}

Symbol * sy_add_temporary(Symbol * table, bool constant, Type type, Value * value) {
  static int number = 0;
  size_t temp_length = strlen(SYMBOL_TEMPORARY) + dlen(number);
  char * name = (char *) malloc((temp_length + 1) * sizeof(char));

  if(name == NULL)
    failwith("Failed to reserve memory for the identifier of a new temporary variable entry of given table of symbols");

  sprintf(name, "%s%d", SYMBOL_TEMPORARY, number);

  table = sy_add_variable(table, name, constant, type, value);
  free(name);

  number++;

  return table;
}

Symbol * sy_add_label(Symbol * table, const char * name) {
  if(name != NULL) {
    table = sy_add_variable(table, name, true, TYPE_LABEL, NULL);
  } else {
    table = sy_add_temporary(table, true, TYPE_LABEL, NULL);
  }

  return table;
}

Symbol * sy_lookup(Symbol * table, const char * identifier) {
  if(table == NULL)
    return NULL;

  if(identifier == NULL)
    failwith("Failed to seek for requested entry in given table of symbols! Provided identifier cannot be NULL");

  Symbol * temp = table;

  while(temp != NULL) {
    if(strcmp(temp->identifier, identifier) == 0)
      return temp;

    temp = temp->next;
  }

  return NULL;
}

void sy_print(Symbol * symbol) {
  if(symbol == NULL) {
    printf("Empty symbol set\n");
    return;
  }

  Symbol * temp = symbol;

  while(temp != NULL) {
    printf("%s\t%s\t%s\t", temp->identifier, (temp->constant ? "constant" : "variable"), ttos(temp->type));

    if(temp->constant && temp->type != TYPE_LABEL)
      va_print(temp->value, temp->type);
    else
      printf("N/A");

    printf("\n");

    temp = temp->next;
  }
}

void sy_free(Symbol * symbol) {
  if(symbol == NULL)
    return;

  while(symbol != NULL) {
    Symbol * temp = symbol;

    symbol = symbol->next;
    temp->next = NULL;

    if(temp->identifier != NULL)
      free(temp->identifier);

    va_free(temp->value, temp->type);

    free(temp);
  }
}
