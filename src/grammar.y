%{
  #include <stdarg.h>
  #include "../include/main.h"

  int yylex();
  void yyerror(const char * __format, ...) {
    va_list arguments;
    vfprintf(stderr, __format, arguments);
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

%token MAIN RETURN INT STENCIL IF ELSE WHILE FOR PRINTI PRINTF LESS LESS_OR_EQUAL GREATER GREATER_OR_EQUAL NOT AND OR EQUALEQUAL PLUS MINUS STAR SLASH DOLLAR EQUAL LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE COMMA COLON MINUSMINUS PLUSPLUS VOID
%token <string> IDENTIFIER STRING
%token <integer> INTEGER

%type <integer> integer_constant
%type <node> array_accessor function_call function_declaration parameter_list scope statement_list control_structure statement declaration declaration_only assignment assignment_array assignment_variable expression declaration_list unary_increment_or_decrement
%type <declarations> argument_list
%type <initializers> initializer integer_constant_list

%left PLUS MINUS
%left STAR SLASH DOLLAR
%nonassoc UMINUS UINCREMENT UDECREMENT
%left LEFT_PARENTHESIS
%left LESS LESS_OR_EQUAL GREATER GREATER_OR_EQUAL OR
%left AND
%nonassoc UNOT
%start module

%%

module:
  statement_list {
    AST = $1;
    YYACCEPT;
  }
  ;

initializer:
  integer_constant {
    $$.initializers = (int *) malloc(sizeof(int));
    if(!$$.initializers) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.count = 1;
    $$.initializers[0] = $1;
  }
  | LEFT_BRACE integer_constant_list RIGHT_BRACE {
    $$ = $2;
  }
  | LEFT_BRACE integer_constant_list COMMA RIGHT_BRACE{
    $$ = $2;
  }
  ;

integer_constant_list:
  integer_constant_list COMMA initializer {
    $$.count = $1.count + $3.count;
    $1.initializers = (int *) realloc($$.initializers, $$.count * sizeof(int));
    if(!$1.initializers) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    for(size_t i = $1.count; i < $$.count; i++) {
      $1.initializers[i] = $3.initializers[i - $1.count];
    }
    $$.initializers = $1.initializers;
  }
  | initializer {
    $$ = $1;
  }
  ;

integer_constant:
  MINUS INTEGER {
    $$ = -$2;
  }
  | INTEGER {
    $$ = $1;
  }
  ;

array_accessor:
	array_accessor LEFT_BRACKET expression RIGHT_BRACKET {
    $$->access->count++;
    $$->access->accessors = (ASTNode **) realloc($$->access->accessors, $$->access->count * sizeof(ASTNode *));
    if(!$$->access->accessors) {
      $$->access->count = 0;
      ast_node_free($$);
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->access->accessors[$$->access->count - 1] = $3;
  }
	| LEFT_BRACKET expression RIGHT_BRACKET {
    $$ = ast_node_alloc(NODE_ARRAY_ACCESS);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->access->array = NULL;
    $$->access->count = 1;
    $$->access->accessors = (ASTNode **) malloc(sizeof(ASTNode *));
    if(!$$->access->accessors) {
      ast_node_free($$);
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->access->accessors[0] = $2;
  }
  ;

function_call:
  IDENTIFIER LEFT_PARENTHESIS argument_list RIGHT_PARENTHESIS {
    // Check whether the called function has been declared.
    Symbol * existing = NULL;
    if(!(existing = tos_lookup(table_of_symbols, $1))) {
      yyerror("Function '%s' was not declared!", $1);
      YYABORT;
    }

    ASTFunctionDeclaration * existing_function = ast_find_function_declaration(AST, existing);
    if(!existing_function) {
      yyerror("Function '%s' was not declared in this scope!", $1);
      YYABORT;
    }

    if(existing_function->argc != $3.count) {
      yyerror("Unexpected argument count in call of function '%s'!", $1);
      YYABORT;
    }

    $$ = ast_node_alloc(NODE_FUNCTION_CALL);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->function_call->function = existing_function;
    $$->function_call->argv = $3.declarations;
  }
  ;

argument_list:
  argument_list COMMA expression {
    $$.count = $1.count + 1;
    $1.declarations = (ASTNode **) realloc($1.declarations, $$.count * sizeof(ASTNode *));
    if(!$1.declarations) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $1.declarations[$1.count] = $3;
    $$.declarations = $1.declarations;
  }
  | expression {
    $$.declarations = (ASTNode **) malloc(sizeof(ASTNode *));
    if(!$$.declarations) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$.count = 1;
    $$.declarations[0] = $1;
  }
  ;

parameter_list:
  parameter_list COMMA declaration_only {
    $1->function_declaration->argc++;
    $1->function_declaration->args = (ASTNode **) realloc($1->function_declaration->args, $1->function_declaration->argc * sizeof(ASTNode *));
    if(!$1->function_declaration->args) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $1->function_declaration->args[$1->function_declaration->argc - 1] = $3;
    $$ = $1;
  }
  | declaration_only {
    $$ = ast_node_alloc(NODE_FUNCTION_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->function_declaration->argc = 1;
    $$->function_declaration->args = (ASTNode **) malloc(sizeof(ASTNode *));
    if(!$$->function_declaration->args) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    $$->function_declaration->args[0] = $1;
  }
  | {
    $$ = ast_node_alloc(NODE_FUNCTION_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->function_declaration->argc = 0;
    $$->function_declaration->args = NULL;
  }
  ;

function_declaration:
  INT IDENTIFIER LEFT_PARENTHESIS parameter_list RIGHT_PARENTHESIS scope {
    $$ = $4;

    // If the function has already been declared, raise a syntax error to prevent a redeclaration.
    if(tos_lookup(table_of_symbols, $2)) {
      yyerror("Redeclaration of '%s'!", $2);
      ast_node_free($$);
      YYABORT;
    }

    // Create value object for the identifier.
    Value * value = va_alloc(VALUE_FUNCTION);
    if(!value) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    // Create and add new symbol to the table of symbols.
    Symbol * new_identifier = sy_variable($2, false, value);
    if(!new_identifier) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$);
      YYABORT;
    }
    
    table_of_symbols = tos_append(table_of_symbols, new_identifier);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      sy_free(new_identifier);
      ast_node_free($$);
      YYABORT;
    }

    //$6->scope->name =
    $$->function_declaration->function = new_identifier;
    $$->function_declaration->returns = NULL;
    $$->function_declaration->argc = 0;
    $$->function_declaration->args = NULL;
    $$->function_declaration->body = $6;
  }
  ;

scope:
  LEFT_BRACE statement_list RIGHT_BRACE {
    $$ = $2;
  }
  ;

statement_list:
  statement COLON statement_list { // Statements (except control structures and function declarations) are separated by a colon.
    $3->scope->count++;
    $3->scope->statements = (ASTNode **) realloc($3->scope->statements, $3->scope->count * sizeof(ASTNode *));
    if(!$3->scope->statements) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    printf("Pridávam statement (mám: %lu)\n", $3->scope->count);

    $3->scope->statements[$3->scope->count - 1] = $1;
    $$ = $3;
  }
  | statement COLON {
    $$ = ast_node_alloc(NODE_SCOPE);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->scope->count = 1;
    $$->scope->statements = (ASTNode **) malloc(sizeof(ASTNode *));
    if(!$$->scope->statements) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    $$->scope->statements[0] = $1;
  }
  | control_structure statement_list {
    $2->scope->count++;
    $2->scope->statements = (ASTNode **) realloc($2->scope->statements, $2->scope->count * sizeof(ASTNode *));
    if(!$2->scope->statements) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $2->scope->statements[$2->scope->count - 1] = $1;
    $$ = $2;
  }
  | control_structure {
    $$ = ast_node_alloc(NODE_SCOPE);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->scope->count = 1;
    $$->scope->statements = (ASTNode **) malloc(sizeof(ASTNode *));
    if(!$$->scope->statements) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    $$->scope->statements[0] = $1;
  }
  ;

control_structure:
  IF LEFT_PARENTHESIS expression RIGHT_PARENTHESIS scope { // IF conditional structure without trailing ELSE block
    $$ = ast_node_alloc(NODE_IF);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->if_conditional->condition = $3;
    $$->if_conditional->onif = $5;
    $$->if_conditional->onelse = NULL;
  }
  | IF LEFT_PARENTHESIS expression RIGHT_PARENTHESIS scope ELSE scope { // IF conditional structure with trailing ELSE block
    $$ = ast_node_alloc(NODE_IF);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->if_conditional->condition = $3;
    $$->if_conditional->onif = $5;
    $$->if_conditional->onelse = $7; 
  }
  | WHILE LEFT_PARENTHESIS expression RIGHT_PARENTHESIS scope { // WHILE loop structure
    $$ = ast_node_alloc(NODE_WHILE);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->while_loop->condition = $3;
    $$->while_loop->statements = $5;
  }
  | FOR LEFT_PARENTHESIS assignment COLON expression COLON expression RIGHT_PARENTHESIS scope { // FOR loop structure (no empty specifier items are allowed, also the first item should be an assignment expression)
    $$ = ast_node_alloc(NODE_FOR);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->for_loop->initialization = $3;
    $$->for_loop->condition = $5;
    $$->for_loop->incrementation = $7;
    $$->for_loop->statements = $9;
  }
  | function_declaration {
    $$ = $1;
  }
  ;

statement:
  assignment { // Assignment statement
    $$ = $1;
  }
  | INT declaration_list { // Declaration of a variable or an array
    $$ = $2;
  }
  | STENCIL IDENTIFIER LEFT_BRACE INTEGER COMMA INTEGER RIGHT_BRACE EQUAL initializer { // Declaration of a stencil
    // Number of dimensions of a stencil should be a positive non-null integer
    if($6 < 1) {
      yyerror("Number of dimensions of a stencil should be a positive non-null constant, got '%d'!", $6);
      YYABORT;
    }

    $$ = ast_node_alloc(NODE_SYMBOL_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // If the identifier has already been declared, raise a syntax error to prevent a redeclaration.
    if(tos_lookup(table_of_symbols, $2)) {
      yyerror("Redeclaration of '%s'!", $2);
      ast_node_free($$);
      YYABORT;
    }

    // Create value object for the identifier.
    Value * value = va_alloc(VALUE_STENCIL);
    if(!value) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    // Initialize the stencil value
    value->array.dimensions = $6;
    value->array.sizes = (size_t *) malloc(value->array.dimensions * sizeof(size_t));
    if(!value->array.sizes) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$);
      YYABORT;
    }

    value->array.values = (int *) malloc(value->array.dimensions * sizeof(int));
    if(!value->array.values) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$);
      YYABORT;
    }

    size_t one_size = 1 + $4 * 2, // Size of a stencil is computed based on its neighborhood's size (e. g. a 2D stencil with a neighborhood of 1 will be of size 3x3).
           total_size = 1;
    for(size_t i = 0; i < value->array.dimensions; i++) {
      value->array.sizes[i] = one_size;
      total_size *= one_size;
    }

    if(total_size != $9.count) {
      yyerror("Unexpected element count in initializer of array '%s'!", $2);
      va_free(value);
      ast_node_free($$);
      YYABORT;
    }

    for(size_t i = 0; i < total_size; i++) {
      value->array.values[i] = $9.initializers[i];
    }

    // Create and add new symbol to the table of symbols.
    Symbol * new_identifier = sy_variable($2, false, value);
    if(!new_identifier) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }
    
    table_of_symbols = tos_append(table_of_symbols, new_identifier);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      sy_free(new_identifier);
      ast_node_free($$);
      YYABORT;
    }
  }
  | function_call { // Function call
    $$ = $1;
  }
  | unary_increment_or_decrement {
    $$ = $1;
  }
  ;

