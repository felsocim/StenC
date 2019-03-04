#include "tos.h"

TOS * tos_alloc(void) {
  TOS * table = (TOS *) malloc(sizeof(TOS));
  if(!table) {
    return NULL;
  }

  table->data = (Symbol **) malloc(TOS_GROW_SIZE * sizeof(Symbol *));
  if(!table->data) {
    free(table);
    return NULL;
  }

  table->size = TOS_GROW_SIZE;
  table->index = 0;

  return table;
}

TOS * tos_append(TOS * table, Symbol * symbol) {
  if(!table || !symbol) {
    return NULL;
  }

  if(table->index >= table->size) {
    table->data = (Symbol **) realloc(table->data, table->size + TOS_GROW_SIZE);
    if(!table->data) {
      return NULL;
    }
  }

  table->data[table->index++] = symbol;

  return table;
}

Symbol * tos_lookup(const TOS * table, const char * identifier) {
  if(!table || !identifier) {
    return NULL;
  }

  for(size_t i = 0; i < table->index; i++) {
    if(!strcmp(table->data[i]->identifier, identifier)) {
      return table->data[i];
    }
  }

  return NULL;
}

void tos_free(TOS * table) {
  if(!table) {
    return;
  }

  for(size_t i = 0; i < table->index; i++) {
    sy_free(table->data[i]);
  }

  free(table->data);
  free(table);
}