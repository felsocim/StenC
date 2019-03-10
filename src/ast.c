#include "ast.h"

GArray * indentation = NULL;

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
    case BO_NOTEQUAL:
      return "!=";
    case BO_EQUAL:
      return "==";
    default: // Unsupported operator detected
      return NULL;
  }
}

ASTNode * ast_node_alloc(ASTType type) {
  ASTNode * node = (ASTNode *) malloc(sizeof(ASTNode));

  if(!node) {
    return NULL;
  }
  
  switch(type) {
    case NODE_RETURN:
      if(!(node->return_statement = (ASTReturn *) malloc(sizeof(ASTReturn)))) {
        return NULL;
      }

      node->return_statement->returns = NULL;
    case NODE_DECLARATION_LIST:
      if(!(node->declaration_list = (ASTDeclarationList *) malloc(sizeof(ASTDeclarationList)))) {
        return NULL;
      }

      node->declaration_list->symbols = NULL;
      break;
    case NODE_ARRAY_ACCESS:
      if(!(node->access = (ASTArrayAccess *) malloc(sizeof(ASTArrayAccess)))) {
        return NULL;
      }

      node->access->array = NULL;
      node->access->accessors = NULL;
      break;
    case NODE_UNARY:
      if(!(node->unary = (ASTUnary *) malloc(sizeof(ASTUnary)))) {
        return NULL;
      }

      node->unary->expression = NULL;
      break;
    case NODE_BINARY:
      if(!(node->binary = (ASTBinary *) malloc(sizeof(ASTBinary)))) {
        return NULL;
      }

      node->binary->LHS = NULL;
      node->binary->RHS = NULL;
      break;
    case NODE_IF:
      if(!(node->if_conditional = (ASTIf *) malloc(sizeof(ASTIf)))) {
        return NULL;
      }

      node->if_conditional->condition = NULL;
      node->if_conditional->onif = NULL;
      node->if_conditional->onelse = NULL;
      break;
    case NODE_WHILE:
      if(!(node->while_loop = (ASTWhile *) malloc(sizeof(ASTWhile)))) {
        return NULL;
      }

      node->while_loop->condition = NULL;
      node->while_loop->statements = NULL;
      break;
    case NODE_FOR:
      if(!(node->for_loop = (ASTFor *) malloc(sizeof(ASTFor)))) {
        return NULL;
      }

      node->for_loop->initialization = NULL;
      node->for_loop->condition = NULL;
      node->for_loop->incrementation = NULL;
      node->for_loop->statements = NULL;
      break;
    case NODE_FUNCTION_DECLARATION:
      if(!(node->function_declaration = (ASTFunctionDeclaration *) malloc(sizeof(ASTFunctionDeclaration)))) {
        return NULL;
      }

      node->function_declaration->function = NULL;
      node->function_declaration->args = NULL;
      node->function_declaration->body = NULL;
      break;
    case NODE_FUNCTION_CALL:
      if(!(node->function_call = (ASTFunctionCall *) malloc(sizeof(ASTFunctionCall)))) {
        return NULL;
      }

      node->function_call->function = NULL;
      node->function_call->argv = NULL;
      break;
    case NODE_SCOPE:
      if(!(node->scope = (ASTScope *) malloc(sizeof(ASTScope)))) {
        return NULL;
      }

      node->scope->statements = NULL;
      break;
    case NODE_SYMBOL_DECLARATION:
    case NODE_SYMBOL: // Identifiers are allocated in the table of symbols using associated functions.
    default: // Unknown AST node type detected
      break;
  }

  node->type = type;

  return node;
}

