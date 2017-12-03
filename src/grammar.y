%{
  #include "../include/main.h"

  int yylex();
  void yyerror(char*);
%}

%union{
  int value;
  Operation operator;
  char * name;
  struct {
    Symbol * pointer;
    Quad * code;
  } generic;
  struct {
    Symbol * pointer;
    Quad * code,
      * truelist,
      * falselist;
  } boolean;
}

%define parse.error verbose

%token INT TAB MAIN PRINTI END IF ELSE WHILE
%token <value> NUMBER
%token <operator> BOP_COMPARISON BOP_OR BOP_AND BOP_NOT
%token <name> ID
%type <generic> list statement variable declaration assignment expression
%type <boolean> bool
%left '+' '-'
%left '*' '/'
%left UMINUS
%left '('
%left BOP_COMPARISON BOP_OR
%left BOP_AND
%left BOP_NOT
%start init

%%
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
  | structControl list {}
  | structControl {}
  ;

structControl:
  IF '(' exprBool ')' '{' list '}' {printf("if sans else\n");}
  | IF '(' exprBool ')' '{' list '}' ELSE '{' list '}' {printf("if avec else\n");}
  | WHILE '(' exprBool ')' '{' list '}'	{printf("boucle while\n");}
;

exprBool:
	| exprBool BOP_AND exprBool {
    //complete lists
    $$.code = qu_concatenate($1.code, $3.code);
    $$.truelist = $3.truelist;
    $$.falselist = qu_concatenate($1.falselist, $3.falselist);
  }
	| exprBool BOP_OR exprBool {
    //complete lists
    $$.code = qu_concatenate($1.code, $3.code);
    $$.truelist = qu_concatenate($1.truelist, $3.truelist);
    $$.falselist = $3.falselist;
  }
  | BOP_NOT exprBool {
    $$.code = $2.code;
    $$.truelist = $2.falselist;
    $$.falselist = $2.truelist;
  }
  | '(' exprBool ')' {
    $$.code = $2.code;
    $$.truelist = $2.truelist;
    $$.falselist = $2.falselist;
  }
  | bool
	;

bool:
	expression BOP_COMPARISON expression {
    if($1.pointer->type == TYPE_INTEGER && $3.pointer->type == TYPE_INTEGER) {
      Quad * ontrue = qu_generate(), * onfalse = qu_generate();

      ontrue->op = $2;
      ontrue->arg1 = $1.pointer;
      ontrue->arg2 = $3.pointer;

      onfalse->op = OP_GOTO;

      $$.truelist = ontrue;
      $$.falselist = onfalse;
      $$.code = qu_concatenate(ontrue, onfalse);
      $$.code = qu_concatenate($$.code, $1.code);
      $$.code = qu_concatenate($$.code, $3.code);
    } else {
      fprintf(stderr, "Syntax error: Comparison is possible only if both operands have integer type!\n");
      exit(EXIT_FAILURE);
    }
  }
	| expression {
    $$.pointer = $1.pointer;
    $$.code = $1.code;
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

    n->op = OP_CALL_PRINT;
    n->arg1 = $3.pointer;
    $$.code = qu_concatenate($3.code, n);
  }
  ;

variable:
  variable ',' declaration {
    $$.code = qu_concatenate($1.code, $3.code);
  }
	| declaration {
    $$.code = $1.code;
  }
	;

declaration:
  assignment {
    $$.code = $1.code;
  }
  | ID {
    Symbol * symbol = NULL;

    if((symbol = sy_lookup(table, yylval.name)) == NULL) {
      table = sy_add_variable(table, yylval.name, false, TYPE_INTEGER, NULL);
      $$.pointer = table;
    } else {
      $$.pointer = symbol;
    }

    $$.code = NULL;
  }
  ;

assignment:
  ID '=' expression {
    Symbol * symbol = NULL;
    Quad * n = qu_generate();

    if((symbol = sy_lookup(table, $1)) == NULL) {
      table = sy_add_variable(table, $1, false, $3.pointer->type, NULL);
      $$.pointer = table;
    } else {
      $$.pointer = symbol;
    }

    n->op = OP_ASSIGN;
    n->arg1 = $3.pointer;
    n->result = $$.pointer;
    $$.code = qu_concatenate($3.code, n);
  }
  ;