declaration_list:
  declaration_list COMMA declaration {
    $1->declaration_list->count++;
    $1->declaration_list->declarations = (ASTNode **) realloc($1->declaration_list->declarations, $1->declaration_list->count * sizeof(ASTNode *));
    if(!$1->declaration_list->declarations) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    if($3->type == NODE_BINARY) {
      $3->binary->LHS->type = NODE_SYMBOL_DECLARATION;
    }

    $1->declaration_list->declarations[$1->declaration_list->count] = $3;
    $$ = $1;
  }
  | declaration {
    $$ = ast_node_alloc(NODE_DECLARATION_LIST);
    if(!$$) {
      perror("Do piče");
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->declaration_list->declarations = (ASTNode **) malloc(sizeof(ASTNode *));
    if(!$$->declaration_list->declarations) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    if($1->type == NODE_BINARY) {
      $1->binary->LHS->type = NODE_SYMBOL_DECLARATION;
    }

    $$->declaration_list->count = 1;
    $$->declaration_list->declarations[0] = $1;
  }
  ;

declaration_only:
  IDENTIFIER { // New variable identifier declaration (e. g. 'myvar')
    $$ = ast_node_alloc(NODE_SYMBOL_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // If the identifier has already been declared, raise a syntax error to prevent a redeclaration.
    if(tos_lookup(table_of_symbols, $1)) {
      yyerror("Redeclaration of '%s'!", $1);
      ast_node_free($$);
      YYABORT;
    }

    // Create value object for the identifier.
    Value * value = va_alloc(VALUE_INTEGER);
    if(!value) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    // Create and add new symbol to the table of symbols.
    Symbol * new_identifier = sy_variable($1, false, value);
    if(!new_identifier) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }
    
    table_of_symbols = tos_append(table_of_symbols, new_identifier);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      sy_free(new_identifier);
      ast_node_free($$);
      YYABORT;
    }
  }
  | IDENTIFIER array_accessor { // New array identifier declaration (e. g. 'tab[10][10]')
    $$ = ast_node_alloc(NODE_SYMBOL_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // If the identifier has already been declared, raise a syntax error to prevent a redeclaration.
    if(tos_lookup(table_of_symbols, $1)) {
      yyerror("Redeclaration of '%s'!", $1);
      ast_node_free($$);
      YYABORT;
    }

    // Create value object for the identifier.
    Value * value = va_alloc(VALUE_ARRAY);
    if(!value) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    value->array.dimensions = $2->access->count;
    value->array.sizes = (size_t *) malloc(value->array.dimensions * sizeof(size_t));
    if(!value->array.sizes) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$);
      YYABORT;
    }

    
    // Gather array dimension sizes.
    for(size_t i = 0; i < value->array.dimensions; i++) {
      if($2->access->accessors[i]->type == NODE_SYMBOL &&
         $2->access->accessors[i]->symbol->is_constant &&
         $2->access->accessors[i]->symbol->value->type == VALUE_INTEGER &&
         $2->access->accessors[i]->symbol->value->integer > 0) {
        value->array.sizes[i] = (size_t) $2->access->accessors[i]->symbol->value->integer;
      } else {
        yyerror("Expected dimension size to be a non-null positive integer literal in declaration of array '%s'!", $1);
        va_free(value);
        ast_node_free($$);
        YYABORT;
      }
    }

    // Create and add new symbol to the table of symbols.
    Symbol * new_identifier = sy_variable($1, false, value);
    if(!new_identifier) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$);
      YYABORT;
    }

    table_of_symbols = tos_append(table_of_symbols, new_identifier);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      sy_free(new_identifier);
      ast_node_free($$);
      YYABORT;
    }
  }
  ;

