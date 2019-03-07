#include "../include/value.h"
#include <string.h>

Value * va_alloc(ValueType type) {
  Value * value = (Value *) malloc(sizeof(Value));

  if(!value) {
    return NULL;
  }

  value->type = type;

  if(type == VALUE_ARRAY || type == VALUE_STENCIL) {
    value->array.values = NULL;
    value->array.sizes = NULL;
    value->array.dimensions = 0;
  }

  if(type == VALUE_STRING) {
    value->string = NULL;
  }

  return value;
}

void va_print(const Value * value) {
  switch(value->type) {
    case VALUE_INTEGER:
      printf("%d", value->integer);
      break;
    case VALUE_STRING:
      printf("%s", value->string);
      break;
    case VALUE_ARRAY:
    case VALUE_STENCIL: {
        size_t value_count = 1, chunk_size = value->array.sizes[value->array.dimensions - 1];
        for(size_t i = 0; i < value->array.dimensions; i++) {
          value_count *= value->array.sizes[i];
          if(i < value->array.dimensions - 1) {
            printf("{");
          }
        }

        for(size_t i = 0; i < value_count; i += chunk_size) {
          printf("{ ");
          for(size_t j = 0; j < chunk_size; j++) {
            printf("%d%s", *(value->array.values + i + j), (j < chunk_size - 1 ? ", " : ""));
          }
          printf("}%s", (i < value_count - 1 ? ", " : ""));
        }
        
        for(size_t i = 0; i < value->array.dimensions - 1; i++) {
          printf("}");
        }
      }
      break;
    case VALUE_FUNCTION:
    case VALUE_LABEL:
    default:
      return;
  }
}

void va_free(Value * value) {
  if(!value) { // Value has already been freed or has never been allocated.
    return;
  }

  switch(value->type) {
    case VALUE_STRING:
      free(value->string);
      break;
    case VALUE_ARRAY:
    case VALUE_STENCIL:
      free(value->array.values);
      free(value->array.sizes);
      break;
    case VALUE_INTEGER:
    case VALUE_LABEL:
    case VALUE_FUNCTION:
    default:
      break;
  }

  free(value);
}
