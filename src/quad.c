#include "../include/quad.h"

char * otos(Operation operation) {
  switch(operation) {
    case OP_ADD:
      return "+";
    case OP_SUBTRACT:
      return "-";
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
    case OP_NE:
      return "!=";
    case OP_GE:
      return ">=";
    case OP_GT:
      return ">";
    case OP_UMINUS:
      return "UM";
    case OP_ASSIGN:
      return "=";
    case OP_LABEL:
      return "label";
    case OP_GOTO:
      return "goto";
    case OP_CALL_PRINTI:
      return "printi";
    case OP_CALL_PRINTF:
      return "printf";
    default:
      failwith("Unknown operation type detected");
  }

  return NULL;
}

Operation stobo(const char * operator) {
  if(operator == NULL)
    failwith("Failed to read input operator! It cannot be NULL");

  if(strcmp(operator, "<") == 0)
    return OP_LT;

  if(strcmp(operator, "<=") == 0)
    return OP_LE;

  if(strcmp(operator, "==") == 0)
    return OP_EQ;

  if(strcmp(operator, "!=") == 0)
    return OP_NE;

  if(strcmp(operator, ">=") == 0)
    return OP_GE;

  if(strcmp(operator, ">") == 0)
    return OP_GT;

  failwith("Failed to determine boolean operator! Invalid input");

  return 0;
}

Quad * qu_generate(void) {
  Quad * quad = (Quad *) malloc(sizeof(struct s_quad));

  if(quad == NULL)
    failwith("Failed to reserve memory for new quad");

  quad->op = OP_ADD;
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
    printf("%s\t%s\t%s\t%s\n", otos(temp->op), (temp->arg1 != NULL ? temp->arg1->identifier : "NULL"), (temp->arg2 != NULL ? temp->arg2->identifier : "NULL"), (temp->result != NULL ? temp->result->identifier : "NULL"));
    temp = temp->next;
  }
}

