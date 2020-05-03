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
    table->size += TOS_GROW_SIZE;
    table->data = (Symbol **) realloc(table->data, table->size * sizeof(Symbol *));
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

bool tos_exists(const TOS * table, const Symbol * symbol) {
  if(!table || !symbol) {
    return false;
  }

  for(size_t i = 0; i < table->index; i++) {
    if(!strcmp(table->data[i]->identifier, symbol->identifier)) {
      for(guint j = 0; j < symbol->scopes->len; j++) {
        for(guint k = 0; k < table->data[i]->scopes->len; k++) {
          if(symbol->scopes->data[j] == table->data[i]->scopes->data[k]) {
            printf("Symbol: %s already exists\n", symbol->identifier);
            return true;
          }
        }
      }
    }
  }

  printf("Symbol: %s does NOT exist\n", symbol->identifier);

  return false;
}

void tos_dump(const TOS * table) {
  if(!table) {
    printf("No symbols in table!\n");
    return;
  }

  printf("Identifier:\tType:\tDefined in scope(s):\tValue:\n");

  for(size_t i = 0; i < table->index; i++) {
    sy_print(table->data[i]);
  }
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