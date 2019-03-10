#include "../include/common.h"

void failwith(const char * message) {
	if(message != NULL && errno != 0) {
		perror(message);
	} else {
		fprintf(stderr, "%s!\n", message);
	}
	exit(EXIT_FAILURE);
}

void usage(const char * arg_0, int exit_code) {
	char * app_name = strrchr(arg_0, '/');
	if(exit_code != 0) {
		fprintf(stderr, usage_message, app_name);
    } else {
        fprintf(stdout, help_message, app_name);
    }
    exit(exit_code);
}

size_t intlen(int number) {
	if(number < 10 && number > -9) {
		return 1;
	}

	return 1 + intlen(number / 10);
}

char * strdup(const char * __s) {
	char * copy = (char *) malloc(strlen(__s) + 1);
	if(!copy) {
		return NULL;
	}
	copy = strcpy(copy, __s);
	return copy;
}