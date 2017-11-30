%{
  #include "../include/main.h"

  int yylex();
  void yyerror(char*);
%}

%union{
  int value;
  char * name;
  struct {
    Symbol * pointer;
    Quad * code;
  } symbol;
}
%define parse.error verbose
%token INT TAB MAIN PRINT END IF ELSE WHILE
%token <value> NUMBER
%token <value> OPBOOL
%token <name> ID
%type <symbol> list statement variable declaration assignment expression
%left '+' '-'
%left '*' '/'
%left UMINUS
%left '('
%left OPBOOL
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
	bool
	| exprBool '&' bool
	| exprBool '|' bool 
	;

bool:
	expression OPBOOL expression
	| ID
	| NUMBER
	;

statement:
  INT variable {
      $$.code = $2.code;
    }
  | assignment {
      $$.code = $1.code;
    }
  | PRINT '(' expression ')' {
    Quad * n = qu_generate();

    switch($3.pointer->type) {
      case ST_INTEGER_VALUE:
        n->op = OP_CALL_PRINT;
        n->arg1 = $3.pointer;
        $$.code = qu_concatenate($3.code, n);


        break;
      default:
        break;
    }
  }
  //| IF
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
      $$.code = NULL;
    }
  ;

assignment:
  ID '=' expression {
      Symbol * symbol = NULL;
      Quad * n = qu_generate();

      switch($3.pointer->type) {
        case ST_INTEGER_VALUE:
          if((symbol = sy_lookup(table, $1)) == NULL) {
            SymbolValue value;
            value.integer = $3.pointer->value.integer;
            table = sy_add_variable(table, $1, false, ST_INTEGER_VALUE, value);
            $$.pointer = table;
          } else {
            $$.pointer = symbol;
          }



          n->op = OP_ASSIGN;
          n->arg1 = $3.pointer;
          n->result = $$.pointer;
          $$.code = qu_concatenate($3.code, n);

          break;
        default:
          break;
      }
    }
  ;

expression :
  expression '+' expression {
      SymbolValue value;
      Quad * n = qu_generate();
      switch($1.pointer->type) {
        case ST_INTEGER_VALUE:
          value.integer = $1.pointer->value.integer + $3.pointer->value.integer;
          table = sy_add_temporary(table, ST_INTEGER_VALUE, value);
          $$.pointer = table;
          n->op = OP_ADD;
          n->arg1 = $1.pointer;
          n->arg2 = $3.pointer;
          n->result = $$.pointer;
          $$.code = qu_concatenate($1.code, $3.code);
          $$.code = qu_concatenate($$.code, n);


          break;
        default:
          break;
      }
    }
  | expression '-' expression {
      SymbolValue value;
      Quad * n = qu_generate();
      switch($1.pointer->type) {
        case ST_INTEGER_VALUE:
          value.integer = $1.pointer->value.integer - $3.pointer->value.integer;
          table = sy_add_temporary(table, ST_INTEGER_VALUE, value);
          $$.pointer = table;
          n->op = OP_SUBTRACT;
          n->arg1 = $1.pointer;
          n->arg2 = $3.pointer;
          n->result = $$.pointer;
          $$.code = qu_concatenate($1.code, $3.code);
          $$.code = qu_concatenate($$.code, n);

          break;
        default:
          break;
      }
    }
  | expression '*' expression {
      SymbolValue value;
      Quad * n = qu_generate();
      switch($1.pointer->type) {
        case ST_INTEGER_VALUE:
          value.integer = $1.pointer->value.integer * $3.pointer->value.integer;
          table = sy_add_temporary(table, ST_INTEGER_VALUE, value);
          $$.pointer = table;
          n->op = OP_MULTIPLY;
          n->arg1 = $1.pointer;
          n->arg2 = $3.pointer;
          n->result = $$.pointer;
          $$.code = qu_concatenate($1.code, $3.code);
          $$.code = qu_concatenate($$.code, n);
          break;
        default:
          break;
      }
    }
  | expression '/' expression {
      SymbolValue value;
      Quad * n = qu_generate();
      switch($1.pointer->type) {
        case ST_INTEGER_VALUE:
          value.integer = $1.pointer->value.integer / $3.pointer->value.integer;
          table = sy_add_temporary(table, ST_INTEGER_VALUE, value);
          $$.pointer = table;
          n->op = OP_DIVIDE;
          n->arg1 = $1.pointer;
          n->arg2 = $3.pointer;
          n->result = $$.pointer;
          $$.code = qu_concatenate($1.code, $3.code);
          $$.code = qu_concatenate($$.code, n);
          break;
        default:
          break;
      }
    }
  | '-' expression %prec UMINUS {
      SymbolValue value;
      Quad * n = qu_generate();
      switch($2.pointer->type) {
        case ST_INTEGER_VALUE:
          value.integer = -$2.pointer->value.integer;
          table = sy_add_temporary(table, ST_INTEGER_VALUE, value);
          $$.pointer = table;
          n->op = OP_UMINUS;
          n->arg1 = $2.pointer;
          n->result = $$.pointer;
          $$.code = qu_concatenate($2.code, n);
          break;
        default:
          break;
      }
    }
  | '(' expression ')' {
      $$.pointer = $2.pointer;
      $$.code = $2.code;
    }
  | ID {
      SymbolValue value;
      Symbol * symbol = NULL;

      if((symbol = sy_lookup(table, yylval.name)) == NULL) {
        table = sy_add_variable(table, yylval.name, false, ST_INTEGER_VALUE, value);
        $$.pointer = table;
      } else {
        $$.pointer = symbol;
      }

      $$.code = NULL;

      printf("ID(%s)\n", yylval.name);
    }
  | NUMBER {
      SymbolValue value;

      value.integer = yylval.value;
      table = sy_add_temporary(table, ST_INTEGER_VALUE, value);
      $$.pointer = table;
      $$.code = NULL;

      printf("NUMBER(%d)\n", yylval.value);
    }
  ;

%%
