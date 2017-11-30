#include "../include/quad.h"

char * qu_otoc(Operation operation) {
  switch(operation) {
    case OP_ADD:
      return "+";
    case OP_SUBTRACT:
      return "-";
    case OP_UMINUS:
      return "UM";
    case OP_MULTIPLY:
      return "*";
    case OP_DIVIDE:
      return "/";
    case OP_LT:
      return "<";
    case OP_LE:
      return "<=";
    case OP_EQ:
      return "==";
    case OP_GE:
      return ">=";
    case OP_GT:
      return ">";
    case OP_GOTO:
      return "goto";
    case OP_ASSIGN:
      return "=";
    case OP_CALL_PRINT:
      return "print";
    case OP_UNDEFINED:
      return "N/A";
    default:
      failwith("Unknown operation type detected");
  }

  return NULL;
}

Quad * qu_generate(void) {
  Quad * quad = (Quad *) malloc(sizeof(struct s_quad));

  if(quad == NULL)
    failwith("Failed to reserve memory for new quad");

  quad->op = OP_UNDEFINED;
  quad->arg1 = NULL;
  quad->arg2 = NULL;
  quad->result = NULL;
  quad->next = NULL;

  return quad;
}

Quad * qu_concatenate(Quad * list1, Quad * list2) {
  if(list1 == NULL)
    return list2;

  if(list2 == NULL)
    return list1;

  Quad * temp = list1;

  while(temp->next != NULL) {
    temp = temp->next;
  }

  temp->next = list2;

  return list1;
}

void qu_print(Quad * quad) {
  if(quad == NULL) {
    printf("Empty quad\n");
    return;
  }

  Quad * temp = quad;

  while(temp != NULL) {
    printf("%s\t%s\t%s\t%s\n", qu_otoc(temp->op), (temp->arg1 != NULL ? temp->arg1->identifier : "NULL"), (temp->arg2 != NULL ? temp->arg2->identifier : "NULL"), (temp->result != NULL ? temp->result->identifier : "NULL"));
    temp = temp->next;
  }
}

void qu_free(Quad * quad) {
  while(quad != NULL) {
    Quad * temp = quad;
    quad = quad->next;

    free(temp);
  }
}
