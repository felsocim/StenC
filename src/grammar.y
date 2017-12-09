%{
  #include "../include/main.h"

  int yylex();
  void yyerror(char*);
%}

%union{
  int value;
  Operation operator;
  char * name;
  Value * array;
  struct {
    Symbol * pointer;
    Quad * code;
  } generic;
  struct {
    Symbol * pointer;
    Quad * code;
    QList * truelist,
      * falselist;
  } boolean;
  intList* iList;
}

%define parse.error verbose

%token INT MAIN PRINTI PRINTF END IF ELSE WHILE STENCIL STRING
%token <value> NUMBER
%token <operator> BOP_COMPARISON BOP_OR BOP_AND BOP_NOT
%token <name> ID
%type <generic> list statement structControl variable declaration assignment expression
%type <boolean> bool exprBool
%type <iList> inittab listInit
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS
%left '('
%left BOP_COMPARISON BOP_OR
%left BOP_AND
%nonassoc BOP_NOT
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
;

exprBool:
	exprBool BOP_AND exprBool {
    Quad * label = qu_generate();

    table = sy_add_label(table, NULL);

    label->op = OP_LABEL;
    label->result = table;

    $1.truelist = ql_complete($1.truelist, table);
    $$.code = $1.code;
    $$.code = qu_concatenate($$.code, label);
    $$.code = qu_concatenate($$.code, $3.code);
    $$.truelist = $3.truelist;
    $$.falselist = ql_concatenate($1.falselist, $3.falselist);
  }
	| exprBool BOP_OR exprBool {
    Quad * label = qu_generate();

    table = sy_add_label(table, NULL);

    label->op = OP_LABEL;
    label->result = table;

    $1.falselist = ql_complete($1.falselist, table);
    $$.code = $1.code;
    $$.code = qu_concatenate($$.code, label);
    $$.code = qu_concatenate($$.code, $3.code);
    $$.truelist = ql_concatenate($1.truelist, $3.truelist);
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
  | bool {
    $$.code = $1.code;
    $$.truelist = $1.truelist;
    $$.falselist = $1.falselist;
  }
	;

bool:
	expression BOP_COMPARISON expression {
    if($1.pointer->type == TYPE_INTEGER && $3.pointer->type == TYPE_INTEGER) {
      Quad * ontrue = qu_generate(), * onfalse = qu_generate();

      ontrue->op = $2;
      ontrue->arg1 = $1.pointer;
      ontrue->arg2 = $3.pointer;

      onfalse->op = OP_GOTO;

      $$.truelist = ql_init(QL_GROW_SIZE);
      $$.truelist = ql_insert($$.truelist, ontrue);
      $$.falselist = ql_init(QL_GROW_SIZE);
      $$.falselist = ql_insert($$.falselist, onfalse);
      $$.code = qu_concatenate(ontrue, onfalse);
      $$.code = qu_concatenate($$.code, $1.code);
      $$.code = qu_concatenate($$.code, $3.code);
    } else {
      fprintf(stderr, "Syntax error: Comparison is possible only if both operands have integer type!\n");
      exit(EXIT_FAILURE);
    }
  }
  | BOP_NOT expression {
    if($2.pointer->type == TYPE_INTEGER) {
      Symbol * zero = NULL;
      Quad * ontrue = qu_generate(), * onfalse = qu_generate();

      Value * v0 = va_alloc();
      v0->integer = 0;

      table = sy_add_temporary(table, true, TYPE_INTEGER, v0);
      zero = table;

      ontrue->op = OP_EQ;
      ontrue->arg1 = $2.pointer;
      ontrue->arg2 = zero;

      onfalse->op = OP_GOTO;

      $$.truelist = ql_init(QL_GROW_SIZE);
      $$.truelist = ql_insert($$.truelist, ontrue);
      $$.falselist = ql_init(QL_GROW_SIZE);
      $$.falselist = ql_insert($$.falselist, onfalse);
      $$.code = qu_concatenate(ontrue, onfalse);
      $$.code = qu_concatenate($$.code, $2.code);
    } else {
      fprintf(stderr, "Syntax error: Comparison is possible only if both operands have integer type!\n");
      exit(EXIT_FAILURE);
    }
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
  | STENCIL ID '{' inittab '}' '=' listInit {printf("StenC reconnu, liste du stencil :\n");
						print_intList($7);}
  ;

listInit:
	listInit ',' listInit  {$$ = intListConcat($1,$3);}
	| '{' inittab '}' { $$ = $2; }
	| '{' listInit '}' {$$ = $2;}
	;

inittab:
	inittab ',' NUMBER { $$ = intListPushBack($1,$3); }
	|NUMBER {$$ = intListCreate();
		$$ = intListPushBack($$,$1); }

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
  | ID rtab {printf("tableau non-initialisee\n");}
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
  | ID '=' exprBool {
    Symbol * symbol = NULL, * result = NULL, * zero = NULL, * one = NULL;
    Quad * ontrue = qu_generate(), * onfalse = qu_generate(), * after = qu_generate(), * n = qu_generate(), * ontruev = qu_generate(), * onfalsev = qu_generate(), * goafter = qu_generate();

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    result = table;

    Value * v0 = va_alloc(), * v1 = va_alloc();
    v0->integer = 0;
    v1->integer = 1;

    table = sy_add_temporary(table, true, TYPE_INTEGER, v0);
    zero = table;

    table = sy_add_temporary(table, true, TYPE_INTEGER, v1);
    one = table;

    if((symbol = sy_lookup(table, $1)) == NULL) {
      table = sy_add_variable(table, $1, false, $3.pointer->type, NULL);
      $$.pointer = table;
    } else {
      $$.pointer = symbol;
    }

    n->op = OP_ASSIGN;
    n->arg1 = result;
    n->result = $$.pointer;

    table = sy_add_label(table, NULL);

    ontrue->op = OP_LABEL;
    ontrue->result = table;

    table = sy_add_label(table, NULL);

    onfalse->op = OP_LABEL;
    onfalse->result = table;

    table = sy_add_label(table, NULL);

    after->op = OP_LABEL;
    after->result = table;

    ontruev->op = OP_ASSIGN;
    ontruev->arg1 = one;
    ontruev->result = result;

    onfalsev->op = OP_ASSIGN;
    onfalsev->arg1 = zero;
    onfalsev->result = result;

    goafter->op = OP_GOTO;
    goafter->result = after->result;

    $3.truelist = ql_complete($3.truelist, ontrue->result);
    $3.falselist = ql_complete($3.falselist, onfalse->result);

    $$.code = $3.code;
    $$.code = qu_concatenate($$.code, ontrue);
    $$.code = qu_concatenate($$.code, ontruev);
    $$.code = qu_concatenate($$.code, goafter);
    $$.code = qu_concatenate($$.code, onfalse);
    $$.code = qu_concatenate($$.code, onfalsev);
    $$.code = qu_concatenate($$.code, after);
    $$.code = qu_concatenate($$.code, n);

    ql_free($3.truelist);
    ql_free($3.falselist);
  }
  | ID rtab '=' listInit {printf("tableau initialisee\n");}
 // | ID rtab '=' expression {}
  ;

expression :
  expression '+' expression {
    if($1.pointer->type == TYPE_INTEGER && $3.pointer->type == TYPE_INTEGER) {
      Quad * n = qu_generate();

      table = sy_add_temporary(table, false, $1.pointer->type, NULL);
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

      table = sy_add_temporary(table, false, $1.pointer->type, NULL);
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

      table = sy_add_temporary(table, false, $1.pointer->type, NULL);
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

      table = sy_add_temporary(table, false, $1.pointer->type, NULL);
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
    if($2.pointer->type == TYPE_INTEGER) {
      Quad * n = qu_generate();

      table = sy_add_temporary(table, false, $2.pointer->type, NULL);
      $$.pointer = table;
      n->op = OP_UMINUS;
      n->arg1 = $2.pointer;
      n->result = $$.pointer;
      $$.code = qu_concatenate($2.code, n);
    } else {
      fprintf(stderr, "Syntax error: Unary minus is possible only if the operand has integer type!\n");
      exit(EXIT_FAILURE);
    }
  }
  | '(' expression ')' {
    $$.pointer = $2.pointer;
    $$.code = $2.code;
  }
  | ID {
    Symbol * symbol = NULL;

    if((symbol = sy_lookup(table, $1)) != NULL) {
      $$.pointer = symbol;
    } else {
      fprintf(stderr, "Syntax error: %s is undeclared!\n", $1);
      exit(EXIT_FAILURE);
    }

    $$.code = NULL;
  }
  | NUMBER {
    Value * value = va_alloc();

    value->integer = $1;
    table = sy_add_temporary(table, true, TYPE_INTEGER, value);
    $$.pointer = table;
    $$.code = NULL;
  }
  | ID rtab {}
  | ID '$' ID rtab {} /* ID correspond à un stencil ! */
  | ID rtab '$' ID {}
  ;

rtab:
	rtab '[' NUMBER ']' {}
	| '[' NUMBER ']' {}
	;
%%