declaration:
  assignment_variable {
    $$ = $1;
  }
  | declaration_only {
    $$ = $1;
  }
  | IDENTIFIER array_accessor EQUAL initializer { // New array identifier declaration with immediate definition using an initializer list (e. g. 'tab[3] = {1, 2, 3}')
    $$ = ast_node_alloc(NODE_SYMBOL_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // If the identifier has already been declared, raise a syntax error to prevent a redeclaration.
    if(tos_lookup(table_of_symbols, $1)) {
      yyerror("Redeclaration of '%s'!", $1);
      ast_node_free($$);
      YYABORT;
    }

    // Create value object for the identifier.
    Value * value = va_alloc(VALUE_ARRAY);
    if(!value) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    value->array.dimensions = $2->access->count;
    value->array.sizes = (size_t *) malloc(value->array.dimensions * sizeof(size_t));
    if(!value->array.sizes) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$);
      YYABORT;
    }

    
    // Gather array dimension sizes.
    size_t values_size = 1;
    for(size_t i = 0; i < value->array.dimensions; i++) {
      if($2->access->accessors[i]->type == NODE_SYMBOL &&
         $2->access->accessors[i]->symbol->is_constant &&
         $2->access->accessors[i]->symbol->value->type == VALUE_INTEGER &&
         $2->access->accessors[i]->symbol->value->integer > 0) {
        value->array.sizes[i] = (size_t) $2->access->accessors[i]->symbol->value->integer;
        values_size *= value->array.sizes[i];
      } else {
        yyerror("Expected dimension size to be a non-null positive integer literal in declaration of array '%s'!", $1);
        va_free(value);
        ast_node_free($$);
        YYABORT;
      }
    }

    if(values_size != $4.count) {
      yyerror("Unexpected element count in initializer of array '%s'!", $1);
      va_free(value);
      ast_node_free($$);
      YYABORT;
    }

    value->array.values = (int *) malloc(values_size * sizeof(int));
    if(!value->array.values) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$);
      YYABORT;
    }

    for(size_t i = 0; i < values_size; i++) {
      value->array.values[i] = $4.initializers[i];
    }

    // Create and add new symbol to the table of symbols.
    Symbol * new_identifier = sy_variable($1, false, value);
    if(!new_identifier) {
      STENC_MEMORY_ERROR;
      va_free(value);
      ast_node_free($$);
      YYABORT;
    }
  }
  ;

