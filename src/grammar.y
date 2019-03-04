%{
  #include <stdarg.h>
  #include "common.h"
  #include "../include/main.h"

  int yylex();
  void yyerror(...) {
    va_list arguments;
    vfprintf(stderr, arguments);
  }
%}

%union{
  int integer;
  char * string;
  ASTNode * node;
  struct {
    ASTNode ** declarations;
    size_t count;
  } declarations;
  struct {
    int * initializers;
    size_t count;
  } initializers;
}

%define parse.error verbose

%token MAIN RETURN INT STENCIL IF ELSE WHILE FOR PRINTI PRINTF LESS LESS_OR_EQUAL GREATER GREATER_OR_EQUAL NOT AND OR EQUALEQUAL PLUS MINUS STAR SLASH DOLLAR EQUAL LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE COMMA COLON
%token <string> IDENTIFIER STRING
%token <integer> INTEGER

%type <node> list statement structControl variable declaration assignment expression
%type <boolean> bool exprBool
%type <iList> inittab listInit
%type <array> rtab
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS UINCREMENT UDECREMENT
%left '('
%left BOP_COMPARISON BOP_OR
%left BOP_AND
%nonassoc BOP_NOT
%start init

%%

initializer:
  initializer_list {
    $$.initializers = $1.initializers;
  }
  | initializer_unit {
    $$.initializers = $1.initializers;
  }
  ;

initializer_list:
  LEFT_BRACE initializer_list RIGHT_BRACE {
    $$.initializers = $1.initializers;
  }
  |
  initializer_list COMMA initializer_unit {
    $$.initializers.initializers = (int *) malloc(($1.initializers.count + $3.initializers.count) * sizeof(int));
    if(!$$.initializers.initializers) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    for(size_t i = 0; i < $1.initializers.count; i++) {
      $$.initializers.initializers[i] = $1.initializers.initializers[i];
    }
    for(size_t i = 0; i < $3.initializers.count; i++) {
      $$.initializers.initializers[i + $1.initializers.count] = $3.initializers.initializers[i];
    }
  }
  ;

initializer_unit:
  LEFT_BRACE integer_constant_list RIGHT_BRACE {
    $$.initializers = $2.initializers;
  }
  ;

integer_constant_list:
  integer_constant_list COMMA integer_constant {
    $$.initializers.count = $1.initializers.count + 1;
    $1.initializers.initializers = (int *) realloc($$.initializers.initializers, sizeof(int));
    if(!$1.initializers.initializers) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $1.initializers.initializers[$1.initializers.count] = $3.integer;
    $$.initializers.initializers = $1.initializers.initializers;
  }
  | integer_constant {
    $$.initializers.initializers = (int *) malloc(sizeof(int));
    if(!$$.initializers.initializers) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.initializers.count = 1;
    $$.initializers.initializers[0] = $1.integer;
  }
  ;

integer_constant:
  MINUS INTEGER {
    $$.integer = -$2.integer;
  } INTEGER {
    $$.integer = $1.integer;
  }
  ;

