#ifndef AST_H
#define AST_H

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>

#include "symbol.h"

// Enumeration of supported operators ('UO' stands for 'Unary Operator' and 'BO' for 'Binary Operator')
typedef enum {
  UO_MINUS,
  UO_NOT,
  UO_PLUSPLUS,
  UO_MINUSMINUS,
  BO_ASSIGNMENT,
  BO_SUM,
  BO_DIFFERENCE,
  BO_MULTIPLICATION,
  BO_DIVISION,
  BO_STENCIL,
  BO_AND,
  BO_OR,
  BO_LESS,
  BO_LESS_OR_EQUAL,
  BO_GRATER_OR_EQUAL,
  BO_GREATER,
  BO_EQUAL
} Operator;

// Enumeration of possible AST node types
typedef enum {
  NODE_IDENTIFIER,
  NODE_ARRAY_ACCESS,
  NODE_UNARY,
  NODE_BINARY,
  NODE_IF,
  NODE_WHILE,
  NODE_FOR,
  NODE_FUNCTION_DECLARATION,
  NODE_FUNCTION_CALL,
  NODE_SCOPE
} ASTType;

typedef struct s_node ASTNode;

// Represents an array access (e. g. array[N][0]).
typedef struct {
  Symbol * array;
  ASTNode ** accessors;
} ASTArrayAccess;

// Represents a unary operation, either arithmetic or logic (e. g. '-1', '!var', etc.)
typedef struct {
  Operator operation;
  ASTNode * expression;
} ASTUnary;

// Represents a binary operation, either arithmetic or logic (e. g. 'a + 12', 'a && b', etc.)
typedef struct {
  Operator operation;
  ASTNode * LHS, * RHS;
} ASTBinary;

// Represents an if or an if-else conditional structure
typedef struct {
  ASTNode * condition, * onif, * onelse;
} ASTIf;

// Represents a while loop structure
typedef struct {
  ASTNode * condition, * statements;
} ASTWhile;

// Represents a for loop structure
typedef struct {
  ASTNode * initialization, * condition, * incrementation, * statements;
} ASTFor;

// Represents a function declaration
typedef struct {
  Symbol * function;
  ASTNode * body;
} ASTFunctionDeclaration;

// Represents a function call, of either user-defined or a built-in function ('printi' or 'printf')
typedef struct {
  Symbol * function;
  ASTNode * argv;
  size_t argc;
} ASTFunctionCall;

// Represents a scope (e. g. scope of a function or even of an entire source file)
typedef struct {
  Symbol * name;
  ASTNode ** statements;
  size_t count;
} ASTScope;

// Type definition of a general AST node
typedef struct s_node {
  union {
    Symbol * identifier;
    ASTArrayAccess * access;
    ASTUnary * unary;
    ASTBinary * binary;
    ASTIf * if_conditional;
    ASTWhile * while_loop;
    ASTFor * for_loop;
    ASTFunctionDeclaration * function_declaration;
    ASTFunctionCall * function_call;
    ASTScope * scope;
  };
  ASTType type;
};

const char * operator_to_string(Operator);
ASTNode * ast_new_node(ASTType);
void ast_delete_node(ASTNode *);
void ast_dump(const ASTNode *);

#endif // AST_H
