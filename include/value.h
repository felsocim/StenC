#ifndef VALUE_H
#define VALUE_H

#include <stdio.h>
#include <stdlib.h>
#include <gmodule.h>

// Possible symbol value types
typedef enum {
  VALUE_INTEGER,
  VALUE_STRING,
  VALUE_ARRAY,
  VALUE_STENCIL,
  VALUE_FUNCTION,
  VALUE_LABEL
} ValueType;

// Union of supported symbol value data structures
typedef struct {
  union {
    int integer;
    char * string;
    struct {
      GArray * values,
             * sizes;
      size_t dimensions;
    } array;
  };
  ValueType type;
} Value;

Value * va_alloc(ValueType);
void va_print(const Value *);
void va_free(Value *);

#endif // VALUE_H