array_accessor:
	array_accessor LEFT_BRACKET expression RIGHT_BRACKET {
    $$.node->access->count++;
    $$.node->access->accessors = (ASTNode **) realloc($$.node->access->accessors, $$.node->count * sizeof(ASTNode *));
    if(!$$.node->access->accessors) {
      $$.node->access->count = 0;
      ast_node_free($$.node);
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->access->accessors[$$.node->access->count - 1] = $3.node;
  }
	| LEFT_BRACKET expression RIGHT_BRACKET {
    $$.node = ast_node_alloc(NODE_ARRAY_ACCESS);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->access->array = NULL;
    $$.node->access->count = 1;
    $$.node->access->accessors = (ASTNode **) malloc(sizeof(ASTNode *));
    if(!$$.node->access->accessors) {
      ast_node_free($$.node);
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->access->accessors[0] = $2.node;
  }
  ;

argument:;

statement:
  assignment { // Assignment statement

  }
  | INT declaration_list { // Declaration of a variable or an array

  }
  | STENCIL IDENTIFIER initializer_unit EQUAL initializer { // Declaration of a stencil

  }
  | IDENTIFIER 
  ;

declaration_list:
  declaration_list COMMA declaration {
    $$.declarations.count = $1.declarations.count + 1;
    $1.declarations.declarations = (ASTNode **) realloc($1.declarations.declarations, $$.declarations.count * sizeof(ASTNode *));
    if(!$1.declarations.declarations) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $1.declarations.declarations[$1.declarations.count] = $3.node;
    $$.declarations.declarations = $1.declarations.declarations;
  }
  | declaration {
    $$.declarations.declarations = (ASTNode **) malloc(sizeof(ASTNode *));
    if(!$$.declarations.declarations) {
      STENC_MEMORY_ERROR;
      ast_node_free($$.node);
      YYABORT;
    }

    $$.declarations.count = 1;
    $$.declarations.declarations[0] = $1.node;
  }
  ;

declaration:
  assignment_variable {
    $$.node = $1.node;
  }
  | IDENTIFIER { // New variable identifier declaration (e. g. 'myvar')
    $$.node = ast_node_alloc(NODE_SYMBOL);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // If the identifier has already been declared, raise a syntax error to prevent a redeclaration.
    if(tos_lookup(table_of_symbols, $1.string)) {
      yyerror("Redeclaration of '%s'!", $1.string);
      ast_node_free($$.node);
      YYABORT;
    }

    // Create value object for the identifier.
    Value * value = va_alloc(VALUE_INTEGER);
    if(!value) {
      STENC_MEMORY_ERROR;
      ast_node_free($$.node);
      YYABORT;
    }

    // Create and add new symbol to the table of symbols.
    Symbol * new_identifier = sy_variable($1.string, false, value);
    if(!new_identifier) {
      STENC_MEMORY_ERROR;
      ast_node_free($$.node);
      YYABORT;
    }
    
    table_of_symbols = tos_append(table_of_symbols, new_identifier);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      sy_free(new_identifier);
      ast_node_free($$.node);
      YYABORT;
    }
  }
  | IDENTIFIER array_accessor { // New array identifier declaration (e. g. 'tab[10][10]')
    $$.node = ast_node_alloc(NODE_SYMBOL);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // If the identifier has already been declared, raise a syntax error to prevent a redeclaration.
    if(tos_lookup(table_of_symbols, $1.string)) {
      yyerror("Redeclaration of '%s'!", $1.string);
      ast_node_free($$.node);
      YYABORT;
    }

    // Create value object for the identifier.
    Value * value = va_alloc(VALUE_ARRAY);
    if(!value) {
      STENC_MEMORY_ERROR;
      ast_node_free($$.node);
      YYABORT;
    }

    value->array.dimensions = $2.node->access->count;
    value->array.sizes = (size_t *) malloc(value->array.dimensions * sizeof(size_t));
    if(!value->array.sizes) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$.node);
      YYABORT;
    }

    
    // Gather array dimension sizes.
    for(size_t i = 0; i < value->array.dimensions; i++) {
      if($2.node->access->accessors[i]->type == NODE_SYMBOL &&
         $2.node->access->accessors[i]->symbol->is_constant &&
         $2.node->access->accessors[i]->symbol->value->type == VALUE_INTEGER &&
         $2.node->access->accessors[i]->symbol->value->integer > 0) {
        value->array.sizes[i] = (size_t) $2.node->access->accessors[i]->symbol->value->integer;
      } else {
        yyerror("Expected dimension size to be a non-null positive integer literal in declaration of array '%s'!", $1.string);
        va_free(value);
        ast_node_free($$.node);
        YYABORT;
      }
    }

    // Create and add new symbol to the table of symbols.
    Symbol * new_identifier = sy_variable($1.string, false, value);
    if(!new_identifier) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$.node);
      YYABORT;
    }
  }
  | IDENTIFIER array_accessor EQUAL initializer { // New array identifier declaration with immediate definition using an initializer list (e. g. 'tab[3] = {1, 2, 3}')
    $$.node = ast_node_alloc(NODE_SYMBOL);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // If the identifier has already been declared, raise a syntax error to prevent a redeclaration.
    if(tos_lookup(table_of_symbols, $1.string)) {
      yyerror("Redeclaration of '%s'!", $1.string);
      ast_node_free($$.node);
      YYABORT;
    }

    // Create value object for the identifier.
    Value * value = va_alloc(VALUE_ARRAY);
    if(!value) {
      STENC_MEMORY_ERROR;
      ast_node_free($$.node);
      YYABORT;
    }

    value->array.dimensions = $2.node->access->count;
    value->array.sizes = (size_t *) malloc(value->array.dimensions * sizeof(size_t));
    if(!value->array.sizes) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$.node);
      YYABORT;
    }

    
    // Gather array dimension sizes.
    size_t values_size = 1;
    for(size_t i = 0; i < value->array.dimensions; i++) {
      if($2.node->access->accessors[i]->type == NODE_SYMBOL &&
         $2.node->access->accessors[i]->symbol->is_constant &&
         $2.node->access->accessors[i]->symbol->value->type == VALUE_INTEGER &&
         $2.node->access->accessors[i]->symbol->value->integer > 0) {
        value->array.sizes[i] = (size_t) $2.node->access->accessors[i]->symbol->value->integer;
        values_size *= value->array.sizes[i];
      } else {
        yyerror("Expected dimension size to be a non-null positive integer literal in declaration of array '%s'!", $1.string);
        va_free(value);
        ast_node_free($$.node);
        YYABORT;
      }
    }

    if(values_size != $4.initializers.count) {
      yyerror("Excess elements in initializer of array '%s'!", $1.string);
      va_free(value);
      ast_node_free($$.node);
      YYABORT;
    }

    value->array.values = (int *) malloc(values_size * sizeof(int));
    if(!value->array.values) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$.node);
      YYABORT;
    }

    for(size_t i = 0; i < values_size; i++) {
      value->array.values[i] = $4.initializers.initializers[i];
    }

    // Create and add new symbol to the table of symbols.
    Symbol * new_identifier = sy_variable($1.string, false, value);
    if(!new_identifier) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$.node);
      YYABORT;
    }
  }
  ;

