#include "ast.h"

const char * operator_to_string(Operator operator) {
  switch(operator) {
    case UO_MINUS:
    case BO_DIFFERENCE:
      return "-";
    case UO_NOT:
      return "!";
    case UO_PLUSPLUS:
      return "++";
    case UO_MINUSMINUS:
      return "--";
    case BO_ASSIGNMENT:
      return "=";
    case BO_SUM:
      return "+";
    case BO_MULTIPLICATION:
      return "*";
    case BO_DIVISION:
      return "/";
    case BO_STENCIL:
      return "$";
    case BO_AND:
      return "&&";
    case BO_OR:
      return "||";
    case BO_LESS:
      return "<";
    case BO_LESS_OR_EQUAL:
      return "<=";
    case BO_GREATER_OR_EQUAL:
      return ">=";
    case BO_GREATER:
      return ">";
    case BO_EQUAL:
      return "==";
    default: // Unsupported operator detected
      return NULL;
  }
}

ASTNode * ast_node_alloc(ASTType type) {
  ASTNode * node = (ASTNode *) malloc(sizeof(ASTNode));

  if(!node) {
    goto memerr;
  }
  
  switch(type) {
    case NODE_DECLARATION_LIST:
      if(!(node->declaration_list = (ASTDeclarationList *) malloc(sizeof(ASTDeclarationList)))) {
        goto memerr;
      }
      break;
    case NODE_ARRAY_ACCESS:
      if(!(node->access = (ASTArrayAccess *) malloc(sizeof(ASTArrayAccess)))) {
        goto memerr;
      }
      break;
    case NODE_UNARY:
      if(!(node->unary = (ASTUnary *) malloc(sizeof(ASTUnary)))) {
        goto memerr;
      }
      break;
    case NODE_BINARY:
      if(!(node->binary = (ASTBinary *) malloc(sizeof(ASTBinary)))) {
        goto memerr;
      }
      break;
    case NODE_IF:
      if(!(node->if_conditional = (ASTIf *) malloc(sizeof(ASTIf)))) {
        goto memerr;
      }
      break;
    case NODE_WHILE:
      if(!(node->while_loop = (ASTWhile *) malloc(sizeof(ASTWhile)))) {
        goto memerr;
      }
      break;
    case NODE_FOR:
      if(!(node->for_loop = (ASTFor *) malloc(sizeof(ASTFor)))) {
        goto memerr;
      }
      break;
    case NODE_FUNCTION_DECLARATION:
      if(!(node->function_declaration = (ASTFunctionDeclaration *) malloc(sizeof(ASTFunctionDeclaration)))) {
        goto memerr;
      }
      break;
    case NODE_FUNCTION_CALL:
      if(!(node->function_call = (ASTFunctionCall *) malloc(sizeof(ASTFunctionCall)))) {
        goto memerr;
      }
      break;
    case NODE_SCOPE:
      if(!(node->scope = (ASTScope *) malloc(sizeof(ASTScope)))) {
        goto memerr;
      }
      break;
    case NODE_SYMBOL_DECLARATION:
    case NODE_SYMBOL: // Identifiers are allocated in the table of symbols using associated functions.
    default: // Unknown AST node type detected
      return node;
  }

memerr:
  errno = ENOMEM;
  return NULL;
}