assignment:
  assignment_variable | assignment_array {
    $$ = $1;
  }
  ;

assignment_variable:
  IDENTIFIER EQUAL expression { // Assignment to a variable (e. g. 'foo = 12;')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // Create new AST node for the lvalue.
    ASTNode * lvalue = ast_node_alloc(NODE_SYMBOL);
    if(!lvalue) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    // Create value object for the identifier.
    Value * value = va_alloc(VALUE_INTEGER);
    if(!value) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    bool is_constant = false;

    if($3->type == NODE_SYMBOL && $3->symbol->is_constant) {
      value->integer = $3->symbol->value->integer;
      is_constant = true;
    }

    // Create and add new symbol to the table of symbols.
    Symbol * new_identifier = sy_variable($1, is_constant, value);
    if(!new_identifier) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    table_of_symbols = tos_append(table_of_symbols, new_identifier);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      sy_free(new_identifier);
      ast_node_free($$);
      YYABORT;
    }

    lvalue->symbol = new_identifier;

    $$->binary->operation = BO_ASSIGNMENT;
    $$->binary->LHS = lvalue;
    $$->binary->RHS = $3;
  }
  ;

assignment_array:  
  IDENTIFIER array_accessor EQUAL expression {
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // Check whether the destination array has been declared.
    Symbol * existing = NULL;
    if(!(existing = tos_lookup(table_of_symbols, $1))) {
      yyerror("Undeclared identifier '%s'!", $1);
      YYABORT;
    }

    $2->access->array = existing;

    $$->binary->operation = BO_ASSIGNMENT;
    $$->binary->LHS = $2;
    $$->binary->RHS = $4;
  }
  ;

