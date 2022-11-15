
  .section ".text.init","ax",@progbits
  .globl _start
  .align 2
_start:
    add t1, x0, x0
    ld  t2, (t1)
    ld  t3, 8 (t1)
    ld  t4, 16(t1)
    ld  t5, 24(t1)
    ld  t6, 32(t1)
    .rept 500
      nop
    .endr

    # End signal
    sw x0, (x0)

infinite_loop:
    j infinite_loop
