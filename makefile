CC = gcc
LEX = flex
YACC = bison -d
CFLAGS = -g -Wall -I./include
LDFLAGS = -lfl -ly -lm

all: compiler include/main.h
	$(CC) $(CFLAGS) obj/*.o src/main.c -o bin/cc $(LDFLAGS)

tests: tos src/test/table.c
	$(CC) $(CFLAGS) obj/common.o obj/tos.o src/test/table.c -o bin/test/table.out

compiler: tos slist tab  quad qlist analyzer include/main.h src/compiler.c
	$(CC) $(CFLAGS) -c src/compiler.c -o obj/compiler.o

analyzer: lexer grammar
	$(CC) $(CFLAGS) -c src/lexer.c -o obj/lexer.o

grammar: src/grammar.y
	$(YACC) -o src/compiler.c --defines="include/compiler.h" src/grammar.y

lexer: src/lexer.l
	$(LEX) -o src/lexer.c src/lexer.l

qlist: quad include/qlist.h src/qlist.c
	$(CC) $(CFLAGS) -c src/qlist.c -o obj/qlist.o

quad: tos include/quad.h src/quad.c
	$(CC) $(CFLAGS) -c src/quad.c -o obj/quad.o

slist: tos include/slist.h src/slist.c
	$(CC) $(CFLAGS) -c src/slist.c -o obj/slist.o

tos: common value include/tos.h src/tos.c
	$(CC) $(CFLAGS) -c src/tos.c -o obj/tos.o

value: tab common include/value.h src/value.c
	$(CC) $(CFLAGS) -c src/value.c -o obj/value.o

tab: common include/tab.h src/tab.c
	$(CC) $(CFLAGS) -c src/tab.c -o obj/tab.o

common: dirs include/common.h src/common.c
	$(CC) $(CFLAGS) -c src/common.c -o obj/common.o

dirs:
	test -d obj || mkdir obj
	test -d bin || mkdir bin
	test -d bin/test || mkdir bin/test

clean:
	rm -fr obj bin src/lexer.c include/compiler.h src/compiler.c *.s
