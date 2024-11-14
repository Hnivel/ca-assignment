.data
image:              .space  196                                         # Image matrix (7x7 floating-point)
kernel:             .space  64                                          # Kernel matrix (max 4x4 floating-point)
out:                .space  196                                         # Output matrix
newline:            .asciiz "\n"                                        # Newline character
buffer:             .space  1024                                        # Buffer
input_filename:     .asciiz "input_matrix.txt"                          # Input filename
output_filename:    .asciiz "output_matrix.txt"                         # Output filename
error:              .asciiz "Unable to open the input file"
error_size:         .asciiz "Error: size not match"
N:                  .word   0
M:                  .word   0
padding:            .word   0
stride:             .word   0
temporary:          .word   0

.text
main:
    # Open the input file (input_matrix.txt)
    li      $v0,                    13
    la      $a0,                    input_filename
    li      $a1,                    0
    li      $a2,                    0
    syscall
    move    $s0,                    $v0                                 # $s0 = file descriptor

    # Check for file opening error
    bltz    $s0,                    Error

    # Read the input file into buffer
    li      $v0,                    14
    move    $a0,                    $s0
    la      $a1,                    buffer
    li      $a2,                    1024
    syscall

    # Read the first line of the input buffer
    la      $t0,                    buffer
    jal     parse_first_line

    # Check if size matches
    lw      $t0,                    N
    lw      $t1,                    M
    lw      $t2,                    padding
    add     $t2,                    $t2,            $t2                 # $t2 = 2 * padding
    add     $t0,                    $t0,            $t2                 # $t0 = N + 2 * padding
    blt     $t0,                    $t1,            Error_size

    # Read image matrix and store in `image`
    la      $t0,                    buffer
    addi    $t0,                    $t0,            17                  # Move to second line
    la      $t1,                    image                               # $t1 is the address of image[0][0]
    li      $t2,                    0                                   # Counter for image matrix elements
    lw      $t3,                    N                                   # $t3 = N
    mul     $t3,                    $t3,            $t3                 # $t3 = N * N
read_image_matrix:
    bge     $t2,                    $t3,            read_kernel_matrix
    jal     floating_point_number
    s.s     $f0,                    0($t1)
    addi    $t1,                    $t1,            4                   # Move to next element in image array
    addi    $t2,                    $t2,            1                   # Increment elements counter
    j       read_image_matrix

read_kernel_matrix:
    # Read kernel matrix and store in `kernel`
    li      $t2,                    0                                   # Counter for kernel elements
    la      $t1,                    kernel                              # $t1 = kernel address
    lw      $t3,                    M                                   # $t3 = M
    mul     $t3,                    $t3,            $t3                 # $t3 = M * M
read_kernel_loop:
    bge     $t2,                    $t3,            perform_convolution # Done reading kernel
    jal     floating_point_number
    s.s     $f0,                    0($t1)
    addi    $t1,                    $t1,            4                   # Move to next element in kernel array
    addi    $t2,                    $t2,            1                   # Increment elements counter
    j       read_kernel_loop

perform_convolution:
    # Perform convolution operation
    jal     convolution

    # Print output result to terminal and output_matrix.txt
    jal     output_result

    # Exit program
Exit:
    li      $v0,                    10
    syscall

    # Parsing the first line to get N, M, padding, and stride
parse_first_line:
    la      $t1,                    N
    lb      $t2,                    0($t0)
    sub     $t2,                    $t2,            '0'
    sw      $t2,                    0($t1)
    la      $t1,                    M
    lb      $t2,                    4($t0)
    sub     $t2,                    $t2,            '0'
    sw      $t2,                    0($t1)
    la      $t1,                    padding
    lb      $t2,                    8($t0)
    sub     $t2,                    $t2,            '0'
    sw      $t2,                    0($t1)
    la      $t1,                    stride
    lb      $t2,                    12($t0)
    sub     $t2,                    $t2,            '0'
    sw      $t2,                    0($t1)

    jr      $ra

    # Floating-point number parsing from buffer
floating_point_number:
    li      $t5,                    0
    li      $t6,                    0
    li      $t7,                    1
    li      $t8,                    0

convert_character_loop:
    lb      $t9,                    0($t0)
    addi    $t0,                    $t0,            1
    beq     $t9,                    32,             end_convert
    beq     $t9,                    10,             end_convert
    beq     $t9,                    46,             fraction_part
    sub     $t9,                    $t9,            '0'
    beq     $t8,                    0,              integer_part

    # Process fractional part
    mul     $t7,                    $t7,            10
    mul     $t9,                    $t9,            $t7
    add     $t6,                    $t6,            $t9
    j       convert_character_loop

integer_part:
    mul     $t5,                    $t5,            10
    add     $t5,                    $t5,            $t9
    j       convert_character_loop

fraction_part:
    li      $t8,                    1
    j       convert_character_loop

end_convert:
    mtc1    $t5,                    $f0
    cvt.s.w $f0,                    $f0
    mtc1    $t6,                    $f1
    cvt.s.w $f1,                    $f1
    li      $t2,                    0x3F800000
    mtc1    $t2,                    $f2

fraction_division_loop:
    beq     $t7,                    1,              combine_parts
    div.s   $f1,                    $f1,            $f2
    div     $t7,                    $t7,            10
    j       fraction_division_loop

combine_parts:
    add.s   $f0,                    $f0,            $f1
    jr      $ra

    # Convolution operation
convolution:
    lw      $t0,                    N
    lw      $t1,                    M
    lw      $t2,                    padding
    lw      $t3,                    stride
    add     $t4,                    $t0,            $t2
    add     $t4,                    $t4,            $t2
    la      $t5,                    image
    la      $t6,                    kernel
    la      $t7,                    out

    li      $t8,                    0
conv_row_loop:
    li      $t9,                    0
conv_col_loop:
    li.s    $f12,                   0.0
    li      $t10,                   0
kernel_row_loop:
    li      $t11,                   0
kernel_col_loop:
    mul     $t12,                   $t8,            $t3
    add     $t12,                   $t12,           $t10
    mul     $t12,                   $t12,           $t4
    mul     $t13,                   $t9,            $t3
    add     $t13,                   $t13,           $t11
    add     $t12,                   $t12,           $t13
    sll     $t12,                   $t12,           2
    add     $t14,                   $t5,            $t12
    l.s     $f14,                   0($t14)
    mul     $t15,                   $t10,           $t1
    add     $t15,                   $t15,           $t11
    sll     $t15,                   $t15,           2
    add     $t16,                   $t6,            $t15
    l.s     $f16,                   0($t16)
    mul.s   $f18,                   $f14,           $f16
    add.s   $f12,                   $f12,           $f18
    addi    $t11,                   $t11,           1
