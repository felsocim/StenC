/*
 * StenC - Basic C language compiler with support for stencils
 *
 * Copyright (C) 2017  Marek Felsoci, Arnaud Pinsun
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
#ifndef __QUAD_H
#define __QUAD_H

#include "common.h"
#include "value.h"
#include "tos.h"

// Supported operations
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
  OP_UMINUS,
  OP_ASSIGN,
  OP_ASSIGN_ARRAY_VALUE,
  OP_LABEL,
  OP_GOTO,
  OP_CALL_PRINTI,
  OP_CALL_PRINTF
} Operation;

// Definition of a quad type (3 addresses code style)
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