void qu_assemble(Quad * list, Symbol * table, FILE * output) {
  if(list == NULL)
    failwith("Failed to assemble given list of quads! The list cannot be empty");

  Quad * temp = list;
  Symbol * temp2 = table;

  if(fprintf(output, "  .text\nmain:\n") < 0)
    failwith("Failed to write heading to the assembly output file");

  while(temp != NULL) {
    if(temp->op <= OP_GT) {
      if(fprintf(output, "lw $t0,%s\n", temp->arg1->identifier) < 0)
        failwith("Failed to write 'lw' assembly instruction to the output file");

      if(fprintf(output, "lw $t1,%s\n", temp->arg2->identifier) < 0)
        failwith("Failed to write 'lw' assembly instruction to the output file");
    }

    switch(temp->op) {
      case OP_ADD:
        if(fprintf(output, "add $t0,$t0,$t1\n") < 0)
          failwith("Failed to write 'add' assembly instruction to the output file");
        break;
      case OP_SUBTRACT:
        if(fprintf(output, "sub $t0,$t0,$t1\n") < 0)
          failwith("Failed to write 'sub' assembly instruction to the output file");
        break;
      case OP_MULTIPLY:
        if(fprintf(output, "mul $t0,$t0,$t1\n") < 0)
          failwith("Failed to write 'mul' assembly instruction to the output file");
        break;
      case OP_DIVIDE:
        if(fprintf(output, "div $t0,$t0,$t1\n") < 0)
          failwith("Failed to write 'div' assembly instruction to the output file");
        break;
      case OP_LT:
        if(fprintf(output, "blt $t0,$t1,%s\n", temp->result->identifier) < 0)
          failwith("Failed to write 'blt' assembly instruction to the output file");
        break;
      case OP_LE:
        if(fprintf(output, "ble $t0,$t1,%s\n", temp->result->identifier) < 0)
          failwith("Failed to write 'ble' assembly instruction to the output file");
        break;
      case OP_EQ:
        if(fprintf(output, "beq $t0,$t1,%s\n", temp->result->identifier) < 0)
          failwith("Failed to write 'beq' assembly instruction to the output file");
        break;
      case OP_NE:
        if(fprintf(output, "bne $t0,$t1,%s\n", temp->result->identifier) < 0)
          failwith("Failed to write 'bne' assembly instruction to the output file");
        break;
      case OP_GE:
        if(fprintf(output, "bge $t0,$t1,%s\n", temp->result->identifier) < 0)
          failwith("Failed to write 'bge' assembly instruction to the output file");
        break;
      case OP_GT:
        if(fprintf(output, "bgt $t0,$t1,%s\n", temp->result->identifier) < 0)
          failwith("Failed to write 'bgt' assembly instruction to the output file");
        break;
      case OP_UMINUS:
        if(fprintf(output, "li $t0,0\n") < 0)
          failwith("Failed to write 'li' assembly instruction to the output file");

        if(fprintf(output, "lw $t1,%s\n", temp->arg1->identifier) < 0)
          failwith("Failed to write 'lw' assembly instruction to the output file");

        if(fprintf(output, "sub $t0,$t0,$t1\n") < 0)
          failwith("Failed to write 'sub' assembly instruction to the output file");
        break;
      case OP_ASSIGN:
        if(fprintf(output, "lw $t0,%s\n", temp->arg1->identifier) < 0)
          failwith("Failed to write 'lw' assembly instruction to the output file");
        break;
      case OP_LABEL:
        if(fprintf(output, "%s:\n", temp->result->identifier) < 0)
          failwith("Failed to write label to the output file");
        break;
      case OP_GOTO:
        if(fprintf(output, "j %s\n", temp->result->identifier) < 0)
          failwith("Failed to write 'j' assembly instruction to the output file");
        break;
      case OP_CALL_PRINTI:
        if(fprintf(output, "li $v0,4\n") < 0)
          failwith("Failed to write 'li' assembly instruction to the output file");

        if(fprintf(output, "la $a0,result_string\n") < 0)
          failwith("Failed to write 'la' assembly instruction to the output file");

        if(fprintf(output, "syscall\n") < 0)
          failwith("Failed to write 'syscall' assembly instruction to the output file");

        if(fprintf(output, "li $v0,1\n") < 0)
          failwith("Failed to write 'li' assembly instruction to the output file");

        if(fprintf(output, "lw $a0,%s\n", temp->arg1->identifier) < 0)
          failwith("Failed to write 'lw' assembly instruction to the output file");

        if(fprintf(output, "syscall\n") < 0)
          failwith("Failed to write 'syscall' assembly instruction to the output file");

        if(fprintf(output, "li $v0,11\n") < 0)
          failwith("Failed to write 'li' assembly instruction to the output file");

        if(fprintf(output, "li $a0,0xA\n") < 0)
          failwith("Failed to write 'li' assembly instruction to the output file");

        if(fprintf(output, "syscall\n") < 0)
          failwith("Failed to write 'syscall' assembly instruction to the output file");
        break;
      case OP_CALL_PRINTF:
        if(fprintf(output, "li $v0,4\n") < 0)
          failwith("Failed to write 'li' assembly instruction to the output file");

        if(fprintf(output, "la $a0,%s\n", temp->arg1->identifier) < 0)
          failwith("Failed to write 'la' assembly instruction to the output file");

        if(fprintf(output, "syscall\n") < 0)
          failwith("Failed to write 'syscall' assembly instruction to the output file");

        if(fprintf(output, "li $v0,11\n") < 0)
          failwith("Failed to write 'li' assembly instruction to the output file");

        if(fprintf(output, "li $a0,0xA\n") < 0)
          failwith("Failed to write 'li' assembly instruction to the output file");

        if(fprintf(output, "syscall\n") < 0)
          failwith("Failed to write 'syscall' assembly instruction to the output file");
        break;
      default:
        failwith("Unknown or undefined operation type detected while assembling given list of quads");
    }

    if(temp->op <= OP_DIVIDE || temp->op == OP_UMINUS || temp->op == OP_ASSIGN) {
      if(fprintf(output, "sw $t0,%s\n", temp->result->identifier) < 0)
        failwith("Failed to write 'sw' assembly instruction to the output file");
    }

    temp = temp->next;
  }

  if(fprintf(output, "li $v0,10\nsyscall\n") < 0)
    failwith("Failed to write exit sequence to the assembly output file");

  if(fprintf(output, "  .data\nresult_string: .asciiz \"Value: \"\n") < 0)
    failwith("Failed to write variable initialization sequence beginning to the assembly output file");

  while(temp2 != NULL) {
    switch(temp2->type) {
      case TYPE_INTEGER:
        if(fprintf(output, "%s: .word %d\n", temp2->identifier, (temp2->constant ? temp2->value->integer : 0)) < 0)
          failwith("Failed to write a variable initialization to the assembly output file");
        break;
      case TYPE_STRING:
        if(fprintf(output, "%s: .asciiz %s\n", temp2->identifier, (temp2->constant ? temp2->value->string : "N/A")) < 0)
          failwith("Failed to write a variable initialization to the assembly output file");
        break;
      default:
        break;
    }

    temp2 = temp2->next;
  }
}

void qu_free(Quad * quad) {
  while(quad != NULL) {
    Quad * temp = quad;
    quad = quad->next;

    free(temp);
  }
}
