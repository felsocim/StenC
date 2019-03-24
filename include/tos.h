#ifndef TOS_H
#define TOS_H

// Everytime a new symbol is about to be inserted into the table of symbols, the size of the table will be increased by TOS_GROW_SIZE if there is no more space to insert the new symbol.
#define TOS_GROW_SIZE 10

#include "symbol.h"

// Definition of symbol list type
typedef struct {
  Symbol ** data;
  size_t size,
         index;
} TOS;

TOS * tos_alloc(void);
TOS * tos_append(TOS *, Symbol *);
Symbol * tos_lookup(const TOS *, const char *);
void tos_dump(const TOS *);
void tos_free(TOS *);

#endif // TOS_H
