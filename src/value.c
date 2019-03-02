#include "../include/value.h"
#include <string.h>

Value * va_alloc() {
  Value * value = (Value *) malloc(sizeof(Value));

  if(!value) {
    return NULL;
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
          printf("%d%s", value->array.values + i + j, (j < chunk_size - 1 ? ", " : ""));
        }
        printf("}%s", (i < value_count - 1 ? ", " : ""));
      }
      
      for(size_t i = 0; i < value->array.dimensions - 1; i++) {
        printf("}");
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
