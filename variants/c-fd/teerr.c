#include <unistd.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    int target = STDERR_FILENO;
    char buf[8192];
    ssize_t n;

    if (argc > 1) {
        target = atoi(argv[1]);
    }

    while ((n = read(STDIN_FILENO, buf, sizeof(buf))) > 0) {
        write(STDOUT_FILENO, buf, n);
        write(target, buf, n);
    }

    return n < 0 ? 1 : 0;
}
