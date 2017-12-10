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
    size_t dimensions;
    SList * sizes;
    bool instantiable;
  } array;
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
%type <array> rtab
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
    $$.pointer = $1.pointer;
    $$.code = $1.code;
  }
  | ID {
    if(sy_lookup(table, $1) == NULL) {
      table = sy_add_variable(table, $1, false, TYPE_INTEGER, NULL);
      $$.pointer = table;
    } else {
      fprintf(stderr, "Syntax error: Identifier %s has already been declared in this scope!\n", $1);
      exit(EXIT_FAILURE);
    }

    $$.code = NULL;
  }
  | ID rtab {
    if(!$2.instantiable) {
      fprintf(stderr, "Syntax error: Static array cannot be declared using with a variable!\n");
      exit(EXIT_FAILURE);
    }

    Value * v = va_alloc();
    size_t i = 0, size = 0;

    v->array.dimensions = $2.dimensions;
    v->array.sizes = (size_t *) malloc(v->array.dimensions * sizeof(size_t));

    if(v->array.sizes == NULL)
      failwith("Failed to reserve memory for array value sizes");

    for(i = 0; i < v->array.dimensions; i++) {
      v->array.sizes[i] = $2.sizes->values[i]->value->integer;
      size *= v->array.sizes[i];
    }

    v->array.values = (int *) malloc(size * sizeof(int));

    if(v->array.values == NULL)
      failwith("Failed to reserve memory for array values");

    if(sy_lookup(table, $1) == NULL) {
      table = sy_add_variable(table, $1, false, TYPE_ARRAY, v);
      $$.pointer = table;
    } else {
      fprintf(stderr, "Syntax error: Identifier %s has already been declared in this scope!\n", $1);
      exit(EXIT_FAILURE);
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
  | ID rtab '=' listInit {
    if(!$2.instantiable) {
      fprintf(stderr, "Syntax error: Static array cannot be declared using with a variable!\n");
      exit(EXIT_FAILURE);
    }

    Value * v = va_alloc();
    size_t i = 0, size = 0;

    v->array.dimensions = $2.dimensions;
    v->array.sizes = (size_t *) malloc(v->array.dimensions * sizeof(size_t));

    if(v->array.sizes == NULL)
      failwith("Failed to reserve memory for array value sizes");

    for(i = 0; i < v->array.dimensions; i++) {
      v->array.sizes[i] = $2.sizes->values[i]->value->integer;
      size *= v->array.sizes[i];
    }

    v->array.values = (int *) malloc(size * sizeof(int));

    if(v->array.values == NULL)
      failwith("Failed to reserve memory for array values");

    size_t j = 0, c = 0;
    size_t * iterator = (size_t *) calloc($2.dimensions, sizeof(size_t)),
      * sizes = sltost($2.sizes);

    if(iterator == NULL)
      failwith("Failed to reserve memory for array iterator");

    Value * v0 = va_alloc(),
      * v1 = va_alloc(),
      * bytes = va_alloc();
    Symbol * symbol = NULL,
      * sy_zero = NULL,
      * sy_one = NULL,
      * sy_bytes = NULL;

    if((symbol = sy_lookup(table, $1)) == NULL) {
      table = sy_add_variable(table, $1, false, TYPE_ARRAY, v);
      $$.pointer = table;
    } else {
      $$.pointer = symbol;
    }

    v0->integer = 0;
    v1->integer = 1;
    bytes->integer = (int) sizeof(int);

    table = sy_add_temporary(table, true, TYPE_INTEGER, v0);
    sy_zero = table;

    table = sy_add_temporary(table, true, TYPE_INTEGER, v1);
    sy_one = table;

    table = sy_add_temporary(table, true, TYPE_INTEGER, bytes);
    sy_bytes = table;

    $$.code = NULL;

    do {
      Value * iv = va_alloc();
      Symbol * init_value = NULL,
        * shift = NULL,
        * temp = NULL,
        * of_temp = NULL,
        * offset = NULL;
      Quad * init_shift = qu_generate(),
        * init_temp = qu_generate(),
        * get_offset_mult = qu_generate(),
        * get_offset_assign = qu_generate(),
        * get_item = qu_generate();

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      shift = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      temp = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      of_temp = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      offset = table;

      init_shift->op = OP_ASSIGN;
      init_shift->arg1 = sy_zero;
      init_shift->result = shift;

      init_temp->op = OP_ASSIGN;
      init_temp->arg1 = sy_one;
      init_temp->result = temp;

      $$.code = qu_concatenate($$.code, init_shift);
      $$.code = qu_concatenate($$.code, init_temp);

      for(i = 0; i < $2.dimensions; i++) {
        for(j = i + 1; j < $2.dimensions; j++) {
          Value * current = va_alloc();
          Symbol * inner_temp = NULL,
            * current_size = NULL;
          Quad * inner_mult = qu_generate(),
            * inner_assign = qu_generate();

          table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
          inner_temp = table;

          current->integer = (int) sizes[j];

          table = sy_add_temporary(table, true, TYPE_INTEGER, current);
          current_size = table;

          inner_mult->op = OP_MULTIPLY;
          inner_mult->arg1 = temp;
          inner_mult->arg2 = current_size;
          inner_mult->result = inner_temp;

          inner_assign->op = OP_ASSIGN;
          inner_assign->arg1 = inner_temp;
          inner_assign->result = temp;

          $$.code = qu_concatenate($$.code, inner_mult);
          $$.code = qu_concatenate($$.code, inner_assign);
        }

        Value * iterator_value = va_alloc();
        Symbol * outer_temp1 = NULL,
          * outer_temp2 = NULL,
          * outer_temp3 = NULL;
        Quad * outer_mult = qu_generate(),
          * outer_add = qu_generate(),
          * outer_assign = qu_generate(),
          * temp_reset = qu_generate();

        table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
        outer_temp1 = table;

        table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
        outer_temp2 = table;

        iterator_value->integer = (int) iterator[i];

        table = sy_add_temporary(table, true, TYPE_INTEGER, iterator_value);
        outer_temp3 = table;

        outer_mult->op = OP_MULTIPLY;
        outer_mult->arg1 = outer_temp3;
        outer_mult->arg2 = temp;
        outer_mult->result = outer_temp1;

        outer_add->op = OP_ADD;
        outer_add->arg1 = shift;
        outer_add->arg2 = outer_temp1;
        outer_add->result = outer_temp2;

        outer_assign->op = OP_ASSIGN;
        outer_assign->arg1 = outer_temp2;
        outer_assign->result = shift;

        temp_reset->op = OP_ASSIGN;
        temp_reset->arg1 = sy_one;
        temp_reset->result = temp;

        $$.code = qu_concatenate($$.code, outer_mult);
        $$.code = qu_concatenate($$.code, outer_add);
        $$.code = qu_concatenate($$.code, outer_assign);
        $$.code = qu_concatenate($$.code, temp_reset);
      }

      get_offset_mult->op = OP_MULTIPLY;
      get_offset_mult->arg1 = shift;
      get_offset_mult->arg2 = sy_bytes;
      get_offset_mult->result = of_temp;

      get_offset_assign->op = OP_ASSIGN;
      get_offset_assign->arg1 = of_temp;
      get_offset_assign->result = offset;

      iv->integer = (int) intListGet($4, c);

      table = sy_add_temporary(table, true, TYPE_INTEGER, iv);
      init_value = table;

      get_item->op = OP_ASSIGN;
      get_item->arg1 = init_value;
      get_item->arg2 = offset;
      get_item->result = $$.pointer;

      $$.code = qu_concatenate($$.code, get_offset_mult);
      $$.code = qu_concatenate($$.code, get_offset_assign);
      $$.code = qu_concatenate($$.code, get_item);

      c++;
    } while(va_array_forward(iterator, sizes, $2.dimensions)); // Add test on c
  }
  | ID rtab '=' expression {
    size_t i = 0, j = 0;
    Value * v0 = va_alloc(),
      * v1 = va_alloc(),
      * bytes = va_alloc();
    Symbol * symbol = NULL,
      * sy_zero = NULL,
      * sy_one = NULL,
      * sy_bytes = NULL,
      * shift = NULL,
      * temp = NULL,
      * of_temp = NULL,
      * offset = NULL;
    Quad * init_shift = qu_generate(),
      * init_temp = qu_generate(),
      * get_offset_mult = qu_generate(),
      * get_offset_assign = qu_generate(),
      * get_item = qu_generate();

    if((symbol = sy_lookup(table, $1)) == NULL) {
      table = sy_add_variable(table, $1, false, TYPE_ARRAY, NULL);
      $$.pointer = table;
    } else {
      $$.pointer = symbol;
    }

    v0->integer = 0;
    v1->integer = 1;
    bytes->integer = (int) sizeof(int);

    table = sy_add_temporary(table, true, TYPE_INTEGER, v0);
    sy_zero = table;

    table = sy_add_temporary(table, true, TYPE_INTEGER, v1);
    sy_one = table;

    table = sy_add_temporary(table, true, TYPE_INTEGER, bytes);
    sy_bytes = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    shift = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    temp = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    of_temp = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    offset = table;

    init_shift->op = OP_ASSIGN;
    init_shift->arg1 = sy_zero;
    init_shift->result = shift;

    init_temp->op = OP_ASSIGN;
    init_temp->arg1 = sy_one;
    init_temp->result = temp;

    $$.code = $4.code;
    $$.code = qu_concatenate($$.code, init_shift);
    $$.code = qu_concatenate($$.code, init_temp);

    for(i = 0; i < $2.dimensions; i++) {
      for(j = i + 1; j < $2.dimensions; j++) {
        Value * current = va_alloc();
        Symbol * inner_temp = NULL,
          * current_size = NULL;
        Quad * inner_mult = qu_generate(),
          * inner_assign = qu_generate();

        table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
        inner_temp = table;

        current->integer = $$.pointer->value->array.sizes[j];

        table = sy_add_temporary(table, true, TYPE_INTEGER, current);
        current_size = table;

        inner_mult->op = OP_MULTIPLY;
        inner_mult->arg1 = temp;
        inner_mult->arg2 = current_size;
        inner_mult->result = inner_temp;

        inner_assign->op = OP_ASSIGN;
        inner_assign->arg1 = inner_temp;
        inner_assign->result = temp;

        $$.code = qu_concatenate($$.code, inner_mult);
        $$.code = qu_concatenate($$.code, inner_assign);
      }

      Symbol * outer_temp1 = NULL, * outer_temp2 = NULL;
      Quad * outer_mult = qu_generate(),
        * outer_add = qu_generate(),
        * outer_assign = qu_generate(),
        * temp_reset = qu_generate();

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      outer_temp1 = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      outer_temp2 = table;

      outer_mult->op = OP_MULTIPLY;
      outer_mult->arg1 = $2.sizes->values[i];
      outer_mult->arg2 = temp;
      outer_mult->result = outer_temp1;

      outer_add->op = OP_ADD;
      outer_add->arg1 = shift;
      outer_add->arg2 = outer_temp1;
      outer_add->result = outer_temp2;

      outer_assign->op = OP_ASSIGN;
      outer_assign->arg1 = outer_temp2;
      outer_assign->result = shift;

      temp_reset->op = OP_ASSIGN;
      temp_reset->arg1 = sy_one;
      temp_reset->result = temp;

      $$.code = qu_concatenate($$.code, outer_mult);
      $$.code = qu_concatenate($$.code, outer_add);
      $$.code = qu_concatenate($$.code, outer_assign);
      $$.code = qu_concatenate($$.code, temp_reset);
    }

    get_offset_mult->op = OP_MULTIPLY;
    get_offset_mult->arg1 = shift;
    get_offset_mult->arg2 = sy_bytes;
    get_offset_mult->result = of_temp;

    get_offset_assign->op = OP_ASSIGN;
    get_offset_assign->arg1 = of_temp;
    get_offset_assign->result = offset;

    get_item->op = OP_ASSIGN;
    get_item->arg1 = $4.pointer;
    get_item->arg2 = offset;
    get_item->result = $$.pointer;

    $$.code = qu_concatenate($$.code, get_offset_mult);
    $$.code = qu_concatenate($$.code, get_offset_assign);
    $$.code = qu_concatenate($$.code, get_item);
  }
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
  | ID rtab {
    size_t i = 0, j = 0;
    Value * v0 = va_alloc(),
      * v1 = va_alloc(),
      * bytes = va_alloc();
    Symbol * symbol = NULL,
      * sy_zero = NULL,
      * sy_one = NULL,
      * sy_bytes = NULL,
      * shift = NULL,
      * temp = NULL,
      * of_temp = NULL,
      * offset = NULL,
      * item = NULL;
    Quad * init_shift = qu_generate(),
      * init_temp = qu_generate(),
      * get_offset_mult = qu_generate(),
      * get_offset_assign = qu_generate(),
      * get_item = qu_generate();

    if((symbol = sy_lookup(table, $1)) == NULL) {
      fprintf(stderr, "Syntax error: %s is undeclared!\n", $1);
      exit(EXIT_FAILURE);
    }

    v0->integer = 0;
    v1->integer = 1;
    bytes->integer = (int) sizeof(int);

    table = sy_add_temporary(table, true, TYPE_INTEGER, v0);
    sy_zero = table;

    table = sy_add_temporary(table, true, TYPE_INTEGER, v1);
    sy_one = table;

    table = sy_add_temporary(table, true, TYPE_INTEGER, bytes);
    sy_bytes = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    shift = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    temp = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    of_temp = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    offset = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    item = table;

    init_shift->op = OP_ASSIGN;
    init_shift->arg1 = sy_zero;
    init_shift->result = shift;

    init_temp->op = OP_ASSIGN;
    init_temp->arg1 = sy_one;
    init_temp->result = temp;

    $$.code = qu_concatenate(init_shift, init_temp);

    for(i = 0; i < $2.dimensions; i++) {
      for(j = i + 1; j < $2.dimensions; j++) {
        Value * current = va_alloc();
        Symbol * inner_temp = NULL,
          * current_size = NULL;
        Quad * inner_mult = qu_generate(),
          * inner_assign = qu_generate();

        table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
        inner_temp = table;

        current->integer = symbol->value->array.sizes[j];

        table = sy_add_temporary(table, true, TYPE_INTEGER, current);
        current_size = table;

        inner_mult->op = OP_MULTIPLY;
        inner_mult->arg1 = temp;
        inner_mult->arg2 = current_size;
        inner_mult->result = inner_temp;

        inner_assign->op = OP_ASSIGN;
        inner_assign->arg1 = inner_temp;
        inner_assign->result = temp;

        $$.code = qu_concatenate($$.code, inner_mult);
        $$.code = qu_concatenate($$.code, inner_assign);
      }

      Symbol * outer_temp1 = NULL, * outer_temp2 = NULL;
      Quad * outer_mult = qu_generate(),
        * outer_add = qu_generate(),
        * outer_assign = qu_generate(),
        * temp_reset = qu_generate();

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      outer_temp1 = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      outer_temp2 = table;

      outer_mult->op = OP_MULTIPLY;
      outer_mult->arg1 = $2.sizes->values[i];
      outer_mult->arg2 = temp;
      outer_mult->result = outer_temp1;

      outer_add->op = OP_ADD;
      outer_add->arg1 = shift;
      outer_add->arg2 = outer_temp1;
      outer_add->result = outer_temp2;

      outer_assign->op = OP_ASSIGN;
      outer_assign->arg1 = outer_temp2;
      outer_assign->result = shift;

      temp_reset->op = OP_ASSIGN;
      temp_reset->arg1 = sy_one;
      temp_reset->result = temp;

      $$.code = qu_concatenate($$.code, outer_mult);
      $$.code = qu_concatenate($$.code, outer_add);
      $$.code = qu_concatenate($$.code, outer_assign);
      $$.code = qu_concatenate($$.code, temp_reset);
    }

    get_offset_mult->op = OP_MULTIPLY;
    get_offset_mult->arg1 = shift;
    get_offset_mult->arg2 = sy_bytes;
    get_offset_mult->result = of_temp;

    get_offset_assign->op = OP_ASSIGN;
    get_offset_assign->arg1 = of_temp;
    get_offset_assign->result = offset;

    get_item->op = OP_ASSIGN_ARRAY_VALUE;
    get_item->arg1 = symbol;
    get_item->arg2 = offset;
    get_item->result = item;

    $$.code = qu_concatenate($$.code, get_offset_mult);
    $$.code = qu_concatenate($$.code, get_offset_assign);
    $$.code = qu_concatenate($$.code, get_item);

    $$.pointer = item;
  }
  | ID '$' ID rtab {
    int i = 0, j = 0; size_t neighbors = 0, dimensions = $4.dimensions;

    Value * v0 = va_alloc(),
      * v1 = va_alloc(),
      * bytes = va_alloc(),
      * vn = va_alloc();
    Symbol * stencil = NULL,
      * array = NULL,
      * sy_zero = NULL,
      * sy_one = NULL,
      * sy_bytes = NULL,
      * result = NULL,
      * sy_neighbors = NULL;

    if((stencil = sy_lookup(table, $1)) == NULL) {
      fprintf(stderr, "Syntax error: %s is undeclared!\n", $1);
      exit(EXIT_FAILURE);
    }

    if((array = sy_lookup(table, $3)) == NULL) {
      fprintf(stderr, "Syntax error: %s is undeclared!\n", $3);
      exit(EXIT_FAILURE);
    }

    if(stencil->value->array.dimensions != array->value->array.dimensions)
      failwith("Sytax error: Stencil and array must have the same number of dimensions");

    neighbors = (stencil->value->array.sizes[0] - 1) / 2;

    printf("Neighbors -- %lu\n", neighbors);

    v0->integer = 0;
    v1->integer = 1;
    bytes->integer = (int) sizeof(int);

    table = sy_add_temporary(table, true, TYPE_INTEGER, v0);
    sy_zero = table;

    table = sy_add_temporary(table, true, TYPE_INTEGER, v1);
    sy_one = table;

    table = sy_add_temporary(table, true, TYPE_INTEGER, bytes);
    sy_bytes = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    result = table;

    vn->integer = (int) neighbors;

    table = sy_add_temporary(table, true, TYPE_INTEGER, vn);
    sy_neighbors = table;

    $$.code = NULL;

    SList * sc_labels = sl_init(SL_GROW_SIZE), * f_labels = sl_init(SL_GROW_SIZE), * is = sl_init(SL_GROW_SIZE);

    for(i = 0; i < dimensions; i++) {
      Value * size = va_alloc();
      Symbol * label = NULL,
        * iterator = NULL,
        * ith_size = NULL,
        * ontrue = NULL,
        * onfalse = NULL;
      Quad * init_label = qu_generate(),
        * label_ontrue = qu_generate(),
        * condition = qu_generate(),
        * j_false = qu_generate();

      table = sy_add_label(table, NULL);
      label = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, v0);
      iterator = table;

      is = sl_insert(is, iterator);
      sc_labels = sl_insert(sc_labels, label);

      size->integer = stencil->value->array.sizes[i];

      table = sy_add_temporary(table, true, TYPE_INTEGER, size);
      ith_size = table;

      table = sy_add_label(table, NULL);
      ontrue = table;

      table = sy_add_label(table, NULL);
      onfalse = table;

      f_labels = sl_insert(f_labels, onfalse);

      init_label->op = OP_LABEL;
      init_label->result = label;

      condition->op = OP_LT;
      condition->arg1 = iterator;
      condition->arg2 = ith_size;
      condition->result = ontrue;

      j_false->op = OP_GOTO;
      j_false->result = onfalse;

      label_ontrue->op = OP_LABEL;
      label_ontrue->result = ontrue;

      $$.code = qu_concatenate($$.code, init_label);
      $$.code = qu_concatenate($$.code, condition);
      $$.code = qu_concatenate($$.code, j_false);
      $$.code = qu_concatenate($$.code, label_ontrue);
    }

    Symbol * ar_shift = NULL,
      * st_shift = NULL,
      * ar_temp = NULL,
      * ar_of_temp = NULL,
      * st_temp = NULL,
      * st_of_temp = NULL,
      * ar_offset = NULL,
      * st_offset = NULL;
    Quad * init_ar_shift = qu_generate(),
      * init_st_shift = qu_generate(),
      * init_ar_temp = qu_generate(),
      * init_st_temp = qu_generate(),
      * get_ar_offset_mult = qu_generate(),
      * get_ar_offset_assign = qu_generate(),
      * get_st_offset_mult = qu_generate(),
      * get_st_offset_assign = qu_generate();

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    ar_shift = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    st_shift = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    ar_temp = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    ar_of_temp = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    st_temp = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    st_of_temp = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    ar_offset = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    st_offset = table;

    init_ar_shift->op = OP_ASSIGN;
    init_ar_shift->arg1 = sy_zero;
    init_ar_shift->result = ar_shift;

    init_st_shift->op = OP_ASSIGN;
    init_st_shift->arg1 = sy_zero;
    init_st_shift->result = st_shift;

    init_ar_temp->op = OP_ASSIGN;
    init_ar_temp->arg1 = sy_one;
    init_ar_temp->result = ar_temp;

    init_st_temp->op = OP_ASSIGN;
    init_st_temp->arg1 = sy_one;
    init_st_temp->result = st_temp;

    $$.code = qu_concatenate($$.code, init_ar_shift);
    $$.code = qu_concatenate($$.code, init_st_shift);
    $$.code = qu_concatenate($$.code, init_ar_temp);
    $$.code = qu_concatenate($$.code, init_st_temp);

    for(i = 0; i < $4.dimensions; i++) {
      for(j = i + 1; j < $4.dimensions; j++) {
        Value * ar_current = va_alloc(),
          * st_current = va_alloc();
        Symbol * ar_inner_temp = NULL,
          * ar_current_size = NULL,
          * st_inner_temp = NULL,
          * st_current_size = NULL;
        Quad * ar_inner_mult = qu_generate(),
          * ar_inner_assign = qu_generate(),
          * st_inner_mult = qu_generate(),
          * st_inner_assign = qu_generate();

        table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
        ar_inner_temp = table;

        table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
        st_inner_temp = table;

        ar_current->integer = (int) array->value->array.sizes[j];
        st_current->integer = (int) stencil->value->array.sizes[j];

        table = sy_add_temporary(table, true, TYPE_INTEGER, ar_current);
        ar_current_size = table;

        table = sy_add_temporary(table, true, TYPE_INTEGER, st_current);
        st_current_size = table;

        ar_inner_mult->op = OP_MULTIPLY;
        ar_inner_mult->arg1 = ar_temp;
        ar_inner_mult->arg2 = ar_current_size;
        ar_inner_mult->result = ar_inner_temp;

        ar_inner_assign->op = OP_ASSIGN;
        ar_inner_assign->arg1 = ar_inner_temp;
        ar_inner_assign->result = ar_temp;

        st_inner_mult->op = OP_MULTIPLY;
        st_inner_mult->arg1 = st_temp;
        st_inner_mult->arg2 = st_current_size;
        st_inner_mult->result = st_inner_temp;

        st_inner_assign->op = OP_ASSIGN;
        st_inner_assign->arg1 = st_inner_temp;
        st_inner_assign->result = st_temp;

        $$.code = qu_concatenate($$.code, ar_inner_mult);
        $$.code = qu_concatenate($$.code, ar_inner_assign);
        $$.code = qu_concatenate($$.code, st_inner_mult);
        $$.code = qu_concatenate($$.code, st_inner_assign);
      }

      Symbol * ar_outer_temp1 = NULL,
        * ar_outer_temp2 = NULL,
        * outer_temp3 = NULL,
        * outer_temp4 = NULL,
        * st_outer_temp1 = NULL,
        * st_outer_temp2 = NULL;
      Quad * outer_ar_mult = qu_generate(),
        * outer_ar_add = qu_generate(),
        * outer_ar_assign = qu_generate(),
        * ar_temp_reset = qu_generate(),
        * outer_st_mult = qu_generate(),
        * outer_st_add = qu_generate(),
        * outer_st_assign = qu_generate(),
        * st_temp_reset = qu_generate(),
        * outer_add_i = qu_generate(),
        * outer_sub_i = qu_generate();

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      ar_outer_temp1 = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      ar_outer_temp2 = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      st_outer_temp1 = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      st_outer_temp2 = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      outer_temp3 = table;

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      outer_temp4 = table;

      outer_add_i->op = OP_ADD;
      outer_add_i->arg1 = $4.sizes->values[i];
      outer_add_i->arg2 = is->values[i];
      outer_add_i->result = outer_temp3;

      outer_sub_i->op = OP_SUBTRACT;
      outer_sub_i->arg1 = outer_temp3;
      outer_sub_i->arg2 = sy_neighbors;
      outer_sub_i->result = outer_temp4;

      outer_ar_mult->op = OP_MULTIPLY;
      outer_ar_mult->arg1 = outer_temp4;
      outer_ar_mult->arg2 = ar_temp;
      outer_ar_mult->result = ar_outer_temp1;

      outer_ar_add->op = OP_ADD;
      outer_ar_add->arg1 = ar_shift;
      outer_ar_add->arg2 = ar_outer_temp1;
      outer_ar_add->result = ar_outer_temp2;

      outer_ar_assign->op = OP_ASSIGN;
      outer_ar_assign->arg1 = ar_outer_temp2;
      outer_ar_assign->result = ar_shift;

      ar_temp_reset->op = OP_ASSIGN;
      ar_temp_reset->arg1 = sy_one;
      ar_temp_reset->result = ar_temp;

      outer_st_mult->op = OP_MULTIPLY;
      outer_st_mult->arg1 = is->values[i];
      outer_st_mult->arg2 = st_temp;
      outer_st_mult->result = st_outer_temp1;

      outer_st_add->op = OP_ADD;
      outer_st_add->arg1 = st_shift;
      outer_st_add->arg2 = st_outer_temp1;
      outer_st_add->result = st_outer_temp2;

      outer_st_assign->op = OP_ASSIGN;
      outer_st_assign->arg1 = st_outer_temp2;
      outer_st_assign->result = st_shift;

      st_temp_reset->op = OP_ASSIGN;
      st_temp_reset->arg1 = sy_one;
      st_temp_reset->result = st_temp;

      $$.code = qu_concatenate($$.code, outer_add_i);
      $$.code = qu_concatenate($$.code, outer_sub_i);
      $$.code = qu_concatenate($$.code, outer_ar_mult);
      $$.code = qu_concatenate($$.code, outer_ar_add);
      $$.code = qu_concatenate($$.code, outer_ar_assign);
      $$.code = qu_concatenate($$.code, ar_temp_reset);
      $$.code = qu_concatenate($$.code, outer_st_mult);
      $$.code = qu_concatenate($$.code, outer_st_add);
      $$.code = qu_concatenate($$.code, outer_st_assign);
      $$.code = qu_concatenate($$.code, st_temp_reset);
    }

    get_ar_offset_mult->op = OP_MULTIPLY;
    get_ar_offset_mult->arg1 = ar_shift;
    get_ar_offset_mult->arg2 = sy_bytes;
    get_ar_offset_mult->result = ar_of_temp;

    get_ar_offset_assign->op = OP_ASSIGN;
    get_ar_offset_assign->arg1 = ar_of_temp;
    get_ar_offset_assign->result = ar_offset;

    get_st_offset_mult->op = OP_MULTIPLY;
    get_st_offset_mult->arg1 = st_shift;
    get_st_offset_mult->arg2 = sy_bytes;
    get_st_offset_mult->result = st_of_temp;

    get_st_offset_assign->op = OP_ASSIGN;
    get_st_offset_assign->arg1 = st_of_temp;
    get_st_offset_assign->result = st_offset;

    Symbol * ar_item = NULL,
      * st_item = NULL,
      * final_temp1 = NULL,
      * final_temp2 = NULL;
    Quad * get_ar_item = qu_generate(), * get_st_item = qu_generate(), * multiply = qu_generate(), * add = qu_generate(), * assign = qu_generate();

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    ar_item = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    st_item = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    final_temp1 = table;

    table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
    final_temp2 = table;

    get_ar_item->op = OP_ASSIGN_ARRAY_VALUE;
    get_ar_item->arg1 = array;
    get_ar_item->arg2 = ar_offset;
    get_ar_item->result = ar_item;

    get_st_item->op = OP_ASSIGN_ARRAY_VALUE;
    get_st_item->arg1 = stencil;
    get_st_item->arg2 = st_offset;
    get_st_item->result = st_item;

    multiply->op = OP_MULTIPLY;
    multiply->arg1 = ar_item;
    multiply->arg2 = st_item;
    multiply->result = final_temp1;

    add->op = OP_ADD;
    add->arg1 = result;
    add->arg2 = final_temp1;
    add->result = final_temp2;

    assign->op = OP_ASSIGN;
    assign->arg1 = final_temp2;
    assign->result = result;

    $$.code = qu_concatenate($$.code, get_ar_offset_mult);
    $$.code = qu_concatenate($$.code, get_ar_offset_assign);

    $$.code = qu_concatenate($$.code, get_st_offset_mult);
    $$.code = qu_concatenate($$.code, get_st_offset_assign);


    $$.code = qu_concatenate($$.code, get_ar_item);
    $$.code = qu_concatenate($$.code, get_st_item);
    $$.code = qu_concatenate($$.code, multiply);
    $$.code = qu_concatenate($$.code, add);
    $$.code = qu_concatenate($$.code, assign);

    for(i = (dimensions - 1); i >= 0; i--) {
      Symbol * temp = NULL;
      Quad * return_to_init_label = qu_generate(),
        * goto_on_false = qu_generate(),
        * incr_iterator = qu_generate(),
        * assign_iterator = qu_generate();

      table = sy_add_temporary(table, false, TYPE_INTEGER, NULL);
      temp = table;

      printf("is size -- %lu\n", is->next);

      incr_iterator->op = OP_ADD;
      incr_iterator->arg1 = is->values[i];
      incr_iterator->arg2 = sy_one;
      incr_iterator->result = temp;

      assign_iterator->op = OP_ASSIGN;
      assign_iterator->arg1 = temp;
      assign_iterator->result = is->values[i];

      return_to_init_label->op = OP_GOTO;
      return_to_init_label->result = sc_labels->values[i];

      goto_on_false->op = OP_LABEL;
      goto_on_false->result = f_labels->values[i];

      $$.code = qu_concatenate($$.code, incr_iterator);
      $$.code = qu_concatenate($$.code, assign_iterator);
      $$.code = qu_concatenate($$.code, return_to_init_label);
      $$.code = qu_concatenate($$.code, goto_on_false);
    }

    $$.pointer = result;
  } /* ID correspond à un stencil ! */
  | ID rtab '$' ID {

  }
  ;

rtab:
	rtab '[' expression ']' {
    $$.dimensions = $1.dimensions + 1;
    $$.sizes = sl_insert($1.sizes, $3.pointer);

    if($1.instantiable && !$3.pointer->constant)
      $1.instantiable = false;
  }
	| '[' expression ']' {
    $$.dimensions = 1;
    $$.sizes = sl_init(SL_GROW_SIZE);
    $$.sizes = sl_insert($$.sizes, $2.pointer);

    $$.instantiable = $2.pointer->constant;
  }
	;
%%
