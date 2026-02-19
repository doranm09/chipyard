#include <stdint.h>

#include <platform.h>

#include "common.h"

#define DEBUG
#include "kprintf.h"

void main(void) {
	uart_init();
    kputs("Hello from payload at 0x80000000!\r\n");
    while (1);
}
