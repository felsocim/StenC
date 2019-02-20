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
#ifndef __MAIN_H
#define __MAIN_H

#include "../include/common.h"
#include "../include/value.h"
#include "../include/tos.h"
#include "../include/quad.h"
#include "../include/qlist.h"
#include "../include/tab.h"
#include "../include/slist.h"

// Symbol table and list of quads will be defined in the main source file.
extern Symbol * table;
extern Quad * list;

extern int yyparse(void);

#endif // __MAIN_H
