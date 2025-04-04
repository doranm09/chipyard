#include <stdint.h>

#include <platform.h>

#include "common.h"

#define DEBUG
#include "kprintf.h"

void main(void) {
	REG32(uart, UART_REG_TXCTRL) = UART_TXEN;
    kputs("Hello from payload at 0x80000000!\r\n");
    while (1);
}
