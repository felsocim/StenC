#ifndef SYMBOL_H
#define SYMBOL_H

// Prefix for temporary variables created during compilation
#define SY_TEMPORARY_PREFIX "temp"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <limits.h>
#include <gmodule.h>
#include "common.h"
#include "value.h"

// Definition of symbol data structure
typedef struct {
  char * identifier;
  GArray * scopes;
  bool is_constant;
  Value * value;
} Symbol;

Symbol * sy_alloc(void);
Symbol * sy_variable(const char *, bool, Value *);
Symbol * sy_temporary(bool, Value *);
Symbol * sy_label(const char *);
bool sy_equal(const Symbol *, const Symbol *);
void sy_print(const Symbol *);
void sy_free(Symbol *);

#endif // SYMBOL_H
