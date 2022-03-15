#include "../include/qlist.h"

QList * ql_init(size_t size) {
  QList * list = (QList *) malloc(sizeof(QList));

  if(list == NULL)
    failwith("Failed to reserve memory for quad list");

  list->values = (Quad **) malloc(size * sizeof(Quad *));

  if(list->values == NULL)
    failwith("Failed to reserve memory for quad list's values array");

  list->size = size;
  list->next = 0;

  return list;
}

QList * ql_grow(QList * list) {
  if(list == NULL) {
    list = ql_init(QL_GROW_SIZE);
  } else {
    list->values = (Quad **) realloc(list->values, (list->size + QL_GROW_SIZE) * sizeof(Quad *));

    if(list->values == NULL)
      failwith("Failed to extend reserved memory for quad list's values array");

    list->size += QL_GROW_SIZE;
  }

  return list;
}

QList * ql_insert(QList * list, Quad * quad) {
  if(list == NULL)
    failwith("Failed to insert item to given quad list! The target list cannot be NULL");
  if(quad == NULL)
    failwith("Failed to insert item to given quad list! The item cannot be NULL");

  if(list->next >= list->size)
    list = ql_grow(list);

  list->values[list->next] = quad;
  list->next++;

  return list;
}

QList * ql_complete(QList * list, Symbol * symbol) {
  if(list == NULL)
    failwith("Failed to complete given quad list with given symbol! The target list cannot be NULL");
  if(symbol == NULL)
    failwith("Failed to complete given quad list with given symbol! The symbol cannot be NULL");

  size_t i = 0;

  for(i = 0; i < list->next; i++) {
    list->values[i]->result = symbol;
  }

  return list;
}

QList * ql_concatenate(QList * list1, QList * list2) {
  if(list1 == NULL || list2 == NULL)
    failwith("Failed to concatenate two quad lists! One or both are not initialized");

  if(list1->next == 0)
    return list2;
  if(list2->next == 0)
    return list1;

  size_t i = 0;

  for(i = 0; i < list2->next; i++) {
    list1 = ql_insert(list1, list2->values[i]);
  }

  ql_free(list2);

  return list1;  
}

void ql_free(QList * list) {
  if(list != NULL) {
    if(list->values != NULL)
      free(list->values);
    free(list);
  }
}
