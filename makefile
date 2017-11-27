CC = gcc
LEX = flex
YACC = bison -d
CFLAGS = -g -Wall
LDFLAGS = -lfl -ly

all: tos quad lexer grammar
	$(CC) $(CFLAGS) obj/common.o obj/tos.o obj/quad.o src/lexer.c src/compiler.c -o bin/compiler $(LDFLAGS)

tests: tos src/test/table.c
	$(CC) $(CFLAGS) obj/common.o obj/tos.o src/test/table.c -o bin/test/table.out

grammar: src/grammar.y
	$(YACC) -o src/compiler.c --defines="include/compiler.h" src/grammar.y

lexer: src/lexer.l
	$(LEX) -o src/lexer.c src/lexer.l

quad: tos include/quad.h src/quad.c
	$(CC) $(CFLAGS) -c src/quad.c -o obj/quad.o

tos: common include/tos.h src/tos.c
	$(CC) $(CFLAGS) -c src/tos.c -o obj/tos.o

common: dirs include/common.h src/common.c
	$(CC) $(CFLAGS) -c src/common.c -o obj/common.o

dirs:
	test -d obj || mkdir obj
	test -d bin || mkdir bin
	test -d bin/test || mkdir bin/test

clean:
	rm -fr obj bin src/lexer.c include/compiler.h src/compiler.c
