#ifndef __QUAD_H
#define __QUAD_H

#include "common.h"
#include "value.h"
#include "tos.h"

typedef enum {
  OP_ADD,
  OP_SUBTRACT,
  OP_MULTIPLY,
  OP_DIVIDE,
  OP_LT,
  OP_LE,
  OP_EQ,
  OP_NE,
  OP_GE,
  OP_GT,
  OP_OR,
  OP_AND,
  OP_NOT,
  OP_UMINUS,
  OP_GOTO,
  OP_ASSIGN,
  OP_CALL_PRINT
} Operation;

typedef struct s_quad {
  Operation op;
  Symbol * arg1,
    * arg2,
    * result;
  struct s_quad * next;
} Quad;

char * otos(Operation);
Operation stobo(const char *);

Quad * qu_generate(void);
Quad * qu_concatenate(Quad *, Quad *);
void qu_print(Quad *);
void qu_assemble(Quad *, Symbol *, FILE *);
void qu_free(Quad *);

#endif // __QUAD_H
