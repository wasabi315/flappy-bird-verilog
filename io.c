#include <stdio.h>
#include <termios.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <stdlib.h>

int _kbhit() {
    static int initialized = 0;

    if (!initialized) {
        struct termios term;
        tcgetattr(STDIN_FILENO, &term);
        term.c_lflag &= ~ICANON;
        tcsetattr(STDIN_FILENO, TCSANOW, &term);
        setbuf(stdin, NULL);
        initialized = 1;
    }

    int bytesWaiting;
    ioctl(STDIN_FILENO, FIONREAD, &bytesWaiting);
    return bytesWaiting;
}

double fps = 60.0;

void parse_env(int argc, char **argv) {
    if (argc >= 2) {
        fps = strtod(argv[1], NULL);
    }
}

int main(int argc, char **argv) {
    parse_env(argc, argv);

    while (1) {
        usleep(1000000 / fps);
        if (_kbhit()) {
            putchar(getchar());
        } else {
            putchar(0);
        }
        fflush(stdout);
    }
}