void ast_node_free(ASTNode * node) {
  if(!node) { // Node has already been freed or has never been allocated
    return;
  }

  switch(node->type) {
    case NODE_RETURN:
      ast_node_free(node->return_statement->returns);
      break;
    case NODE_DECLARATION_LIST:
      for(guint i = 0; i < node->declaration_list->symbols->len; i++) {
        ast_node_free(g_ptr_array_index(node->declaration_list->symbols, i));
      }
      g_ptr_array_free(node->declaration_list->symbols, FALSE);
      break;
    case NODE_ARRAY_ACCESS:
      for(guint i = 0; i < node->access->accessors->len; i++) {
        ast_node_free(g_ptr_array_index(node->access->accessors, i));
      }
      g_ptr_array_free(node->access->accessors, FALSE);
      break;
    case NODE_UNARY:
      ast_node_free(node->unary->expression);
      break;
    case NODE_BINARY:
      ast_node_free(node->binary->LHS);
      ast_node_free(node->binary->RHS);
      break;
    case NODE_IF:
      ast_node_free(node->if_conditional->condition);
      ast_node_free(node->if_conditional->onif);
      ast_node_free(node->if_conditional->onelse);
      break;
    case NODE_WHILE:
      ast_node_free(node->while_loop->condition);
      ast_node_free(node->while_loop->statements);
      break;
    case NODE_FOR:
      ast_node_free(node->for_loop->initialization);
      ast_node_free(node->for_loop->condition);
      ast_node_free(node->for_loop->incrementation);
      ast_node_free(node->for_loop->statements);
      break;
    case NODE_FUNCTION_DECLARATION:
      ast_node_free(node->function_declaration->body);
      if(node->function_declaration->args) {
        for(guint i = 0; i < node->function_declaration->args->len; i++) {
          ast_node_free(g_ptr_array_index(node->function_declaration->args, i));
        }
        g_ptr_array_free(node->function_declaration->args, FALSE);
      }
      break;
    case NODE_FUNCTION_CALL:
      if(node->function_call->argv) {
        for(guint i = 0; i < node->function_call->argv->len; i++) {
          ast_node_free(g_ptr_array_index(node->function_call->argv, i));
        }   
        g_ptr_array_free(node->function_call->argv, FALSE);
      }
      break;
    case NODE_SCOPE:
      if(node->scope->statements) {
        for(guint i = 0; i < node->scope->statements->len; i++) {
          ast_node_free(g_ptr_array_index(node->scope->statements, i));
        }  
        g_ptr_array_free(node->scope->statements, FALSE);
      }
      break;
    case NODE_SYMBOL_DECLARATION:
    case NODE_SYMBOL: // Identifiers are freed using functions associated to the table of symbols.
    default: // Unknown AST node type detected
      return;
  }

  free(node);
}

