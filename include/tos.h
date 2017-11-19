#ifndef __TOS_H
#define __TOS_H
#define ST_TEMPORARY_VARIABLE_NAME "temp"

#include "common.h"

typedef enum {
  ST_UNKNOWN_TYPE,
  ST_INTEGER_VALUE,
  ST_INTEGER_ARRAY
} SymbolType;

// Table of symbols structure definition
typedef struct s_table_of_symbols {
  char * identifier;
  bool constant;
  SymbolType type;
  void * value;
  struct s_table_of_symbols * next;
} Symbol;

char * sy_ttoc(SymbolType);
void sy_print_value(const void *, SymbolType);

Symbol * sy_alloc(void);
Symbol * sy_add_variable(Symbol *, char *, bool, SymbolType, void *);
Symbol * sy_add_temporary(Symbol *, SymbolType, void *);
Symbol * sy_lookup(Symbol *, char *);
void sy_print(Symbol *);
void sy_free(Symbol *);

#endif
