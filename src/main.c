#include "idt.h"
#include "isr.h"
#include "screen.h"
#include "util.h"

void _main() {
  // Your code goes here
  idt_init();
  isr_init();
  screen_init();
}

// void _main() {
//   unsigned short *VGA_MEMORY = (unsigned short *)(0xA0000);
//   VGA_MEMORY[0] = 0x3333;
//   VGA_MEMORY[1] = 0x4444;
//   VGA_MEMORY[293] = 0x4444;
//   for (;;) {
//   }
// }