assignment:
  assignment_variable | assignment_array {
    $$.node = $1.node;
  }
  ;

assignment_variable:
  IDENTIFIER EQUAL expression { // Assignment to a variable (e. g. 'foo = 12;')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // Create new AST node for the lvalue.
    ASTNode * lvalue = ast_node_alloc(NODE_SYMBOL);
    if(!lvalue) {
      STENC_MEMORY_ERROR;
      ast_node_free($$.node);
      YYABORT;
    }

    // Check whether the destination variable has been declared.
    Symbol * existing = NULL;
    if(!(existing = tos_lookup(table_of_symbols, $1.string))) {
      yyerror("Undeclared identifier '%s'!", $1.string);
      YYABORT;
    }

    lvalue->symbol = existing;

    $$.node->binary->operation = BO_ASSIGNMENT;
    $$.node->binary->LHS = lvalue;
    $$.node->binary->RHS = $3.node;
  }
  ;

assignment_array:  
  IDENTIFIER array_accessor EQUAL expression {
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // Check whether the destination array has been declared.
    Symbol * existing = NULL;
    if(!(existing = tos_lookup(table_of_symbols, $1.string))) {
      yyerror("Undeclared identifier '%s'!", $1.string);
      YYABORT;
    }

    $2.node->access->array = existing;

    $$.node->binary->operation = BO_ASSIGNMENT;
    $$.node->binary->LHS = $2.node;
    $$.node->binary->RHS = $3.node;
  }
  ;

