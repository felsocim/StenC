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
    case BO_GRATER_OR_EQUAL:
      return ">=";
    case BO_GREATER:
      return ">";
    case BO_EQUAL:
      return "==";
    default: // Unsupported operator detected
      return NULL;
  }
}

ASTNode * ast_new_node(ASTType type) {
  ASTNode * node = (ASTNode *) malloc(sizeof(ASTNode));

  if(!node) {
    goto memerr;
  }
  
  switch(type) {
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
    case NODE_IDENTIFIER: // Identifiers are allocated in the table of symbols using associated functions.
    default: // Unknown AST node type detected
      return NULL;
  }

  return node;

memerr:
  errno = ENOMEM;
  return NULL;
}

void ast_delete_node(ASTNode * node) {
  if(!node) { // Node has already been freed or has never been allocated
    return;
  }

  switch(node->type) {
    case NODE_ARRAY_ACCESS:
      if(node->access->array) {
        for(size_t i = 0; i < node->access->array->value->array.dimensions; i++) {
          ast_delete_node(node->access->accessors[i]);
        }
      }
      free(node->access->accessors);
      break;
    case NODE_UNARY:
      ast_delete_node(node->unary->expression);
      free(node->unary);
      break;
    case NODE_BINARY:
      ast_delete_node(node->binary->LHS);
      ast_delete_node(node->binary->RHS);
      free(node->binary);
      break;
    case NODE_IF:
      ast_delete_node(node->if_conditional->condition);
      ast_delete_node(node->if_conditional->onif);
      ast_delete_node(node->if_conditional->onelse);
      free(node->if_conditional);
      break;
    case NODE_WHILE:
      ast_delete_node(node->while_loop->condition);
      ast_delete_node(node->while_loop->statements);
      free(node->while_loop);
      break;
    case NODE_FOR:
      ast_delete_node(node->for_loop->initialization);
      ast_delete_node(node->for_loop->condition);
      ast_delete_node(node->for_loop->incrementation);
      ast_delete_node(node->for_loop->statements);
      free(node->for_loop);
      break;
    case NODE_FUNCTION_DECLARATION:
      ast_delete_node(node->function_declaration->body);
      free(node->function_declaration);
      break;
    case NODE_FUNCTION_CALL:
      ast_delete_node(node->function_call->argv);
      free(node->function_call);
      break;
    case NODE_SCOPE:
      ast_delete_node(node->scope->statements);
      free(node->scope);
      break;
    case NODE_IDENTIFIER: // Identifiers are freed using functions associated to the table of symbols.
    default: // Unknown AST node type detected
      return;
  }

  free(node);
}

void ast_dump_and_indent(const ASTNode * node, size_t indent, const char * beginning) {
  if(!node) { // Stop when there are no more nodes to print.
    return;
  }

  for(size_t i = 0; i < indent; i++) {
    printf("  "); // We indent using 2 spaces.
  }

  switch(node->type) {
    case NODE_IDENTIFIER:
      // TODO
      break;
    case NODE_ARRAY_ACCESS:
      printf("%s Array access <%s>\n", beginning, node->access->array->identifier);

      size_t limit = node->access->array->value->array.dimensions;
      if(node->access->array) {
        for(size_t i = 0; i < limit; i++) {
          ast_dump_and_indent(node->access->accessors[i], ++indent, (i < limit - 1 ? "├─ " : "└─ "));
        }
      }
      break;
    case NODE_UNARY:
      printf("%s Unary operator <%s>\n", beginning, operator_to_string(node->unary->operation));
      ast_dump_and_indent(node->unary->expression, ++indent, "└─ ");
      break;
    case NODE_BINARY:
      printf("%s Binary operator <%s>\n", beginning, operator_to_string(node->binary->operation));
      ast_dump_and_indent(node->binary->LHS, ++indent, "├─ ");
      ast_dump_and_indent(node->binary->RHS, ++indent, "└─ ");
      break;
    case NODE_IF:
      printf("%s IF conditional\n", beginning);
      ast_dump_and_indent(node->if_conditional->condition, ++indent, "├─ ");
      if(node->if_conditional->onelse) {
        ast_dump_and_indent(node->if_conditional->onif, ++indent, "├─ ");
        ast_dump_and_indent(node->if_conditional->onelse, ++indent, "└─ ");
      } else {
        ast_dump_and_indent(node->if_conditional->onif, ++indent, "└─ ");
      }
      break;
    case NODE_WHILE:
      printf("%s WHILE loop\n", beginning);
      ast_dump_and_indent(node->while_loop->condition, ++indent, "├─ ");
      ast_dump_and_indent(node->while_loop->statements, ++indent, "└─ ");
      break;
    case NODE_FOR:
      printf("%s FOR loop\n", beginning);
      ast_dump_and_indent(node->for_loop->initialization, ++indent, "├─ ");
      ast_dump_and_indent(node->for_loop->condition, ++indent, "├─ ");
      ast_dump_and_indent(node->for_loop->incrementation, ++indent, "├─ ");
      ast_dump_and_indent(node->for_loop->statements, ++indent, "└─ ");
      break;
    case NODE_FUNCTION_DECLARATION:
      // TODO
      break;
    case NODE_FUNCTION_CALL:
      // TODO
      break;
    case NODE_SCOPE:
      printf("%s Scop <%s>\n", beginning, node->scope->name->identifier);
      for(size_t i = 0; i < node->scope->count; i++) {
        ast_dump_and_indent(node->scope->statements[i], ++indent, (i < node->scope->count - 1 ? "├─ " : "└─ "));
      }
      break;
    default: // Unknown AST node type detected
      return;
  }
}

void ast_dump(const ASTNode * node) {
  ast_dump_and_indent(node, 0, "──");
}