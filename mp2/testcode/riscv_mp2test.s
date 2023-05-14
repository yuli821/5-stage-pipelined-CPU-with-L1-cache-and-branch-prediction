riscv_mp2test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    # Note that one/two/eight are data labels
    lw  x1, threshold # X1 <- 0x40
    lui  x2, 2       # X2 <= 0x2000
    lui  x3, 8     # X3 <= 0x8000
    srli x2, x2, 12 # x2 <= 0x2
    srli x3, x3, 12 # x3 <= 0x8

    addi x4, x3, 4    # X4 <= X3 + 2 = 0xc

loop1:
    slli x3, x3, 1    # X3 <= X3 << 1 = 0x10 = 0x20 = 0x40 = 0x80 = 0x100 = 0x200 = 0x400 = 0x800 = 0x1000 = 0x2000 = 0x4000 = 0x8000 = 0x10000 = 0x20000
    xori x5, x2, 127  # X5 <= XOR (X2, 7b'1111111) = 0x7d
    addi x5, x5, 1    # X5 <= X5 + 1 = 0x7e
    addi x4, x4, 4    # X4 <= X4 + 4 = 0x10 = 0x14 = 0x18 = 0x1c = 0x20 = 0x24 = 0x28 = 0x2c = 0x30 = 0x34 = 0x38 = 0x3c = 0x40 = 0x44

    bleu x4, x1, loop1   # Branch if x4 <= 0x40

    andi x6, x3, 64   # X6 <= X3 & 64 = 0x20000 & 0x40 = 0x0

    auipc x7, 8         # X7 <= PC + 0x8000
    lw x8, good         # X8 <= 0x600d600d
    la x10, result      # X10 <= Addr[result]
    sw x8, 0(x10)       # [Result] <= 0x600d600d
    lw x9, result       # X9 <= [Result]
    bne x8, x9, deadend # PC <= bad if x8 != x9

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

deadend:
    lw x8, bad     # X8 <= 0xdeadbeef
deadloop:
    beq x8, x8, deadloop

.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d
