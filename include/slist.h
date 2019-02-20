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
#ifndef __SLIST_H
#define __SLIST_H

// Everytime the 'sl_grow' function is called on a symbol list, the size of the latter will be increased by SL_GROW_SIZE items.
#define SL_GROW_SIZE 10

#include "common.h"
#include "value.h"
#include "tos.h"

// Definition of symbol list type
typedef struct s_symbol_list {
  Symbol ** values;
  size_t size,
    next;
} SList;

size_t * sltost(SList *);
SList * sl_init(size_t);
SList * sl_grow(SList *);
SList * sl_insert(SList *, Symbol *);
SList * sl_concatenate(SList *, SList *);
void sl_free(SList *);

#endif // __SLIST_H
