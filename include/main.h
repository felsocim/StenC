#ifndef __MAIN_H
#define __MAIN_H

#include "../include/common.h"
#include "../include/value.h"
#include "../include/tos.h"
#include "../include/quad.h"
#include "../include/qlist.h"
#include "../include/slist.h"

extern Symbol * table;
extern Quad * list;

extern int yyparse(void);

#endif // __MAIN_H
