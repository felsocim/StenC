#ifndef __QLIST_H
#define __QLIST_H
#define QL_GROW_SIZE 10

#include "common.h"
#include "value.h"
#include "tos.h"
#include "quad.h"

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
