/*
 * Копия server.c из части 3 — исходник приложения не менялся
 * ни разу за все части, менялась только его упаковка.
 * Подробные пояснения к коду — в 03/server.c.
 */

#include <fcgi_stdio.h>
#include <stdlib.h>

int main(void) {
    while (FCGI_Accept() >= 0) {
        printf("Content-Type: text/html\r\n\r\n"
        "<html><body>\n"
        "<h1>Hello World!</h1>\n"
        "</body></html>\n");
    }
    return 0;
}