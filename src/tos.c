#include "../include/tos.h"

char * sy_ttoc(SymbolType type) {
  switch(type) {
    case ST_UNKNOWN_TYPE:
      return "unknown";
    case ST_INTEGER_VALUE:
      return "integer";
    case ST_INTEGER_ARRAY:
      return "array of integers";
  }

  failwith("Failed to determine symbol type");
}

void sy_print_value(const void * value, SymbolType type) {
  switch(type) {
    case ST_UNKNOWN_TYPE:
      printf("N/A");
      return;
    case ST_INTEGER_VALUE:
      printf("%d", (int) (*value));
      return;
    case ST_INTEGER_ARRAY:
      size_t l
  }
}

Symbol * sy_alloc(void) {
  Symbol * table = (Symbol *) malloc(sizeof(struct s_table_of_symbols));

  if(table == NULL)
    failwith("Failed to reserve memory for a new entry of table of symbols");

  table->identifier = NULL;
  table->constant = false;
  table->type = ST_UNKNOWN_TYPE;
  table->value = NULL;
  table->next = NULL;

  return table;
}

Symbol * sy_add_variable(Symbol * table, const char * identifier, bool constant, SymbolType type, const void * value) {
  Symbol * symbol = sy_alloc();

  symbol->identifier = strdup(identifier);

  if(symbol->identifier == NULL)
    failwith("Failed to copy the identifier for a new entry of given table of symbols");

  symbol->constant = constant;
  symbol->type = type;
  symbol->value = memcpy(symbol->value, value, (size_t) sizeof(*value));
  symbol->next = table;

  return symbol;
}

Symbol * sy_add_temporary(Symbol * table, SymbolType type, const void * value) {
  static int number = 0;
  size_t temp_length = strlen(ST_TEMPORARY_VARIABLE_NAME) + strlen(itoa(number));
  char * name = (char *) malloc((temp_length + 1) * sizeof(char));

  if(name == NULL)
    failwith("Failed to reserve memory for the identifier of a new temporary variable entry of given table of symbols");

  if(snprintf(name, temp_length, "%s%d", ST_TEMPORARY_VARIABLE_NAME, number) != temp_length)
    failwith("Failed to compose the name for new temporary variable");

  table = sy_add_variable(table, name, true, type, value);
  free(name);

  return table;
}

Symbol * sy_lookup(const Symbol * table, const char * identifier) {
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

void sy_print(const Symbol * symbol) {
  if(table == NULL) {
    printf("Empty symbol set\n");
    return;
  }

  Symbol * temp = symbol;

  while(temp != NULL) {
    printf("%s\t%s\t%s\t", temp->identifier, (temp->constant ? "true" : "false"), );
    // Print value

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

    if(temp->value != NULL)
      free(temp->value);

    free(temp);
  }
}
