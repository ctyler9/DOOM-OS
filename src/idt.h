#ifndef IDT_H
#define IDT_H

#include "isr.h"
#include "util.h"

void idt_set(u8 index, void (*base)(struct Registers *), u16 selector,
             u8 flags);
void idt_init();

#endif
