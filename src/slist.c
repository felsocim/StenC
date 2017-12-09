#include "../include/slist.h"

SList * sl_init(size_t size) {
  SList * list = (SList *) malloc(sizeof(SList));

  if(list == NULL)
    failwith("Failed to reserve memory for symbol list");

  list->values = (Symbol **) malloc(size * sizeof(Symbol *));

  if(list->values == NULL)
    failwith("Failed to reserve memory for symbol list's values array");

  list->size = size;
  list->next = 0;

  return list;
}

SList * sl_grow(SList * list) {
  if(list == NULL) {
    list = sl_init(SL_GROW_SIZE);
  } else {
    list->values = (Symbol **) realloc(list->values, (list->size + SL_GROW_SIZE) * sizeof(Symbol *));

    if(list->values == NULL)
      failwith("Failed to extend reserved memory for quad list's values array");

    list->size += SL_GROW_SIZE;
  }

  return list;
}

SList * sl_insert(SList * list, Symbol * symbol) {
  if(list == NULL)
    failwith("Failed to insert item to given symbol list! The target list cannot be NULL");
  if(symbol == NULL)
    failwith("Failed to insert item to given symbol list! The item cannot be NULL");

  if(list->next >= list->size)
    list = sl_grow(list);

  list->values[list->next] = symbol;
  list->next++;

  return list;
}

SList * sl_concatenate(SList * list1, SList * list2) {
  if(list1 == NULL || list2 == NULL)
    failwith("Failed to concatenate two symbol lists! One or both are not initialized");

  if(list1->next == 0)
    return list2;
  if(list2->next == 0)
    return list1;

    size_t i = 0;

  for(i = 0; i < list2->next; i++) {
    list1 = sl_insert(list1, list2->values[i]);
  }

  sl_free(list2);

  return list1;
}

void sl_free(SList * list) {
  if(list != NULL) {
    if(list->values != NULL)
      free(list->values);
    free(list);
  }
}
