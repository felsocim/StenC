CC = gcc
CFLAGS = -g -Wall

tests: dirs tos src/test/table.c
	$(CC) $(CFLAGS) obj/common.o obj/tos.o src/test/table.c -o bin/test/table.out

tos: dirs common include/tos.h src/tos.c
	$(CC) $(CFLAGS) -c src/tos.c -o obj/tos.o

common: dirs include/common.h src/common.c
	$(CC) $(CFLAGS) -c src/common.c -o obj/common.o

dirs:
	test -d obj || mkdir obj
	test -d bin || mkdir bin
	test -d bin/test || mkdir bin/test

clean:
	rm -fr obj/* bin/*
