#include <platform.h>
#include <smp.h>
#include "common.h"


.section .text.init
.option norvc
.globl _prog_start

_prog_start:
  li sp, 0x800ff000  // Some high memory location for your stack
  call main                  // Call C code to load from SD card
  la t0, payload_start       // Load address of loaded payload
  jr t0                      // Jump to payload (must be PIC)

.section .bss
.align 12
.skip 0x10000                // 64 KiB reserved for stack
stack_top:

.section .data
.align 12
payload_start = PAYLOAD_DEST
