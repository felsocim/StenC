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

int intlen(int number) {
	int i = 0, c = 1;

	for(i = 10; i < INT_MAX; i *= 10) {
		if(number < i)
			return c;

		c++;
	}

	return -1;
}
