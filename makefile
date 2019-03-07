CC = gcc
LEX = flex
YACC = bison -d
CFLAGS = -g -Wall -std=c11
LDFLAGS = -lfl -ly -lm
INCLUDES = -I./include

all: compiler include/main.h
	$(CC) $(CFLAGS) $(INCLUDES) obj/*.o src/main.c -o stenc $(LDFLAGS)

compiler: ast analyzer include/main.h
	$(CC) $(CFLAGS) $(INCLUDES) -c src/compiler.c -o obj/compiler.o

analyzer: lexer grammar
	$(CC) $(CFLAGS) $(INCLUDES) -c src/lexer.c -o obj/lexer.o

grammar: src/grammar.y
	$(YACC) -o src/compiler.c --defines="include/compiler.h" src/grammar.y

lexer: src/lexer.l
	$(LEX) -o src/lexer.c --header-file="include/lexer.h" src/lexer.l

#qlist: quad include/qlist.h src/qlist.c
#	$(CC) $(CFLAGS) $(INCLUDES) -c src/qlist.c -o obj/qlist.o

#quad: ast include/quad.h src/quad.c
#	$(CC) $(CFLAGS) $(INCLUDES) -c src/quad.c -o obj/quad.o

ast: tos include/ast.h src/ast.c
	$(CC) $(CFLAGS) $(INCLUDES) -c src/ast.c -o obj/ast.o

tos: symbol include/tos.h src/tos.c
	$(CC) $(CFLAGS) $(INCLUDES) -c src/tos.c -o obj/tos.o

symbol: common value include/symbol.h src/symbol.c
	$(CC) $(CFLAGS) $(INCLUDES) -c src/symbol.c -o obj/symbol.o

value: obj include/value.h src/value.c
	$(CC) $(CFLAGS) $(INCLUDES) -c src/value.c -o obj/value.o

common: obj include/common.h src/common.c
	$(CC) $(CFLAGS) $(INCLUDES) -c src/common.c -o obj/common.o

obj:
	test -d obj || mkdir obj

test:
	test -d test || mkdir test

clean:
	rm -fr obj test src/lexer.c include/lexer.h include/compiler.h src/compiler.c stenc *.s
