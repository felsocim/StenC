#include "../include/value.h"

char * ttos(Type type) {
  switch(type) {
    case TYPE_INTEGER:
      return "integer";
    case TYPE_ARRAY:
      return "array";
    case TYPE_LABEL:
      return "label";
    case TYPE_STRING:
      return "string";
  }

  return NULL;
}

Value * va_alloc() {
  Value * value = (Value *) malloc(sizeof(Value));

  if(value == NULL)
    failwith("Failed to reserve memory for new value");

  return value;
}

void va_print(Value * value, Type type) {
  if(value == NULL)
    failwith("Failed to print value content! Pointer to the given value cannot be NULL");

  switch(type) {
    case TYPE_INTEGER:
      printf("%d", value->integer);
      break;
    case TYPE_ARRAY:
      printf("|");

      size_t * current = (size_t *) calloc(value->array.dimensions, sizeof(size_t));

      do {
        printf(" %d |", va_array_get(value, current));
      } while (va_array_forward(current, value->array.sizes, value->array.dimensions));

      free(current);
      break;
    case TYPE_STRING:
      printf("%s", value->string);
      break;
    default:
      failwith("Failed to determine symbol type");
  }
}

void va_free(Value * value, Type type) {
  if(value != NULL) {
    if(type == TYPE_ARRAY) {
      if(value->array.values != NULL)
        free(value->array.values);

      if(value->array.sizes != NULL)
        free(value->array.sizes);
    }
    if(type == TYPE_STRING && value->string != NULL)
      free(value->string);

    free(value);
  }
}


int va_array_get(Value * value, size_t * address) {
  if(address == NULL)
    failwith("Failed to determine array value address! Provided coordinates cannot be NULL");

  size_t shift = 0, temp = 1;
  size_t i = 0, j = 0;

#ifdef _DEBUG
  printf("getting [%lu][%lu]\n", address[0], address[1]);
#endif

  for(i = 0; i < value->array.dimensions; i++) {
    for(j = i + 1; j < value->array.dimensions; j++) {
      temp *= value->array.sizes[j];
    }
    shift += address[i] * temp;
    temp = 1;
  }

  return *(value->array.values + shift);
}

bool va_array_forward(size_t * iterator, const size_t * sizes, size_t dimensions) {
  int i = 0, final = 0;
  bool increment = false;

  for(i = (dimensions - 1); i >= 0; i--) {
    if(iterator[i] < (sizes[i] - 1)) {
      iterator[i]++;
      increment = true;
      final = i;
      break;
    }
    increment = false;
  }

  if(increment) {
    if(final < (dimensions - 1)) {
      for(i = (dimensions - 1); i > final; i--)
        iterator[i] = 0;
    }

    return true;
  }

  return false;
}
