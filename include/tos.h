#ifndef __TOS_H
#define __TOS_H
#define SYMBOL_TEMPORARY "temp"
#define ITOB(INT) (INT != 0 ? 1 : 0)

#include "common.h"
#include "value.h"

typedef struct s_table_of_symbols {
  char * identifier;
  bool constant;
  Type type;
  Value * value;
  struct s_table_of_symbols * next;
} Symbol;

Symbol * sy_alloc(void);
Symbol * sy_add_variable(Symbol *, const char *, bool, Type, Value *);
Symbol * sy_add_temporary(Symbol *, bool, Type, Value *);
Symbol * sy_add_label(Symbol *, const char *);
Symbol * sy_add_string(Symbol *, Value *);
Symbol * sy_lookup(Symbol *, const char *);
void sy_print(Symbol *);
void sy_free(Symbol *);

#endif
