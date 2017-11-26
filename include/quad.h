#ifndef __QUAD_H
#define __QUAD_H

#include "common.h"
#include "tos.h"

typedef enum {
  OP_UNDEFINED,
  OP_ADD,
  OP_SUBTRACT,
  OP_MULTIPLY,
  OP_DIVIDE,
  OP_LT,
  OP_LE,
  OP_EQ,
  OP_GE,
  OP_GT,
  OP_GOTO
} Operation;

typedef struct s_quad {
  Operation op;
  Symbol * arg1,
    * arg2,
    * result;
  struct s_quad * next;
} Quad;

char * qu_otoc(Operation);

Quad * qu_generate(void);
Quad * qu_concatenate(Quad *, Quad *);
void qu_print(Quad *);
void qu_free(Quad *);

#endif // __QUAD_H
