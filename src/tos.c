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

  return NULL;
}

void sy_print_value(SymbolValue value, SymbolType type) {
  switch(type) {
    case ST_UNKNOWN_TYPE:
      printf("N/A");
      return;
    case ST_INTEGER_VALUE:
      printf("%d", value.integer);
      return;
    case ST_INTEGER_ARRAY:
      printf("|");

      size_t * current = (size_t *) calloc(value.Array.dimension, sizeof(size_t));

      do {
        printf(" %d |", (*sy_array_address(value, current)));
      } while (sy_array_iterator_increment(current, value.Array.sizes, value.Array.dimension));

      free(current);
      return;
  }

  failwith("Failed to determine symbol type");
}

int * sy_array_address(SymbolValue value, size_t * coordinates) {
  if(coordinates == NULL)
    failwith("Failed to determine array value address! Provided coordinates cannot be NULL");

  size_t shift = 0, temp = 1;
  size_t i = 0, j = 0;

#ifdef _DEBUG
  printf("getting [%lu][%lu]\n", coordinates[0], coordinates[1]);
#endif

  for(i = 0; i < value.Array.dimension; i++) {
    for(j = i + 1; j < value.Array.dimension; j++) {
      temp *= value.Array.sizes[j];
    }
    shift += coordinates[i] * temp;
    temp = 1;
  }

  return (value.Array.array + shift);
}

bool sy_array_iterator_increment(size_t * iterator, const size_t * sizes, size_t dimension) {
  int i = 0, final = 0;
  bool increment = false;

  for(i = (dimension - 1); i >= 0; i--) {
    if(iterator[i] < (sizes[i] - 1)) {
      iterator[i]++;
      increment = true;
      final = i;
      break;
    }
    increment = false;
  }

  if(increment) {
    if(final < (dimension - 1)) {
      for(i = (dimension - 1); i > final; i--)
        iterator[i] = 0;
    }

    return true;
  }

  return false;
}

Symbol * sy_alloc(void) {
  Symbol * table = (Symbol *) malloc(sizeof(struct s_table_of_symbols));

  if(table == NULL)
    failwith("Failed to reserve memory for a new entry of table of symbols");

  table->identifier = NULL;
  table->constant = false;
  table->type = ST_UNKNOWN_TYPE;
  table->next = NULL;

  return table;
}

Symbol * sy_add_variable(Symbol * table, const char * identifier, bool constant, SymbolType type, SymbolValue value) {
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

Symbol * sy_add_temporary(Symbol * table, SymbolType type, SymbolValue value) {
  static int number = 0;
  size_t temp_length = strlen(ST_TEMPORARY) + dlen(number);
  char * name = (char *) malloc((temp_length + 1) * sizeof(char));

  if(name == NULL)
    failwith("Failed to reserve memory for the identifier of a new temporary variable entry of given table of symbols");

  sprintf(name, "%s%d", ST_TEMPORARY, number);

  table = sy_add_variable(table, name, true, type, value);
  free(name);

  number++;

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
    printf("%s\t%s\t%s\t", temp->identifier, (temp->constant ? "constant" : "variable"), sy_ttoc(temp->type));
    if(temp->constant)
      sy_print_value(temp->value, temp->type);
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

    if(temp->type == ST_INTEGER_ARRAY) {
      free(temp->value.Array.array);
      free(temp->value.Array.sizes);
    }

    free(temp);
  }
}
