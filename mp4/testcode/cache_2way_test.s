cache_2way_test.s:
.align 4
.section .text
.globl _start

_start:
    la x1, result
    lw x2, result   # Read. Update first way
    addi x2, x2, 5
    sw x2, (x1)     # Write into first way
    lw x3, result   # Read back result from first way
    lw x4, loc2     # Read. Updated second way
    lw x5, loc3     # Read into first way. Causes write back
    lw x6, result   # Read from memory, value not in cache
    
halt:
    beq x0, x0, halt  

.word 0x00000000    # Commenting out this line causes the test to stop failing

result:     .word 0x11111111
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678


loc2: .word 0x98765432
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678
.word 0x12345678

loc3: .word 0xabcdef12