#ifndef __COMMON_H
#define __COMMON_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <errno.h>

extern const char * help_message;
extern const char * usage_message;

void failwith(const char *);
void usage(const char *, int);

#endif
