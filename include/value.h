#ifndef __VALUE_H
#define __VALUE_H

#include "common.h"

typedef enum {
  TYPE_INTEGER,
  TYPE_ARRAY,
  TYPE_LABEL
} Type;

typedef union {
  int integer;
  struct {
    int * values;
    size_t * sizes;
    size_t dimensions;
  } array;
} Value;

char * ttos(Type);

Value * va_alloc();
void va_print(Value *, Type);
void va_free(Value *, Type);

int va_array_get(Value *, size_t *);
bool va_array_forward(size_t *, const size_t *, size_t);

#endif // __VALUE_H
