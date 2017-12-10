#ifndef __SLIST_H
#define __SLIST_H
#define SL_GROW_SIZE 10

#include "common.h"
#include "value.h"
#include "tos.h"

typedef struct s_symbol_list {
  Symbol ** values;
  size_t size,
    next;
} SList;

size_t * sltost(SList *);
SList * sl_init(size_t);
SList * sl_grow(SList *);
SList * sl_insert(SList *, Symbol *);
SList * sl_concatenate(SList *, SList *);
void sl_free(SList *);

#endif // __SLIST_H
