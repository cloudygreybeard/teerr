#include <unistd.h>

int main(void) {
    char buf[8192];
    ssize_t n;

    while ((n = read(STDIN_FILENO, buf, sizeof(buf))) > 0) {
        write(STDOUT_FILENO, buf, n);
        write(STDERR_FILENO, buf, n);
    }

    return n < 0 ? 1 : 0;
}
