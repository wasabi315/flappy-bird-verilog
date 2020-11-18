#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

double fps = 60.0;

void parse_env(int argc, char **argv) {
    if (argc >= 2) {
        fps = strtod(argv[1], NULL);
    }
}

int main(int argc, char **argv) {
    parse_env(argc, argv);

    while (1) {
        printf("x");
        fflush(stdout);
        sleep(1 / fps);
    }
}

