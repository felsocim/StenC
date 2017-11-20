CC = gcc
CFLAGS = -g -Wall

all: tos src/main.c
	$(CC) $(CFLAGS) obj/common.o obj/tos.o src/main.c -o a.out

tos: common include/tos.h src/tos.c
	$(CC) $(CFLAGS) -c src/tos.c -o obj/tos.o

common: include/common.h src/common.c
	$(CC) $(CFLAGS) -c src/common.c -o obj/common.o
