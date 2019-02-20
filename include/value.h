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
#ifndef __VALUE_H
#define __VALUE_H

#include "common.h"

// Supported symbol types
typedef enum {
  TYPE_INTEGER,
  TYPE_ARRAY,
  TYPE_LABEL,
  TYPE_STRING
} Type;

// Supported symbol values definitions
typedef union {
  int integer;
  char * string;
  struct {
    int * values;
    size_t * sizes;
    size_t dimensions;
  } array;
} Value;

char * ttos(Type);

Value * va_alloc();
void va_print(Value *, Type);
void va_free(Value *, Type);

int * va_array_get(Value *, size_t *);
bool va_array_forward(size_t *, const size_t *, size_t);

#endif // __VALUE_H