unary_increment_or_decrement:
  PLUSPLUS expression %prec UINCREMENT { // Unary increment with priority (e. g. '++i')
    $$ = ast_node_alloc(NODE_UNARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->unary->operation = UO_PLUSPLUS;
    $$->unary->expression = $2;
  }
  | expression PLUSPLUS { // Unary increment (e. g. 'i++')
    $$ = ast_node_alloc(NODE_UNARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->unary->operation = UO_PLUSPLUS;
    $$->unary->expression = $1;
  }
  | MINUSMINUS expression %prec UINCREMENT { // Unary decrement with priority (e. g. '--i')
    $$ = ast_node_alloc(NODE_UNARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->unary->operation = UO_MINUSMINUS;
    $$->unary->expression = $2;
  }
  | expression MINUSMINUS { // Unary decrement (e. g. 'i--')
    $$ = ast_node_alloc(NODE_UNARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->unary->operation = UO_MINUSMINUS;
    $$->unary->expression = $1;
  }
  ;

expression:
  function_call { // Function call
    $$ = $1;
  }
  | expression AND expression { // Logical 'and' (e. g. '(12 + test) && foo')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_AND;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | expression OR expression { // Logical 'or' (e. g. '(12 + test) || foo')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_OR;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | expression LESS expression { // Comparison operator '<' (e. g. '(12 + test) < foo')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_LESS;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | expression LESS_OR_EQUAL expression { // Comparison operator '<=' (e. g. '(12 + test) <= foo')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_LESS_OR_EQUAL;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | expression GREATER_OR_EQUAL expression { // Comparison operator '>=' (e. g. '(12 + test) < foo')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_GREATER_OR_EQUAL;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | expression GREATER expression { // Comparison operator '>' (e. g. '(12 + test) < foo')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_GREATER;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | expression EQUALEQUAL expression { // Comparison operator '==' (e. g. '(12 + test) < foo')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_EQUAL;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | NOT expression %prec UNOT { // Logical negation (e. g. '!bar')
    $$ = ast_node_alloc(NODE_UNARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->unary->operation = UO_NOT;
    $$->unary->expression = $2;
  }
  | expression PLUS expression { // Sum (e. g. '3 + foo')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_SUM;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | expression MINUS expression { // Difference (e. g. 'bar - 12')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_DIFFERENCE;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | expression STAR expression { // Multiplication (e. g. 'foo * bar')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_MULTIPLICATION;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | expression SLASH expression { // Division (e. g. '12 / (3 + foo * bar)')
    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->binary->operation = BO_DIVISION;
    $$->binary->LHS = $1;
    $$->binary->RHS = $3;
  }
  | expression DOLLAR expression { // Stencil binary operation (e. g. 'tab[3][3] $ sten1')
    if(($1->type == NODE_ARRAY_ACCESS && $3->type == NODE_SYMBOL && $3->symbol->value->type == VALUE_STENCIL) || ($3->type == NODE_ARRAY_ACCESS && $1->type == NODE_SYMBOL && $1->symbol->value->type == VALUE_STENCIL)) {
      $$ = ast_node_alloc(NODE_BINARY);
      if(!$$) {
        STENC_MEMORY_ERROR;
        YYABORT;
      }

      $$->binary->operation = BO_STENCIL;
      $$->binary->LHS = $1;
      $$->binary->RHS = $3;
    } else {
      yyerror("Stencil operator can be only applied between a stencil and an array reference!");
      YYABORT;
    }
  }
  | LEFT_PARENTHESIS expression RIGHT_PARENTHESIS { // Parenthesis expression (e. g. '(10 / foo)')
    $$ = $2;
  }
  | MINUS expression %prec UMINUS { // Sign change (e. g. '-(8 + bar)')
    $$ = ast_node_alloc(NODE_UNARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->unary->operation = UO_MINUS;
    $$->unary->expression = $2;
  }
  | unary_increment_or_decrement {
    $$ = $1;
  }
  | IDENTIFIER array_accessor { // Array item reference (e. g. 'tab[0][i + 1]')
    // Check if the array identified by the parsed identifier has been defined.
    Symbol * existing = NULL;
    if((existing = tos_lookup(table_of_symbols, $1))) {
      // Create new symbol AST node.
      $$ = $2;
      $$->access->array = existing;
    } else {
      // Otherwise, abort parsing and raise a syntax error.
      yyerror("Undefined variable '%s'!", $1);
      ast_node_free($$);
      YYABORT;
    }
  }
  | IDENTIFIER { // Variable reference (e. g. 'foo')
    // Check if the variable identified by the parsed identifier has been defined.
    Symbol * existing = NULL;
    if((existing = tos_lookup(table_of_symbols, $1))) {
      // Create new symbol AST node.
      $$ = ast_node_alloc(NODE_SYMBOL);
      if(!$$) {
        STENC_MEMORY_ERROR;
        YYABORT;
      }

      $$->symbol = existing;
    } else {
      // Otherwise, abort parsing and raise a syntax error.
      yyerror("Undefined variable '%s'!", $1);
      YYABORT;
    }
  }
  | INTEGER { // Integer literal (e. g. '12')
    // Create new symbol AST node.
    $$ = ast_node_alloc(NODE_SYMBOL);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // Create value corresponding to the parsed integer value.
    Value * integer = va_alloc(VALUE_INTEGER);
    if(!integer) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    integer->integer = $1;

    // Create and then add a new temporary, having the parsed value, to the table of symbols and link it to the AST node we've created above.
    $$->symbol = sy_temporary(true, integer);
    if(!$$->symbol) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    table_of_symbols = tos_append(table_of_symbols, $$->symbol);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      sy_free($$->symbol);
      ast_node_free($$);
      YYABORT;
    }
  }
  ;

%%
