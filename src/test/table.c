#include "../../include/tos.h"

const char * usage_message = "Usage error";
const char * help_message = "help_message";

int main(void) {
  Symbol * item = sy_alloc();
  SymbolValue value;
  value.Array.dimension = 2;
  value.Array.sizes = (size_t *) malloc(2 * sizeof(size_t));
  value.Array.sizes[0] = 3;
  value.Array.sizes[1] = 4;
  value.Array.array = (int *) malloc(12 *sizeof(int));
  item->value = value;
  size_t * c = (size_t *) calloc(2, sizeof(size_t));

  c[0] = 0;
  c[1] = 0;
  int * temp = sy_array_address(value, c);
  (*temp) = 1;

  c[0] = 0;
  c[1] = 1;
  temp = sy_array_address(value, c);
  (*temp) = 2;

  c[0] = 0;
  c[1] = 2;
  temp = sy_array_address(value, c);
  (*temp) = 3;

  c[0] = 0;
  c[1] = 3;
  temp = sy_array_address(value, c);
  (*temp) = 4;

  c[0] = 1;
  c[1] = 0;
  temp = sy_array_address(value, c);
  (*temp) = 5;

  c[0] = 1;
  c[1] = 1;
  temp = sy_array_address(value, c);
  (*temp) = 6;

  c[0] = 1;
  c[1] = 2;
  temp = sy_array_address(value, c);
  (*temp) = 7;

  c[0] = 1;
  c[1] = 3;
  temp = sy_array_address(value, c);
  (*temp) = 8;

  c[0] = 2;
  c[1] = 0;
  temp = sy_array_address(value, c);
  (*temp) = 9;

  c[0] = 2;
  c[1] = 1;
  temp = sy_array_address(value, c);
  (*temp) = 10;

  c[0] = 2;
  c[1] = 2;
  temp = sy_array_address(value, c);
  (*temp) = 11;

  c[0] = 2;
  c[1] = 3;
  temp = sy_array_address(value, c);
  (*temp) = 12;

  item->type = ST_INTEGER_ARRAY;
  item->identifier = malloc(7);
  item->identifier = strcpy(item->identifier, "skuska");
  item->constant = true;

  Symbol * item2 = sy_alloc();
  SymbolValue value2;
  value2.Array.dimension = 3;
  value2.Array.sizes = (size_t *) malloc(3 * sizeof(size_t));
  value2.Array.sizes[0] = 1;
  value2.Array.sizes[1] = 1;
  value2.Array.sizes[2] = 2;
  value2.Array.array = (int *) malloc(2 * sizeof(int));
  item2->value = value2;
  size_t * c2 = (size_t *) calloc(3, sizeof(size_t));

  c2[0] = 0;
  c2[1] = 0;
  c2[2] = 0;
  int * temp2 = sy_array_address(value2, c2);
  (*temp2) = 42;

  c2[0] = 0;
  c2[1] = 0;
  c2[2] = 1;
  temp2 = sy_array_address(value2, c2);
  (*temp2) = 43;

  item2->type = ST_INTEGER_ARRAY;
  item2->identifier = strdup("3Dpole");
  item2->constant = true;

  sy_print(item);

  sy_print(item2);

  sy_free(item);
  sy_free(item2);
  free(c);
  free(c2);

  return 0;
}
