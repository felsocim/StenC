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
#ifndef __COMMON_H
#define __COMMON_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>
#include <math.h>

// The following messages are usually defined in the same file as the main function.

// This message should be displayed when the program is run with '-h' or '--help' option.
extern const char * help_message;

// This message should be displayed whenever the program is run with an unsupported combination of options and/or arguments.
extern const char * usage_message;

void failwith(const char *);
void usage(const char *, int);
int intlen(int);

#endif // __COMMON_H