expression :
  expression '+' expression {
    if($1.pointer->type == TYPE_INTEGER && $3.pointer->type == TYPE_INTEGER) {
      Quad * n = qu_generate();

      table = sy_add_temporary(table, NULL, $1.pointer->type, NULL);
      $$.pointer = table;
      n->op = OP_ADD;
      n->arg1 = $1.pointer;
      n->arg2 = $3.pointer;
      n->result = $$.pointer;
      $$.code = qu_concatenate($1.code, $3.code);
      $$.code = qu_concatenate($$.code, n);
    } else {
      fprintf(stderr, "Syntax error: Addition is possible only if both operands have integer type!\n");
      exit(EXIT_FAILURE);
    }
  }
  | expression '-' expression {
    if($1.pointer->type == TYPE_INTEGER && $3.pointer->type == TYPE_INTEGER) {
      Quad * n = qu_generate();

      table = sy_add_temporary(table, NULL, $1.pointer->type, NULL);
      $$.pointer = table;
      n->op = OP_SUBTRACT;
      n->arg1 = $1.pointer;
      n->arg2 = $3.pointer;
      n->result = $$.pointer;
      $$.code = qu_concatenate($1.code, $3.code);
      $$.code = qu_concatenate($$.code, n);
    } else {
      fprintf(stderr, "Syntax error: Subtraction is possible only if both operands have integer type!\n");
      exit(EXIT_FAILURE);
    }
  }
  | expression '*' expression {
    if($1.pointer->type == TYPE_INTEGER && $3.pointer->type == TYPE_INTEGER) {
      Quad * n = qu_generate();

      table = sy_add_temporary(table, NULL, $1.pointer->type, NULL);
      $$.pointer = table;
      n->op = OP_MULTIPLY;
      n->arg1 = $1.pointer;
      n->arg2 = $3.pointer;
      n->result = $$.pointer;
      $$.code = qu_concatenate($1.code, $3.code);
      $$.code = qu_concatenate($$.code, n);
    } else {
      fprintf(stderr, "Syntax error: Multiplication is possible only if both operands have integer type!\n");
      exit(EXIT_FAILURE);
    }
  }
  | expression '/' expression {
    if($1.pointer->type == TYPE_INTEGER && $3.pointer->type == TYPE_INTEGER) {
      Quad * n = qu_generate();

      table = sy_add_temporary(table, NULL, $1.pointer->type, NULL);
      $$.pointer = table;
      n->op = OP_DIVIDE;
      n->arg1 = $1.pointer;
      n->arg2 = $3.pointer;
      n->result = $$.pointer;
      $$.code = qu_concatenate($1.code, $3.code);
      $$.code = qu_concatenate($$.code, n);
    } else {
      fprintf(stderr, "Syntax error: Division is possible only if both operands have integer type!\n");
      exit(EXIT_FAILURE);
    }
  }
  | '-' expression %prec UMINUS {
    Quad * n = qu_generate();

    table = sy_add_temporary(table, false, $2.pointer->type, NULL);
    $$.pointer = table;
    n->op = OP_UMINUS;
    n->arg1 = $2.pointer;
    n->result = $$.pointer;
    $$.code = qu_concatenate($2.code, n);
  }
  | '(' expression ')' {
    $$.pointer = $2.pointer;
    $$.code = $2.code;
  }
  | ID {
    Symbol * symbol = NULL;

    if((symbol = sy_lookup(table, yylval.name)) != NULL) {
      $$.pointer = symbol;
    } else {
      fprintf(stderr, "Syntax error: %s is undeclared!\n", yylval.name);
      exit(EXIT_FAILURE);
    }

    $$.code = NULL;
  }
  | NUMBER {
    Value * value = va_alloc();

    value->integer = yylval.value;
    table = sy_add_temporary(table, true, TYPE_INTEGER, value);
    $$.pointer = table;
    $$.code = NULL;
  }
  ;

%%
