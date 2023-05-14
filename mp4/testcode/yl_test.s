.align 4
.section .text
.globl _start
_start:

# test_jal:
#     #csrrs x5, cycle, x0
#     rdcycle x5
#     jal x2, jumpto

# test_jalr:
#     lw x4, GOOD
#     auipc x3, 0
#     jalr x0, 20(x3)

# jumpto:
#     lw x1, GOOD
#     jal x2, test_jalr


# end:
#     #csrrs x5, cycle, x0
#     rdcycle x5
# halt:
#     beq x0, x0, halt  
    addi x2, x0, 10
    addi x1, x0, 0

loop:
    addi x1, x1, 1
    lw x3, BAD
    bne x1, x2, loop

    lw x3, GOOD
end:
    beq x0,x0, end

.section .rodata
.balign 256
DataSeg:
    nop
    nop
    nop
    nop
    nop
    nop
BAD:            .word 0x00BADBAD
PAY_RESPECTS:   .word 0xFFFFFFFF
# cache line boundary - this cache line should never be loaded

A:      .word 0x00000001
GOOD:   .word 0x600D600D
NOPE:   .word 0x00BADBAD
TEST:   .word 0x00000000
FULL:   .word 0xFFFFFFFF
        nop
        nop
        nop
# cache line boundary

B:      .word 0x00000002
        nop
        nop
        nop
        nop
        nop
        nop
        nop
# cache line boundary

C:      .word 0x00000003
        nop
        nop
        nop
        nop
        nop
        nop
        nop
# cache line boundary

D:      .word 0x00000004
        nop
        nop
        nop
        nop
        nop
        nop
        nop

.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0