expression:
  expression AND expression { // Logical 'and' (e. g. '(12 + test) && foo')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_AND;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | expression OR expression { // Logical 'or' (e. g. '(12 + test) || foo')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_OR;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | expression LESS expression { // Comparison operator '<' (e. g. '(12 + test) < foo')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_LESS;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | expression LESS_OR_EQUAL expression { // Comparison operator '<=' (e. g. '(12 + test) <= foo')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_LESS_OR_EQUAL;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | expression GREATER_OR_EQUAL expression { // Comparison operator '>=' (e. g. '(12 + test) < foo')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_GREATER_OR_EQUAL;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | expression GREATER expression { // Comparison operator '>' (e. g. '(12 + test) < foo')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_GREATER;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | expression EQUALEQUAL expression { // Comparison operator '==' (e. g. '(12 + test) < foo')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_EQUAL;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | NOT expression %prec UNOT { // Logical negation (e. g. '!bar')
    $$.node = ast_node_alloc(NODE_UNARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->unary->operation = UO_NOT;
    $$.node->unary->expression = $3.node;
  }
  expression PLUS expression { // Sum (e. g. '3 + foo')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_SUM;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | expression MINUS expression { // Difference (e. g. 'bar - 12')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_DIFFERENCE;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | expression STAR expression { // Multiplication (e. g. 'foo * bar')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_MULTIPLICATION;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | expression SLASH expression { // Division (e. g. '12 / (3 + foo * bar)')
    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_DIVISION;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | expression DOLLAR stencil { // Stencil binary operation (e. g. 'tab[3][3] $ sten1')
    if($1.node->type != NODE_ARRAY_ACCESS) {
      yyerror("Expected left-hand side of the expression to be an array access!");
      YYABORT;
    }

    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_STENCIL;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | stencil DOLLAR expression { // Stencil binary operation (e. g. 'sten1 $ tab[3][3]')
    if($3.node->type != NODE_ARRAY_ACCESS) {
      yyerror("Expected right-hand side of the expression to be an array access!");
      YYABORT;
    }

    $$.node = ast_node_alloc(NODE_BINARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->binary->operation = BO_STENCIL;
    $$.node->binary->LHS = $1.node;
    $$.node->binary->RHS = $3.node;
  }
  | LEFT_PARENTHESIS expression RIGHT_PARENTHESIS { // Parenthesis expression (e. g. '(10 / foo)')
    $$.node = $2.node;
  }
  | MINUS expression %prec UMINUS { // Sign change (e. g. '-(8 + bar)')
    $$.node = ast_node_alloc(NODE_UNARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->unary->operation = UO_MINUS;
    $$.node->unary->expression = $2.node;
  }
  | PLUSPLUS expression %prec UINCREMENT { // Unary increment with priority (e. g. '++i')
    $$.node = ast_node_alloc(NODE_UNARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->unary->operation = UO_PLUSPLUS;
    $$.node->unary->expression = $2.node;
  }
  | expression PLUS PLUS { // Unary increment (e. g. 'i++')
    $$.node = ast_node_alloc(NODE_UNARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->unary->operation = UO_PLUSPLUS;
    $$.node->unary->expression = $1.node;
  }
  | MINUSMINUS expression %prec UINCREMENT { // Unary decrement with priority (e. g. '--i')
    $$.node = ast_node_alloc(NODE_UNARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->unary->operation = UO_MINUSMINUS;
    $$.node->unary->expression = $2.node;
  }
  | expression MINUS MINUS { // Unary decrement (e. g. 'i--')
    $$.node = ast_node_alloc(NODE_UNARY);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.node->unary->operation = UO_MINUSMINUS;
    $$.node->unary->expression = $1.node;
  }
  | IDENTIFIER array_accessor { // Array item reference (e. g. 'tab[0][i + 1]')
    // Check if the array identified by the parsed identifier has been defined.
    Symbol * existing = NULL;
    if((existing = tos_lookup(table_of_symbols, $1.string))) {
      // Create new symbol AST node.
      $$.node = $2.node;
      $$.node->access->array = existing;
    } else {
      // Otherwise, abort parsing and raise a syntax error.
      yyerror("Undefined variable '%s'!", $1.string);
      ast_node_free($$.node);
      YYABORT;
    }
  }
  | IDENTIFIER { // Variable reference (e. g. 'foo')
    // Check if the variable identified by the parsed identifier has been defined.
    Symbol * existing = NULL;
    if((existing = tos_lookup(table_of_symbols, $1.string))) {
      // Create new symbol AST node.
      $$.node = ast_node_alloc(NODE_SYMBOL);
      if(!$$.node) {
        STENC_MEMORY_ERROR;
        YYABORT;
      }

      $$.node->symbol = existing;
    } else {
      // Otherwise, abort parsing and raise a syntax error.
      yyerror("Undefined variable '%s'!", $1.string);
      YYABORT;
    }
  }
  | INTEGER { // Integer literal (e. g. '12')
    // Create new symbol AST node.
    $$.node = ast_node_alloc(NODE_SYMBOL);
    if(!$$.node) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // Create value corresponding to the parsed integer value.
    Value * integer = va_alloc();
    if(!integer) {
      STENC_MEMORY_ERROR;
      ast_node_free($$.node);
      YYABORT;
    }

    integer->type = VALUE_INTEGER;
    integer->integer = $1.integer;

    // Create and then add a new temporary, having the parsed value, to the table of symbols and link it to the AST node we've created above.
    $$.node->symbol = sy_temporary(true, integer);
    if(!$$.node->symbol) {
      STENC_MEMORY_ERROR;
      ast_node_free($$.node);
      YYABORT;
    }

    table_of_symbols = tos_append(table_of_symbols, $$.node->symbol);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      sy_free($$.node->symbol);
      ast_node_free($$.node);
      YYABORT;
    }
  }
  ;

init:
	INT MAIN '(' ')' '{' list END ';' '}' {
    list = $6.code;
    printf("reconnaissance du main...\n");
  }
	;

list:
	statement ';' list {
    $$.code = qu_concatenate($1.code, $3.code);
  }
  | statement ';' {
    $$.code = $1.code;
  }
  | structControl list {
    $$.code = qu_concatenate($1.code, $2.code);
  }
  | structControl {
    $$.code = $1.code;
  }
  ;

structControl:
  IF '(' exprBool ')' '{' list '}' {
    Quad * ontrue = qu_generate(), * onfalse = qu_generate();

    table = sy_add_label(table, NULL);

    ontrue->op = OP_LABEL;
    ontrue->result = table;

    table = sy_add_label(table, NULL);

    onfalse->op = OP_LABEL;
    onfalse->result = table;

    $3.truelist = ql_complete($3.truelist, ontrue->result);
    $3.falselist = ql_complete($3.falselist, onfalse->result);

    $$.code = $3.code;
    $$.code = qu_concatenate($$.code, ontrue);
    $$.code = qu_concatenate($$.code, $6.code);
    $$.code = qu_concatenate($$.code, onfalse);

    ql_free($3.truelist);
    ql_free($3.falselist);
  }
  | IF '(' exprBool ')' '{' list '}' ELSE '{' list '}' {
    Quad * ontrue = qu_generate(), * onfalse = qu_generate(), * after = qu_generate(), * goafter = qu_generate();

    table = sy_add_label(table, NULL);

    ontrue->op = OP_LABEL;
    ontrue->result = table;

    table = sy_add_label(table, NULL);

    onfalse->op = OP_LABEL;
    onfalse->result = table;

    table = sy_add_label(table, NULL);

    after->op = OP_LABEL;
    after->result = table;

    goafter->op = OP_GOTO;
    goafter->result = after->result;

    $3.truelist = ql_complete($3.truelist, ontrue->result);
    $3.falselist = ql_complete($3.falselist, onfalse->result);

    $$.code = $3.code;
    $$.code = qu_concatenate($$.code, ontrue);
    $$.code = qu_concatenate($$.code, $6.code);
    $$.code = qu_concatenate($$.code, goafter);
    $$.code = qu_concatenate($$.code, onfalse);
    $$.code = qu_concatenate($$.code, $10.code);
    $$.code = qu_concatenate($$.code, after);

    ql_free($3.truelist);
    ql_free($3.falselist);
  }
  | WHILE '(' exprBool ')' '{' list '}'	{
    Quad * condition = qu_generate(), * ontrue = qu_generate(), * verify = qu_generate(), * onfalse = qu_generate();

    table = sy_add_label(table, NULL);
    condition->op = OP_LABEL;
    condition->result = table;

    verify->op = OP_GOTO;
    verify->result = condition->result;

    table = sy_add_label(table, NULL);

    ontrue->op = OP_LABEL;
    ontrue->result = table;

    table = sy_add_label(table, NULL);

    onfalse->op = OP_LABEL;
    onfalse->result = table;

    $3.truelist = ql_complete($3.truelist, ontrue->result);
    $3.falselist = ql_complete($3.falselist, onfalse->result);

    $$.code = qu_concatenate(condition, $3.code);
    $$.code = qu_concatenate($$.code, ontrue);
    $$.code = qu_concatenate($$.code, $6.code);
    $$.code = qu_concatenate($$.code, verify);
    $$.code = qu_concatenate($$.code, onfalse);

    ql_free($3.truelist);
    ql_free($3.falselist);
  }
  | FOR '(' assignment ';' exprBool ';' assignment ')' '{' list '}' {

    Quad * condition = qu_generate(), * ontrue = qu_generate(), * verify = qu_generate(), * onfalse = qu_generate();

    table = sy_add_label(table, NULL);
    condition->op = OP_LABEL;
    condition->result = table;

    verify->op = OP_GOTO;
    verify->result = condition->result;

    table = sy_add_label(table, NULL);

    ontrue->op = OP_LABEL;
    ontrue->result = table;

    table = sy_add_label(table, NULL);

    onfalse->op = OP_LABEL;
    onfalse->result = table;

    $5.truelist = ql_complete($5.truelist, ontrue->result);
    $5.falselist = ql_complete($5.falselist, onfalse->result);
    $$.code = qu_concatenate($$.code, $3.code);
    $$.code = qu_concatenate($$.code, condition);    
    $$.code = qu_concatenate($$.code, $5.code);    
    $$.code = qu_concatenate($$.code, ontrue);
    $$.code = qu_concatenate($$.code, $10.code);
    $$.code = qu_concatenate($$.code, $7.code);
    $$.code = qu_concatenate($$.code, verify);
    $$.code = qu_concatenate($$.code, onfalse);

    ql_free($5.truelist);
    ql_free($5.falselist);
}
;

statement:
  INT variable {
      $$.code = $2.code;
    }
  | assignment {
      $$.code = $1.code;
    }
  | PRINTI '(' expression ')' {
    Quad * n = qu_generate();

    n->op = OP_CALL_PRINTI;
    n->arg1 = $3.pointer;
    $$.code = qu_concatenate($3.code, n);
  }
  | PRINTI '(' exprBool ')' {
    Quad * n = qu_generate();

    n->op = OP_CALL_PRINTI;
    n->arg1 = $3.pointer;
    $$.code = qu_concatenate($3.code, n);
  }
  | PRINTF '(' STRING ')' {
    Value * string = va_alloc();
    Quad * n = qu_generate();

    string->string = yylval.name;

    table = sy_add_string(table, string);

    n->op = OP_CALL_PRINTF;
    n->arg1 = table;
    $$.code = n;
  }
  | STENCIL ID '{' inittab '}' '=' listInit {
    if($4->size != 2) {
      fprintf(stderr, "Syntax error: Too %s parameters for type stencil of '%s'!\n", $4->size < 2 ? "few" : "much", $2);
      exit(EXIT_FAILURE);
    }

    size_t dimensions = (size_t) intListGet($4, 1),
      neighbors = (size_t) intListGet($4, 0),
      i = 0;
    int * current = NULL;
    size_t * iterator = (size_t *) calloc(dimensions, sizeof(size_t));

    if(iterator == NULL)
      failwith("Failed to reserve memory for stencil array iterator");

    Value * stencil = va_alloc();

    stencil->array.sizes = (size_t *) malloc(dimensions * sizeof(size_t));

    if(stencil->array.sizes == NULL)
      failwith("Failed to reserve memory for stencil array sizes");

    for(i = 0; i < dimensions; i++) {
      stencil->array.sizes[i] = 2 * neighbors + 1;
    }

    stencil->array.dimensions = dimensions;

    stencil->array.values = (int *) malloc(((size_t) pow((double) (2 * neighbors + 1), (double) dimensions)) * sizeof(int));

    if(stencil->array.values == NULL)
      failwith("Failed to reserve memory for stencil array values");

    i = 0;

    do {
      current = va_array_get(stencil, iterator);
      *current = intListGet($7, i);
      i++;
    } while(va_array_forward(iterator, stencil->array.sizes, stencil->array.dimensions)); // Add test on i

    if(sy_lookup(table, $2) == NULL) {
      table = sy_add_variable(table, $2, true, TYPE_ARRAY, stencil);
      $$.pointer = table;
    } else {
      fprintf(stderr, "Syntax error: Identifier %s has already been declared in this scope!\n", $2);
      exit(EXIT_FAILURE);
    }

    $$.code = NULL;
  }
  ;




%%