void ast_dump_and_indent(const ASTNode * node, size_t indent, const char * beginning, bool expands, bool prepend, size_t to_prepend) {
  if(!node) { // Stop when there are no more nodes to print.
    return;
  }

  if(node->type != NODE_DECLARATION_LIST) {
    if(expands) {
      bool insert = true;
      for(guint j = 0; j < indentation->len; j++) {
        if(indent == g_array_index(indentation, size_t, j)) {
          insert = false;
        }
      }

      if(insert) {
        indentation = g_array_append_val(indentation, indent);
      }
    } else {
      bool removal = false;
      guint j = 0;
      for(; j < indentation->len; j++) {
        if(indent == g_array_index(indentation, size_t, j)) {
          removal = true;
          break;
        }
      }

      if(removal) {
        indentation = g_array_remove_index(indentation, j);
      }
    }

    for(size_t i = 0; i < indent; i++) {
      bool bar = false;
      for(size_t j = 0; j < indentation->len; j++) {
        if(i && i == g_array_index(indentation, size_t, j)) {
          bar = true;
          break;
        }
      }
      if(bar) {
        printf("│ ");
      } else {
        printf("  ");
      }
    }
  }

  switch(node->type) {
    case NODE_RETURN:
      switch(node->return_statement->type) {
        case RETURNS_INTEGER:
          printf("%s Return statement <returns %s>\n", beginning, "INTEGER");
          break;
        case RETURNS_VOID:
          printf("%s Return statement <returns %s>\n", beginning, "VOID");
          break;
        default:
          break;
      }

      ast_dump_and_indent(node->return_statement->returns, indent + 1, "└─", false, expands, to_prepend + 1);
      break;      
    case NODE_DECLARATION_LIST:
      for(guint i = 0; i < node->declaration_list->symbols->len; i++) {
        ast_dump_and_indent(g_ptr_array_index(node->declaration_list->symbols, i), indent, beginning, expands, false, to_prepend);
      }
      break;
    case NODE_SYMBOL_DECLARATION:
    case NODE_SYMBOL:
      switch(node->symbol->value->type) {
        case VALUE_INTEGER:
          if(node->symbol->is_constant) {
            printf("%s integer constant (%s) <name: %s, value: %d>\n", beginning, node->type == NODE_SYMBOL ? "reference" : "declaration", node->symbol->identifier, node->symbol->value->integer);
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
      for(guint i = 0; i < node->access->accessors->len; i++) {
        ast_dump_and_indent(g_ptr_array_index(node->access->accessors, i), indent + 1, (i < node->access->accessors->len - 1 ? "├─" : "└─"), i < node->access->accessors->len - 1, false, to_prepend + 1);
      }
      break;
    case NODE_UNARY:
      printf("%s Unary operator '%s'\n", beginning, operator_to_string(node->unary->operation));
      ast_dump_and_indent(node->unary->expression, indent + 1, "└─", false, expands, to_prepend + 1);
      break;
    case NODE_BINARY:
      printf("%s Binary operator '%s'\n", beginning, operator_to_string(node->binary->operation));
      ast_dump_and_indent(node->binary->LHS, indent + 1, "├─", true, expands, to_prepend + 1);
      ast_dump_and_indent(node->binary->RHS, indent + 1, "└─", false, expands, to_prepend + 1);
      break;
    case NODE_IF:
      printf("%s IF conditional\n", beginning);
      ast_dump_and_indent(node->if_conditional->condition, indent + 1, "├─ condition:", true, expands, to_prepend + 1);
      if(node->if_conditional->onelse) {
        ast_dump_and_indent(node->if_conditional->onif, indent + 1, "├─ on true:", true, expands, to_prepend + 1);
        ast_dump_and_indent(node->if_conditional->onelse, indent + 1, "└─ on false:", false, expands, to_prepend + 1);
      } else {
        ast_dump_and_indent(node->if_conditional->onif, indent + 1, "└─ on true:", false, expands, to_prepend + 1);
      }
      break;
    case NODE_WHILE:
      printf("%s WHILE loop\n", beginning);
      ast_dump_and_indent(node->while_loop->condition, indent + 1, "├─ condition:", true, expands, to_prepend + 1);
      ast_dump_and_indent(node->while_loop->statements, indent + 1, "└─ statement(s):", false, expands, to_prepend + 1);
      break;
    case NODE_FOR:
      printf("%s FOR loop\n", beginning);
      ast_dump_and_indent(node->for_loop->initialization, indent + 1, "├─ initialization:", true, expands, to_prepend + 1);
      ast_dump_and_indent(node->for_loop->condition, indent + 1, "├─ condition:", true, expands, to_prepend + 1);
      ast_dump_and_indent(node->for_loop->incrementation, indent + 1, "├─ increment:", true, expands, to_prepend + 1);
      ast_dump_and_indent(node->for_loop->statements, indent + 1, "└─ statement(s):", false, expands, to_prepend + 1);
      break;
    case NODE_FUNCTION_DECLARATION:
      printf("%s Function declaration <%s>", beginning, node->function_declaration->function->identifier);

      switch(node->function_declaration->returns) {
        case RETURNS_VOID:
          printf(" [without return value]");
          break;
        case RETURNS_INTEGER:
          printf(" [returns integer]");
          break;
        default:
          break;
      }
      
      if(!node->function_declaration->args) {
        printf(" [without argument(s)]");
      }

      printf("\n");

      if(node->function_declaration->args) {
        guint i = 0;
        for(; i < node->function_declaration->args->len - 1; i++) {
          ast_dump_and_indent(g_ptr_array_index(node->function_declaration->args, i), indent + 1, "├─ argument:", true, expands, to_prepend + 1);
        }
        ast_dump_and_indent(g_ptr_array_index(node->function_declaration->args, i), indent + 1, "├─ argument:", true, expands, to_prepend + 1);
      }
      ast_dump_and_indent(node->function_declaration->body, indent + 1, "└─ body:", false, expands, to_prepend + 1);
      break;
    case NODE_FUNCTION_CALL:
      printf("%s Function call <%s>\n", beginning, node->function_call->function->identifier);

      if(node->function_call->argv->len) {
        guint i = 0;
        for(; i < node->function_call->argv->len - 1; i++) {
          ast_dump_and_indent(g_ptr_array_index(node->function_call->argv, i), indent + 1, "├─ Argument value:", true, expands, to_prepend + 1);
        }
        ast_dump_and_indent(g_ptr_array_index(node->function_call->argv, i), indent + 1, "└─ Argument value:", false, expands, to_prepend + 1);
      }
      break;
    case NODE_SCOPE:
      printf("%s Scop <%lu> (holds %u statement(s))\n", beginning, node->scope->identifier, node->scope->statements->len);

      guint j = 0;
      for(; j < node->scope->statements->len - 1; j++) {
        ast_dump_and_indent(g_ptr_array_index(node->scope->statements, j), indent + 1, "├─", true, expands, to_prepend + 1);
      }
      ast_dump_and_indent(g_ptr_array_index(node->scope->statements, j), indent + 1, "└─", false, expands, to_prepend + 1);
      break;
    default: // Unknown AST node type detected
      return;
  }
}

void ast_dump(const ASTNode * node) {
  indentation = g_array_new(FALSE, TRUE, sizeof(size_t));
  ast_dump_and_indent(node, 0, "──", false, false, 0);
  g_array_free(indentation, TRUE);
}

ASTFunctionDeclaration * ast_find_function_declaration(const ASTNode * tree, const Symbol * function) {
  if(!tree) {
    return NULL;
  }

  if(tree->type == NODE_FUNCTION_DECLARATION && sy_equal(tree->function_declaration->function, function)) {
    return tree->function_declaration;
  }

  if(tree->type == NODE_SCOPE) {
    ASTFunctionDeclaration * result = NULL;
    for(guint i = 0; i < tree->scope->statements->len; i++) {
      if((result = ast_find_function_declaration(g_ptr_array_index(tree->scope->statements, i), function))) {
        return result;
      }
    }
  }

  return NULL;
}

bool is_node_integer_constant(const ASTNode * node) {
  return node && node->type == NODE_SYMBOL && node->symbol->is_constant && node->symbol->value->type == VALUE_INTEGER;
}