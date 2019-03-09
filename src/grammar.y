%{
  #include <stdarg.h>
  #include "../include/main.h"

  static int scope = 0;

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
}

%define parse.error verbose

%token MAIN RETURN INT STENCIL IF ELSE WHILE FOR PRINTI PRINTF LESS LESS_OR_EQUAL GREATER GREATER_OR_EQUAL NOT AND OR EQUALEQUAL PLUS MINUS STAR SLASH DOLLAR EQUAL LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE COMMA COLON MINUSMINUS PLUSPLUS VOID
%token <string> IDENTIFIER STRING
%token <integer> INTEGER

%type <integer> integer_constant
%type <node> array_accessor function_call function_declaration parameter_list scope statement_list control_structure statement declaration declaration_only assignment assignment_array assignment_variable expression declaration_list unary_increment_or_decrement initializer integer_constant_list argument_list

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
    Value * array = va_alloc(VALUE_ARRAY);
    if(!array) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    array->values = g_array_new(FALSE, FALSE, sizeof(int));
    if(!array->values) {
      STENC_MEMORY_ERROR;
      va_free(array);
      YYABORT;
    }

    array->values = g_array_append_val(array->values, $1);

    Symbol * symbol = sy_alloc();
    if(!symbol) {
      STENC_MEMORY_ERROR;
      va_free(array);
      YYABORT;
    }

    symbol->value = array;

    $$ = ast_node_alloc(NODE_SYMBOL_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
      sy_free(symbol);
      YYABORT;
    }

    $$->symbol = symbol;
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
    $1->symbol->value->array->values = g_array_append_vals($1->symbol->value->array->values, $3->symbol->value->array->values, $3->symbol->value->array->values->len);
    $$ = $1;
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
    $1->access->accessors = g_ptr_array_add($1->access->accessors, (gpointer) $3);
    $$ = $1;
  }
	| LEFT_BRACKET expression RIGHT_BRACKET {
    $$ = ast_node_alloc(NODE_ARRAY_ACCESS);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->access->accessors = g_ptr_array_new();
    if(!$$->access->accessors) {
      ast_node_free($$);
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->access->accessors = g_ptr_array_add($$->access->accessors, (gpointer) $2);
  }
  ;

array_accessor_constant:
	array_accessor LEFT_BRACKET integer_constant RIGHT_BRACKET {
    $1->symbol->value->array.sizes = g_array_append_val($1->symbol->value->array.sizes, $3);
    $1->symbol->value->array.dimensions++;
    $$ = $1;
  }
	| LEFT_BRACKET integer_constant RIGHT_BRACKET {
    Value * array = va_alloc(VALUE_ARRAY);
    if(!array) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    array->array.sizes = g_array_new(FALSE, TRUE, sizeof(int));
    if(!array->sizes) {
      STENC_MEMORY_ERROR;
      va_free(array);
      YYABORT;
    }

    array->array.sizes = g_array_append_val(array->array.sizes, $1);
    array->array.dimensions = 1;

    Symbol * symbol = sy_alloc();
    if(!symbol) {
      STENC_MEMORY_ERROR;
      va_free(array);
      YYABORT;
    }

    symbol->value = array;

    $$ = ast_node_alloc(NODE_SYMBOL_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
      sy_free(symbol);
      YYABORT;
    }

    $$->symbol = symbol;
  }
  ;

function_call:
  IDENTIFIER LEFT_PARENTHESIS argument_list RIGHT_PARENTHESIS {
    Value * function = va_alloc(VALUE_FUNCTION);
    if(!function) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    Symbol * symbol = sy_variable($1, false, function);
    if(!symbol) {
      STENC_MEMORY_ERROR;
      va_free(function);
      YYABORT;
    }

    $3->function_call->function = symbol;
    $$ = $3;
  }
  ;

argument_list:
  argument_list COMMA expression {
    $1->function_call->argv = g_ptr_array_add($1->function_call->argv, (gpointer) $3);
    $$ = $1;
  }
  | expression {
    $$ = ast_node_alloc(NODE_FUNCTION_CALL);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->function_call->argv = g_ptr_array_new();
    if(!$$->function_call->argv) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    $$->function_call->argv = g_ptr_array_add($$->function_call->argv, (gpointer) $1);
  }
  ;

parameter_list:
  parameter_list_non_void {
    $$ = $1;
  }
  | {
    $$ = ast_node_alloc(NODE_FUNCTION_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }
  }
  ;

parameter_list_non_void:
  parameter_list_non_void COMMA declaration_only {
    $1->function_declaration->args = g_ptr_array_add($1->function_declaration->args, $3);
    $$ = $1;
  }
  | declaration_only {
    $$ = ast_node_alloc(NODE_FUNCTION_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->function_declaration->args = g_ptr_array_new();
    if(!$$->function_declaration->args) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    $$->function_declaration->args = g_ptr_array_add($$->function_declaration->args, $1);
  }
  ;

function_declaration:
  IDENTIFIER LEFT_PARENTHESIS parameter_list RIGHT_PARENTHESIS scope {
    for(guint i = 0; i < $4->function_declaration->args->len; i++) {
      Symbol * arg = g_ptr_array_index($4->function_declaration->args, i);
      arg->scopes = g_array_append_val(arg->scopes, scope);
    }

    scope++;

    // Create value object for the identifier.
    Value * function = va_alloc(VALUE_FUNCTION);
    if(!function) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    // Create and add new symbol to the table of symbols.
    Symbol * symbol = sy_variable($2, false, function);
    if(!symbol) {
      STENC_MEMORY_ERROR;
      va_free(function);
      YYABORT;
    }
    
    table_of_symbols = tos_append(table_of_symbols, symbol);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      sy_free(symbol);
      YYABORT;
    }

    $4->function_declaration->function = symbol;
    $4->function_declaration->body = $6;

    $$ = $4;
  }
  ;

scope:
  LEFT_BRACE statement_list RIGHT_BRACE {
    $$ = $2;
  }
  ;

statement_list:
  statement COLON statement_list { // Statements (except control structures and function declarations) are separated by a colon.
    $2->scope->statements = g_ptr_array_add($2->scope->statements, $1);
    $$ = $2;
  }
  | statement COLON {
    $$ = ast_node_alloc(NODE_SCOPE);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->scope->statements = g_ptr_array_new();
    if(!$$->scope->statements) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    $$->scope->statements = g_ptr_array_add($$->scope->statements, $1);
  }
  | control_structure statement_list {
    $2->scope->statements = g_ptr_array_add($2->scope->statements, $1);
    $$ = $2;
  }
  | control_structure {
    $$ = ast_node_alloc(NODE_SCOPE);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->scope->statements = g_ptr_array_new();
    if(!$$->scope->statements) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    $$->scope->statements = g_ptr_array_add($$->scope->statements, $1);
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
  | INT function_declaration {
    $1->function_declaration->returns = RETURNS_INTEGER;
    $$ = $1;
  }
  | VOID function_declaration {
    $1->function_declaration->returns = RETURNS_VOID;
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
  | STENCIL stencil_declaration_list {
    $$ = $2;
  }
  | function_call { // Function call
    $$ = $1;
  }
  | unary_increment_or_decrement {
    $$ = $1;
  }
  ;

stencil_declaration_list:
  stencil_declaration_list COMMA stencil_declaration {
    $1->declaration_list->declarations = g_ptr_array_add($1->declaration_list->declarations, (gpointer) $3);
    $$ = $1;
  }
  | stencil_declaration {
    $$ = ast_node_alloc(NODE_DECLARATION_LIST);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->declaration_list->declarations = g_ptr_array_new();
    if(!$$->declaration_list->declarations) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    $$->declaration_list->declarations = g_ptr_array_add($$->declaration_list->declarations, (gpointer) $1);
  }
  ;

stencil_declaration:
  IDENTIFIER LEFT_BRACE INTEGER COMMA INTEGER RIGHT_BRACE EQUAL initializer { // Declaration of a stencil
    // Number of dimensions of a stencil should be a positive non-null integer
    if($5 < 1) {
      yyerror("Number of dimensions of a stencil should be a positive non-null constant, got '%d'!", $6);
      YYABORT;
    }

    $8->symbol->value->type = VALUE_STENCIL;

    // Initialize the stencil value
    $8->symbol->value->array.dimensions = $6;
    $8->symbol->value->array.sizes = g_array_new(FALSE, TRUE, sizeof(size_t));
    if(!$8->symbol->value->array.sizes) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $8->symbol->value->array.values = g_array_new(FALSE, TRUE, sizeof(int));
    if(!$8->symbol->value->array.values) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    size_t one_size = 1 + $4 * 2, // Size of a stencil is computed based on its neighborhood's size (e. g. a 2D stencil with a neighborhood of 1 will be of size 3x3).
           total_size = 1;
    for(size_t i = 0; i < $8->symbol->value->array.dimensions; i++) {
      $8->symbol->value->array.sizes = g_array_append_val($8->symbol->value->array.sizes, one_size);
      total_size *= one_size;
    }

    if(total_size != $8->symbol->value->array.values->len) {
      yyerror("Unexpected element count in initializer of array '%s'!", $2);
      YYABORT;
    }

    $8->symbol->identifier = strdup($1);
    if(!$8->symbol->identifier) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }
    
    table_of_symbols = tos_append(table_of_symbols, $8->symbol);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$ = $8;
  }
  ;

declaration_list:
  declaration_list COMMA declaration {
    if($3->type == NODE_BINARY) {
      $3->binary->LHS->type = NODE_SYMBOL_DECLARATION;
    }

    $1->declaration_list->declarations = g_ptr_array_add($1->declaration_list->declarations, (gpointer) $3);
    $$ = $1;
  }
  | declaration {
    $$ = ast_node_alloc(NODE_DECLARATION_LIST);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->declaration_list->declarations = g_ptr_array_new();
    if(!$$->declaration_list->declarations) {
      STENC_MEMORY_ERROR;
      ast_node_free($$);
      YYABORT;
    }

    if($1->type == NODE_BINARY) {
      $1->binary->LHS->type = NODE_SYMBOL_DECLARATION;
    }

    $$->declaration_list->declarations = g_ptr_array_add($$->declaration_list->declarations, (gpointer) $1);
  }
  ;

declaration_only:
  IDENTIFIER { // New variable identifier declaration (e. g. 'myvar')
    $$ = ast_node_alloc(NODE_SYMBOL_DECLARATION);
    if(!$$) {
      STENC_MEMORY_ERROR;
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
  | IDENTIFIER array_accessor_constant { // New array identifier declaration (e. g. 'tab[10][10]')
    $1->symbol->identifier = strdup($1);
    if(!$1->symbol->identifier) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    table_of_symbols = tos_append(table_of_symbols, $1->symbol);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$ = $1;
  }
  ;

declaration:
  assignment_variable {
    $$ = $1;
  }
  | declaration_only {
    $$ = $1;
  }
  | IDENTIFIER array_accessor_constant EQUAL initializer { // New array identifier declaration with immediate definition using an initializer list (e. g. 'tab[3] = {1, 2, 3}')
    size_t expected_value_count = 1;
    for(guint i = 0; i < $2->symbol->value->array.sizes->len; i++) {
      expected_value_count *= g_array_index($2->symbol->value->array.sizes, size_t, i);
    }

    if(expected_value_count != $4->symbol->value->array.values->len) {
      yyerror("Unexpected element count in initializer of array '%s'!", $1);
      YYABORT;
    }

    $2->symbol->value->array.values = g_array_new(FALSE, TRUE, sizeof(int));
    if(!$2->symbol->value->array.values) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    for(guint i = 0; i < $4->symbol->value->array.values->len; i++) {
      $2->symbol->value->array.values = g_array_append_val($2->symbol->value->array.values, g_array_index($4->symbol->value->array.values, int, i));
    }

    // Create and add new symbol to the table of symbols.
    $2->symbol->identifier = strdup($1);
    if(!$2->symbol->identifier) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    ast_node_free($4);
    $$ = $2;
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
    Value * array = va_alloc(VALUE_ARRAY);
    if(!array) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    Symbol * symbol = sy_variable($1, false, array);
    if(!symbol) {
      STENC_MEMORY_ERROR;
      va_free(array);
      YYABORT;
    }

    $2->access->array = symbol;

    $$ = ast_node_alloc(NODE_BINARY);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

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
    Value * array = va_alloc(VALUE_ARRAY);
    if(!array) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    Symbol * symbol = sy_variable($1, false, array);
    if(!symbol) {
      STENC_MEMORY_ERROR;
      va_free(array);
      YYABORT;
    }

    $2->access->array = symbol;
    $$ = $2;
  }
  | IDENTIFIER { // Variable reference (e. g. 'foo')
    Value * integer = va_alloc(VALUE_INTEGER);
    if(!integer) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    Symbol * symbol = sy_variable($1, false, integer);
    if(!symbol) {
      STENC_MEMORY_ERROR;
      va_free(integer);
      YYABORT;
    }

    table_of_symbols = tos_append(table_of_symbols, symbol);
    if(!table_of_symbols) {
      STENC_MEMORY_ERROR;
      sy_free(symbol);
      YYABORT;
    }

    $$ = ast_node_alloc(NODE_SYMBOL);
    if(!$$) {
      STENC_MEMORY_ERROR;
      YYABORT;
    }

    $$->symbol = symbol;
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
