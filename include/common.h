#ifndef COMMON_H
#define COMMON_H

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
size_t intlen(int);

#endif // COMMON_H
