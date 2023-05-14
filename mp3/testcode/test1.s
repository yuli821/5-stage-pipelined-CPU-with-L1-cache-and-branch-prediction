test1.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:

    # lui x1, 0x01010  # x5 <= 0x01010000
    # srli x2, x1, 4
    # slli x3, x2, 4
    # addi x4, x0, -10  #fffffff6
    # srai x5, x4, 4    #ffffffff
    # auipc x1, 2       #store pc address + 0x00002000 to x1
    # addi x2, x0, 4    #store 4 to x2
    # sll  x3, x1, x2   #logical left shift the value in x1 by 4 bits
    # srl  x3, x1, x2   #logical right shift the value in x1 by 4 bits
    # addi x4, x0, -10  #fffffff6
    # sra  x5, x4, x2   #arithmetic right shift the value in x4 by 4 bits
    # lw x1, good         # X8 <= 0x600d600d
    # la x2, result      # X10 <= Addr[result]
    # sw x1, 0(x2)       # [Result] <= 0x600d600d
    # lw x3, result       # X9 <= [Result]
    # beq x1, x3, deadend # PC <= bad if x8 != x9
    #lh x1, good         # X8 <= 0x600d
    # la x2, result      # X10 <= Addr[result]
    # lh x3, good         # X8 <= 0x0d
    # sh x3, 0(x2)
    # lh x4, result
    # addi x1, x0, 4
    # addi x2, x0, 5
    # xor  x3, x1, x2
    # or   x4, x1, x2
    # and  x5, x1, x2
    # blt  x1, x2, deadend            # branch if x1 < x2
    # la  x2, deadend
    # addi x2, x2, -10
    # jalr x1, x2, 10
    # lw  x8, bad
branch1:
    la  x1, bad
    # lb  x8, 0(x1)
    # lb  x7, 1(x1)
    # lbu  x6, 2(x1)
    lb x5, 3(x1)
    lb x6, 2(x1)
    lb x7, 1(x1)
    lb x8, 0(x1)
    la x1, result
    sb x5, 3(x1)
    sb x6, 2(x1)
    sb x7, 1(x1)
    sb x8, 0(x1)
    lw x6, 0(x1)
#     addi x1, x0, -1
#     bltu x1, x2, deadend
#     bgeu x1, x2, deadend
    # slt  x3, x2, x1       # x2 < x1 ? no, x3 <= 0
    # slt  x4, x1, x2       # x1 < x2 ? yes, x4 <= 1
    # addi x5, x0, -1
    # slt  x6, x5, x1       # x5 < x1 ? yes, x6 <= 1
    # sltu x7, x5, x1       # x5 < x1 in unsigned case ? no, x7 <= 0

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

deadend:
    lw x8, bad     # X8 <= 0xdeadbeef
    addi x2, x0, 3
    #bge  x1, x2, branch1        # branch if x1 > x2

deadloop:
    beq x8, x8, deadloop

.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x800d800d