void ast_node_free(ASTNode * node) {
  if(!node) { // Node has already been freed or has never been allocated
    return;
  }

  switch(node->type) {
    case NODE_DECLARATION_LIST:
      for(size_t i = 0; i < node->declaration_list->count; i++) {
        ast_node_free(node->declaration_list->declarations[i]);
      }
      free(node->declaration_list->declarations);
      break;
    case NODE_ARRAY_ACCESS:
      for(size_t i = 0; i < node->access->count; i++) {
        ast_node_free(node->access->accessors[i]);
      }
      free(node->access->accessors);
      break;
    case NODE_UNARY:
      ast_node_free(node->unary->expression);
      free(node->unary);
      break;
    case NODE_BINARY:
      ast_node_free(node->binary->LHS);
      ast_node_free(node->binary->RHS);
      free(node->binary);
      break;
    case NODE_IF:
      ast_node_free(node->if_conditional->condition);
      ast_node_free(node->if_conditional->onif);
      ast_node_free(node->if_conditional->onelse);
      free(node->if_conditional);
      break;
    case NODE_WHILE:
      ast_node_free(node->while_loop->condition);
      ast_node_free(node->while_loop->statements);
      free(node->while_loop);
      break;
    case NODE_FOR:
      ast_node_free(node->for_loop->initialization);
      ast_node_free(node->for_loop->condition);
      ast_node_free(node->for_loop->incrementation);
      ast_node_free(node->for_loop->statements);
      free(node->for_loop);
      break;
    case NODE_FUNCTION_DECLARATION:
      ast_node_free(node->function_declaration->body);
      free(node->function_declaration->args);
      free(node->function_declaration);
      break;
    case NODE_FUNCTION_CALL:
      for(size_t i = 0; i < node->function_call->function->argc; i++) {
        ast_node_free(node->function_call->argv[i]);
      }      
      free(node->function_call);
      break;
    case NODE_SCOPE:
      for(size_t i = 0; i < node->scope->count; i++) {
        ast_node_free(node->scope->statements[i]);
      }
      free(node->scope->statements);
      free(node->scope);
      break;
    case NODE_SYMBOL_DECLARATION:
    case NODE_SYMBOL: // Identifiers are freed using functions associated to the table of symbols.
    default: // Unknown AST node type detected
      return;
  }

  free(node);
}

