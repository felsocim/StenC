#ifndef __TOS_H
#define __TOS_H
#define ST_TEMPORARY "temp"
#define ST_INTEGER_LENGTH 4

#include "common.h"

typedef enum {
  ST_UNKNOWN_TYPE,
  ST_INTEGER_VALUE,
  ST_INTEGER_ARRAY
} SymbolType;

typedef union {
  int integer;
  struct {
    int * array;
    size_t * sizes;
    size_t dimension;
  } Array;
} SymbolValue;

// Table of symbols structure definition
typedef struct s_table_of_symbols {
  char * identifier;
  bool constant;
  SymbolType type;
  SymbolValue value;
  struct s_table_of_symbols * next;
} Symbol;

char * sy_ttoc(SymbolType);
void sy_print_value(SymbolValue, SymbolType);

int * sy_array_address(SymbolValue, size_t *);
bool sy_array_iterator_increment(size_t *, const size_t *, size_t);

Symbol * sy_alloc(void);
Symbol * sy_add_variable(Symbol *, const char *, bool, SymbolType, SymbolValue);
Symbol * sy_add_temporary(Symbol *, SymbolType, SymbolValue);
Symbol * sy_lookup(Symbol *, const char *);
void sy_print(Symbol *);
void sy_free(Symbol *);

#endif
