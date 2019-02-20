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
#ifndef __QLIST_H
#define __QLIST_H

// Everytime the 'ql_grow' function is called on a quad list, the size of the latter will be increased by QL_GROW_SIZE items.
#define QL_GROW_SIZE 10

#include "common.h"
#include "value.h"
#include "tos.h"
#include "quad.h"

// Definition of quad list type
typedef struct s_quad_list {
  Quad ** values;
  size_t size,
         next;
} QList;

QList * ql_init(size_t);
QList * ql_grow(QList *);
QList * ql_insert(QList *, Quad *);
QList * ql_complete(QList *, Symbol *);
QList * ql_concatenate(QList *, QList *);
void ql_free(QList *);

#endif // __QLIST_H