void ast_dump_and_indent(const ASTNode * node, size_t indent, const char * beginning) {
  if(!node) { // Stop when there are no more nodes to print.
    return;
  }

  if(indent > 0) {
    printf("│");
  }

  for(size_t i = 0; i < indent; i++) {
    printf("  "); // We indent using 2 spaces.
  }

  switch(node->type) {
    case NODE_DECLARATION_LIST:
      if(node->declaration_list->count > 0) {
        if(node->declaration_list->count > 1) {
          for(size_t i = 0; i < node->declaration_list->count - 1; i++) {
            ast_dump_and_indent(node->declaration_list->declarations[i], indent, "├─");
          }
        }
        ast_dump_and_indent(node->declaration_list->declarations[node->declaration_list->count - 1], indent, "└─");
      }
      break;
    case NODE_SYMBOL_DECLARATION:
    case NODE_SYMBOL:
      switch(node->symbol->value->type) {
        case VALUE_INTEGER:
          if(node->symbol->is_constant) {
            printf("%s integer constant <name: %s, value: %d>\n", beginning, node->symbol->identifier, node->symbol->value->integer);
          } else {
            printf("%s integer variable (%s) <name: %s>\n", beginning, node->type == NODE_SYMBOL ? "reference" : "declaration", node->symbol->identifier);
          }
          break;
        case VALUE_STRING:
          printf("%s string literal <name: %s, value: %s>\n", beginning, node->symbol->identifier, node->symbol->value->string);
          break;
        case VALUE_ARRAY:
          if(node->symbol->is_constant) {
            printf("%s integer array constant <name: %s, values: ", beginning, node->symbol->identifier);
            va_print(node->symbol->value);
            printf(">\n");
          } else {
            printf("%s integer array variable <name: %s>\n", beginning, node->symbol->identifier);
          }
          break;
        case VALUE_FUNCTION:
        case VALUE_LABEL:
        default:
          break;
      }
      break;
    case NODE_ARRAY_ACCESS:
      printf("%s Array access <%s>\n", beginning, node->access->array->identifier);

      size_t limit = node->access->count;
      if(node->access->array) {
        for(size_t i = 0; i < limit; i++) {
          ast_dump_and_indent(node->access->accessors[i], ++indent, (i < limit - 1 ? "├─" : "└─"));
        }
      }
      break;
    case NODE_UNARY:
      printf("%s Unary operator <%s>\n", beginning, operator_to_string(node->unary->operation));
      ast_dump_and_indent(node->unary->expression, ++indent, "└─");
      break;
    case NODE_BINARY:
      printf("%s Binary operator <%s>\n", beginning, operator_to_string(node->binary->operation));
      ast_dump_and_indent(node->binary->LHS, ++indent, "├─");
      ast_dump_and_indent(node->binary->RHS, ++indent, "└─");
      break;
    case NODE_IF:
      printf("%s IF conditional\n", beginning);
      ast_dump_and_indent(node->if_conditional->condition, ++indent, "├─");
      if(node->if_conditional->onelse) {
        ast_dump_and_indent(node->if_conditional->onif, ++indent, "├─");
        ast_dump_and_indent(node->if_conditional->onelse, ++indent, "└─");
      } else {
        ast_dump_and_indent(node->if_conditional->onif, ++indent, "└─");
      }
      break;
    case NODE_WHILE:
      printf("%s WHILE loop\n", beginning);
      ast_dump_and_indent(node->while_loop->condition, ++indent, "├─");
      ast_dump_and_indent(node->while_loop->statements, ++indent, "└─");
      break;
    case NODE_FOR:
      printf("%s FOR loop\n", beginning);
      ast_dump_and_indent(node->for_loop->initialization, ++indent, "├─");
      ast_dump_and_indent(node->for_loop->condition, ++indent, "├─");
      ast_dump_and_indent(node->for_loop->incrementation, ++indent, "├─");
      ast_dump_and_indent(node->for_loop->statements, ++indent, "└─");
      break;
    case NODE_FUNCTION_DECLARATION:
      printf("%s Function declaration <%s>", beginning, node->function_declaration->function->identifier);

      if(!node->function_declaration->returns) {
        printf(" [without return value]");
      } 
      
      if(!node->function_declaration->argc) {
        printf(" [without argument(s)]");
      }

      printf("\n");

      if(node->function_declaration->argc) {
        size_t i = 0;
        for(; i < node->function_declaration->argc - 1; i++) {
          ast_dump_and_indent(node->function_declaration->args[i], ++indent, "├─ Argument:");
        }
        ast_dump_and_indent(node->function_declaration->args[i], ++indent, node->function_declaration->returns ? "├─ Argument:" : "└─ Argument:");
      }

      if(node->function_declaration->returns) {
        ast_dump_and_indent(node->function_declaration->returns, ++indent, "└─ Returns:");
      }
      break;
    case NODE_FUNCTION_CALL:
      printf("%s Function call <%s>", beginning, node->function_call->function->function->identifier);

      if(node->function_call->function->argc) {
        size_t i = 0;
        for(; i < node->function_call->function->argc - 1; i++) {
          ast_dump_and_indent(node->function_call->argv[i], ++indent, "├─ Argument value:");
        }
        ast_dump_and_indent(node->function_call->argv[i], ++indent, "└─ Argument value:");
      }
      break;
    case NODE_SCOPE:
      printf("%s Scop <%s>\n", beginning, node->scope->name->identifier);
      for(size_t i = 0; i < node->scope->count; i++) {
        ast_dump_and_indent(node->scope->statements[i], ++indent, (i < node->scope->count - 1 ? "├─" : "└─"));
      }
      break;
    default: // Unknown AST node type detected
      return;
  }
}

void ast_dump(const ASTNode * node) {
  ast_dump_and_indent(node, 0, "──");
}

ASTFunctionDeclaration * ast_find_function_declaration(const ASTNode * tree, const Symbol * function) {
  if(!tree) {
    return NULL;
  }

  if(tree->type == NODE_FUNCTION_DECLARATION && sy_compare(tree->function_declaration->function, function)) {
    return tree->function_declaration;
  }

  if(tree->type == NODE_SCOPE) {
    ASTFunctionDeclaration * result = NULL;
    for(size_t i = 0; i < tree->scope->count; i++) {
      if((result = ast_find_function_declaration(tree->scope->statements[i], function))) {
        return result;
      }
    }
  }

  return NULL;
}