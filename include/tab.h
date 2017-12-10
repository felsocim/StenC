#ifndef __TAB_H
#define __TAB_H
#include "common.h"

typedef struct elemlist{
  int number;
  struct elemlist* next;
} elemList;

typedef struct{
  elemList* listFirst;
  elemList* listEnd;
  size_t size;
} intList;

intList * intListCreate();
intList * intListPushBack(intList* il,int n);
intList * intListConcat(intList* l1, intList* l2);
int intListGet(intList * list, size_t index);
void print_intList(intList* l1);

#endif
