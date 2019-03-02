#include "symbol.h"

Symbol * sy_alloc(void) {
  Symbol * table = (Symbol *) malloc(sizeof(Symbol));

  if(!table){
    return NULL;
  }

  table->identifier = NULL;
  table->scope = NULL;
  table->is_constant = false;
  table->value = NULL;

  return table;
}

Symbol * sy_variable(const char * identifier, bool is_constant, Value * value) {
  Symbol * symbol = sy_alloc();
  if(!symbol) {
    return NULL;
  }

  symbol->identifier = strdup(identifier);
  if(!symbol->identifier) {
    sy_free(symbol);
    return NULL;
  }

  symbol->is_constant = is_constant;
  symbol->value = value;

  return symbol;
}

Symbol * sy_temporary(bool is_constant, Value * value) {
  static int number = 0;

  size_t length = strlen(SY_TEMPORARY_PREFIX) + intlen(number);
  if(length > INT_MAX) {
    goto error;
  }

  char * name = (char *) malloc(length + 1);
  if(!name) {
    goto error;
  }

  if(snprintf(name, "%s%d", length, SY_TEMPORARY_PREFIX, number) != (int) length) {
    goto clean;
  }

  Symbol * temporary = sy_add_variable(name, is_constant, value);
  if(!temporary) {
    goto clean;
  }

  free(name);
  number++;

  return temporary;

clean:
  free(name);
error:
  return NULL;
}

Symbol * sy_label(const char * name) {
  Value * va_label = va_alloc();
  if(!va_label) {
    return NULL;
  }

  va_label->type = VALUE_LABEL;

  Symbol * label;
  if(name) {
    label = sy_variable(name, true, va_label);
  } else {
    label = sy_temporary(true, va_label);
  }

  return label;
}

bool sy_compare(const Symbol * __s1, const Symbol * __s2) {
  return !strcmp(__s1->identifier, __s2->identifier) && !strcmp(__s1->scope, __s2->scope);
}

void sy_print(const Symbol * symbol) {
  if(!symbol) {
    return;
  }

  printf("%s\t", symbol->identifier);

  switch(symbol->value->type) {
    case VALUE_INTEGER:
      printf("integer\t");
      break;
    case VALUE_STRING:
      printf("string\t");
      break;
    case VALUE_ARRAY:
      printf("array\t");
      break;
    case VALUE_FUNCTION:
      printf("function\t");
      break;
    case VALUE_LABEL:
      printf("label\t");
      break;
    default:
      return;
  }

  if(symbol->is_constant && symbol->value->type < VALUE_FUNCTION) {
    va_print(symbol->value);
  } else {
    printf("N/A");
  }

  printf("\n");
}

void sy_free(Symbol * symbol) {
  if(!symbol) {
    return;
  }

  free(symbol->identifier);
  free(symbol->scope);
  va_free(symbol->value);
}
