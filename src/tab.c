#include "../include/tab.h"

intList * intListCreate(){
  intList * il = (intList*) malloc(sizeof(intList));
  if(il == NULL)
    printf("Failed to reserve memory for new list");
  il->listFirst = NULL;
  il->listEnd = NULL;
  il->size = 0;
  return il;
}

intList * intListPushBack(intList* il,int n){
  elemList* newElem = (elemList*) malloc(sizeof(elemList));
  newElem->number = n;
  newElem->next = NULL;
  if(il->size == 0 && il->listFirst == NULL){
    il->listFirst = newElem;
    il->listEnd = newElem;
  }
  else{
    il->listEnd->next = newElem;
    il->listEnd = newElem;
  }
  il->size++;
  return il;
}

intList * intListConcat(intList* l1, intList* l2){
  l1->listEnd->next = l2->listFirst;
  l1->listEnd = l2->listEnd;
  l1->size += l2->size;
  free(l2);
  return l1;
}

int intListGet(intList * list, size_t index) {
  if(list->size < 1)
    failwith("Failed to get integer list value at given index! The target list is empty");

  if(index >= list->size)
    failwith("Failed to get integer list value at given index! The required index is out of given list's bounds");

  size_t c = 0;

  elemList * tmp = list->listFirst;

  while(tmp != NULL && c != index){
    c++;
    tmp = tmp->next;
  }

  return tmp->number;
}

void print_intList(intList* il){
  printf("liste : ");
  elemList* tmp = il->listFirst;
  while(tmp != NULL){
    printf("%d,",tmp->number);
    tmp = tmp->next;
  }
  printf("\n");
}
