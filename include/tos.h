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
#ifndef __TOS_H
#define __TOS_H

// Prefix for temporary variables created during compilation
#define SYMBOL_TEMPORARY "temp"


#define ITOB(INT) (INT != 0 ? 1 : 0)

#include "common.h"
#include "value.h"

// Definition of symbol type
typedef struct s_table_of_symbols {
  char * identifier;
  bool constant;
  Type type;
  Value * value;
  struct s_table_of_symbols * next;
} Symbol;

Symbol * sy_alloc(void);
Symbol * sy_add_variable(Symbol *, const char *, bool, Type, Value *);
Symbol * sy_add_temporary(Symbol *, bool, Type, Value *);
Symbol * sy_add_label(Symbol *, const char *);
Symbol * sy_add_string(Symbol *, Value *);
Symbol * sy_lookup(Symbol *, const char *);
void sy_print(Symbol *);
void sy_free(Symbol *);

#endif
