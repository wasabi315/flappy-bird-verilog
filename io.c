#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>

void _getmaxyx(int *y, int *x) {
    int fd;
    struct winsize ws;

    fd = open("/dev/tty", O_RDWR);
    ioctl(fd, TIOCGWINSZ, &ws);
    close(fd);
    *y = ws.ws_row;
    *x = ws.ws_col;
}

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

int main(int argc, char **argv) {
    if (argc >= 2) {
        fps = strtod(argv[1], NULL);
    }

    int n_row, n_col;
    _getmaxyx(&n_row, &n_col);
    printf("%d %d", n_row, n_col);

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
