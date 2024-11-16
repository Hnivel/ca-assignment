.data
image:                  .space  196                                                 # Image matrix (7x7 floating-point number matrix)
kernel:                 .space  64                                                  # Kernel matrix (4x4 floating-point number matrix)
padded_image:           .space  900                                                 # Padded image matrix (15x15 floating-point number matrix)
out:                    .space  784                                                 # Output matrix (14x14 floating-point number matrix)
newline:                .asciiz "\n"                                                # Newline
buffer:                 .space  1024                                                # Buffer
input_filename:         .asciiz "input_matrix.txt"                                  # Input filename
output_filename:        .asciiz "output_matrix.txt"                                 # Output filename
error_input:            .asciiz "Unable to open the input file"                     # Error message for input file
error_output:           .asciiz "Unable to open the input file"                     # Error message for output file
error_size:             .asciiz "Error: size not match"                             # Error message for size mismatch
image_message:          .asciiz "Image: "                                           # Image message
kernel_message:         .asciiz "Kernel: "                                          # Kernel message
padded_image_message:   .asciiz "Padded Image: "                                    # Padded image message
result_message:         .asciiz "\nResult: "                                        # Result message
N:                      .word   0                                                   # N: size of the image
M:                      .word   0                                                   # M: size of the kernel
padding:                .word   0                                                   # padding: padding value
stride:                 .word   0                                                   # stride: stride value
temp_buffer:            .space  32                                                  # Temporary buffer for integer to string conversion
float_string:           .space  32                                                  # Floating-point number string
scale_factor:           .float  10.0                                                # Scale factor for rounding
round_value:            .float  0.01                                                # Round value for rounding
zero_value:             .float  0.0                                                 # Zero value for rounding
space:                  .asciiz " "                                                 # Space
    ########################################################################################################################
.text
main:
    ########################################################################################################################
    # Step 1: Open the input file (input_matrix.txt) (Finished)

    li      $v0,                    13                                              # syscall for opening a file
    la      $a0,                    input_filename                                  # $a0 = address of the input filename
    li      $a1,                    0                                               # $a1 = 0 = read mode
    li      $a2,                    0                                               
    syscall
    move    $s0,                    $v0                                             # $s0 = file descriptor

    ########################################################################################################################
    # Step 2: Check for file opening error (Finished)

    bltz    $s0,                    Error_Input                                     # If $s0 < 0 (file opening error), print error message

    ########################################################################################################################
    # Step 3: Read the input file (input_matrix.txt) (Finished)

    li      $v0,                    14                                              # syscall for reading from a file
    move    $a0,                    $s0                                             # $a0 = file descriptor
    la      $a1,                    buffer                                          # $a1 = address of the buffer
    li      $a2,                    1024                                            # $a2 = buffer size
    syscall

    ########################################################################################################################
    # Step 4: Read the first line of the input buffer (Finished)

    la      $t0,                    buffer                                          # $t0 = address of the buffer
    jal     parse_first_line                                                        # Parse the first line of the buffer

    ########################################################################################################################
    # Step 5: Check for size mismatch (Finished)

    lw      $t0,                    N                                               # $t0 = N
    lw      $t1,                    M                                               # $t1 = M
    lw      $t2,                    padding                                         # $t2 = padding
    add     $t2,                    $t2,                        $t2                 # $t2 = 2 * padding
    add     $t0,                    $t0,                        $t2                 # $t0 = N + 2 * padding
    blt     $t0,                    $t1,                        Error_size          # If N + 2 * padding < M (size mismatch), print error message

    ########################################################################################################################
    # Step 6: Read image matrix and store in `image` (Finished)

read_image_matrix:

    # Functionality: Print the image message

    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    image_message                                   # $a0 = address of the image message
    syscall                 
    la      $t0,                    buffer                                          # $t0 = address of the buffer
    addi    $t0,                    $t0,                        17                  # $t0 = $t0 + 17 = the second line

    # Functionality: Parse the image matrix

    la      $t1,                    image                                           # $t1 = address of the image matrix
    lw      $t2,                    N                                               # $t2 = N
    mul     $t2,                    $t2,                        $t2                 # $t2 = N * N
    li      $t3,                    0                                               # $t3 = 0 (counter for image matrix elements)

parse_image_loop:

    # Functionality: Check if all elements have been parsed

    bge     $t3,                    $t2,                        end_parse_image     # If $t3 >= N * N, end parsing

    # Functionality: Parse the next element in the buffer

    jal     floating_point_number                                                   # Parse the next floating-point number to $f0
    swc1    $f0,                    0($t1)                                          # Store the parsed number in the image matrix

    # Functionality: Print the parsed number

    li      $v0,                    2                                               # syscall for printing floating-point number
    mov.s   $f12,                   $f0                                             # $f12 = $f0 = the parsed number
    syscall

    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    space                                           # $a0 = address of the space
    syscall

    # Functionality: Move to the next element in the image matrix

    addi    $t1,                    $t1,                        4                   # $t1 = $t1 + 4 = move to the next element in the image matrix
    addi    $t3,                    $t3,                        1                   # $t3 = $t3 + 1 = increment the counter
    j       parse_image_loop                                                        

end_parse_image:

    addi    $t0,                    $t0,                        1                   # $t0 = $t0 + 1 = the third line

    # Functionality: Print newline

    li      $v0,                    4
    la      $a0,                    newline
    syscall

    ########################################################################################################################
    # Step 7: Read kernel matrix and store in `kernel` (Finished)

read_kernel_matrix:
    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    kernel_message                                  # $a0 = address of the kernel message
    syscall
    la      $t1,                    kernel                                          # $t1 = address of the kernel matrix
    lw      $t2,                    M                                               # $t2 = M
    mul     $t2,                    $t2,                        $t2                 # $t2 = M * M
    li      $t3,                    0                                               # $t3 = 0 (counter for kernel matrix elements)

parse_kernel_loop:

    # Functionality: Check if all elements have been parsed

    bge     $t3,                    $t2,                        end_parse_kernel    # If $t3 >= M * M, end parsing

    # Functionality: Parse the next element in the buffer

    jal     floating_point_number                                                   # Parse the next floating-point number to $f0
    swc1    $f0,                    0($t1)                                          # Store the parsed number in the kernel matrix

    # Functionality: Print the parsed number

    li      $v0,                    2                                               # syscall for printing floating-point number
    mov.s   $f12,                   $f0                                             # $f12 = $f0 = the parsed number
    syscall

    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    space                                           # $a0 = address of the space
    syscall

    # Functionality: Move to the next element in the kernel matrix

    addi    $t1,                    $t1,                        4                   # $t1 = $t1 + 4 = move to the next element in the kernel matrix
    addi    $t3,                    $t3,                        1                   # $t3 = $t3 + 1 = increment the counter
    j       parse_kernel_loop

end_parse_kernel:
    
    # Functionality: Print newline

    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    newline                                         # $a0 = address of the newline
    syscall

    ########################################################################################################################
    # Step 8: Pad the image matrix with zeros (Finished)

padding_image:
    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    padded_image_message                            # $a0 = address of the padded image message
    syscall
    lw      $t0,                    N                                               # $t0 = N
    lw      $t1,                    padding                                         # $t1 = padding

    # Functionality: Calculate the size of the padded image

    add     $t2,                    $t0,                        $t1                 # $t2 = $t0 + $t1 = N + padding
    move    $s7,                    $t2                                             # $s7 = N + padding
    add     $t2,                    $t2,                        $t1                 # $t2 = $t2 + $t1 = N + padding * 2 = padded image size

    # Functionality: Initialize image and padded_image pointers
    la      $t3,                    image                                           # $t3 = address of the image matrix
    la      $t4,                    padded_image                                    # $t4 = address of the padded image matrix

    # Functionality: Initialize loop counters

    li      $t5,                    0                                               # $t5 = row counter

row_loop:

    li      $t6,                    0                                               # $t6 = column counter

column_loop:
    
    # Functionality: Check if we are in the padding area (row)

    blt     $t5,                    $t1,                        pad_pixel           # If row < padding, pad the pixel
    bge     $t5,                    $s7,                        pad_pixel           # If row >= N + padding, pad the pixel

    # Functionality: Check if we are in the padding area (column)

    blt     $t6,                    $t1,                        pad_pixel           # If column < padding, pad the pixel
    bge     $t6,                    $s7,                        pad_pixel           # If column >= N + padding, pad the pixel

    # Functionality: Copy the original image pixel to the padded image

    sub     $t7,                    $t5,                        $t1                 # $t7 = $t5 - $t1 = row - padding
    mul     $t7,                    $t7,                        $t0                 # $t7 = $t7 * $t0 = (row - padding) * N
    sub     $t8,                    $t6,                        $t1                 # $t8 = $t6 - $t1 = column - padding
    add     $t7,                    $t7,                        $t8                 # $t7 = $t7 + $t8 = (row - padding) * N + (column - padding)
    sll     $t7,                    $t7,                        2                   # $t7 = $t7 << 2 = 4 * ((row - padding) * N + (column - padding))
    add     $t7,                    $t3,                        $t7                 # $t7 = address of the original image pixel
    lwc1    $f0,                    0($t7)                                          # $f0 = original image pixel
    swc1    $f0,                    0($t4)                                          # Store the pixel in the padded image

    # Functionality: Print the original image pixel

    li      $v0,                    2                                               # syscall for printing floating-point number
    mov.s   $f12,                   $f0                                             # $f12 = $f0 = the original image pixel
    syscall

    # Functionality: Print space

    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    space                                           # $a0 = address of the space
    syscall

    j       next_pixel

    # Functionality: Pad the pixel with zeros

pad_pixel:
    li      $t9,                    0                                               # $t9 = 0 = zero value
    mtc1    $t9,                    $f0                                             # $f0 = 0.0
    cvt.s.w $f0,                    $f0                                             # $f0 = 0.0
    swc1    $f0,                    0($t4)                                          # Store the pixel in the padded image

    # Functionality: Print the padded pixel

    li      $v0,                    2                                               # syscall for printing floating-point number
    mov.s   $f12,                   $f0                                             # $f12 = $f0 = the padded pixel
    syscall

    # Functionality: Print space

    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    space                                           # $a0 = address of the space
    syscall
    
next_pixel:
    addi    $t6,                    $t6,                        1                   # $t6 = $t6 + 1 = increment column counter
    addi    $t4,                    $t4,                        4                   # $t4 = $t4 + 4 = move to the next pixel in the padded image
    bne     $t6,                    $t2,                        column_loop         # If column counter < padded image size, continue the column loop

    addi    $t5,                    $t5,                        1                   # $t5 = $t5 + 1 = increment row counter
    bne     $t5,                    $t2,                        row_loop            # If row counter < padded image size, continue the row loop

    ########################################################################################################################
    # Step 9: Convolution operation (Finished)

    jal     convolution_process

    ########################################################################################################################
    # Step 10: Print output result to terminal and output_matrix.txt (Unfinished)

output_result:
    lw      $t0,                    N                                               # $t0 = N
    lw      $t1,                    M                                               # $t1 = M
    lw      $t2,                    padding                                         # $t2 = padding
    lw      $t3,                    stride                                          # $t3 = stride

    add     $t4,                    $t2,                        $t2                 # $t4 = 2 * padding
    add     $t5,                    $t0,                        $t4                 # $t5 = N + 2 * padding
    sub     $t5,                    $t5,                        $t1                 # $t5 = N + 2 * padding - M

    div     $t5,                    $t3                                             # $t5 = (N + 2 * padding - M) / s
    mflo    $t5                                                                     # $t5 = (N + 2 * padding - M) / s

    addi    $s1,                    $t5,                        1                   # $s1 = (N + 2 * padding - M) / s + 1
    mul     $s1,                    $s1,                        $s1                 # $t5 = ((N + 2 * padding - M) / s + 1) ^ 2 = output_matrix_size

    # Functionality: Open the output file (output_matrix.txt) (Finished)

    li      $v0,                    13                                              # syscall for opening a file
    la      $a0,                    output_filename                                 # $a0 = address of the output filename
    li      $a1,                    1                                               # $a1 = 1 = write mode
    li      $a2,                    0                                               
    syscall
    move    $s0,                    $v0                                             # $s0 = file descriptor

    # Functionality: Check for file opening error (Finished)

    bltz    $s0,                    Error_Output

    # Functionality: Print the output matrix to the output file (output_matrix.txt)
    # Arguments: out, output_matrix_size
    # Return: Output matrix in the output file
    # Status: Finished

    la      $s2,                    out                                             # $s2 = address of the output matrix
    li      $s3,                    0                                               # $s3 = 0 = loop counter for the output matrix
    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    result_message                                  # $a0 = address of the result message
    syscall

write_loop:

    bge     $s3,                    $s1,                        close_file          # If $s3 >= $s1 (counter >= output_matrix_size), close the output file

    # Functionality: Print the next element in the output matrix

    l.s     $f12,                   0($s2)                                          # $f12 = the next element in the output matrix
    addiu   $s2,                    $s2,                        4                   # $s2 = $s2 + 4 = move to the next element in the output matrix

    # Functionality: Write the element to the output file

    jal     float_to_string

    la      $s4,                    float_string                                    # $s4 = address of the float_string
    li      $s5,                    0                                               # $s5 = 0 = counter for the float_string

count_length:
    lb      $t0,                    0($s4)                                          # $t0 = the current byte in the float_string
    beq     $t0,                    $zero,                      end_count           # If $t0 == 0, end counting
    addi    $s4,                    $s4,                        1                   # $s4 = $s4 + 1 = move to the next byte
    addi    $s5,                    $s5,                        1                   # $s5 = $s5 + 1 = increment counter
    j       count_length
end_count:

    li      $v0,                    15                                              # syscall for writing to a file
    move    $a0,                    $s0                                             # $s0 = file descriptor
    la      $a1,                    float_string                                    # $a1 = address of the float_string
    move    $a2,                    $s5                                             # $a2 = length of the float_string
    syscall

    # Functionality: Print the output matrix element

    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    float_string                                    # $a0 = address of the float_string
    syscall

    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    space                                           # $a0 = address of the space
    syscall

    # Functionality: Increment the loop counter and print space if not the last element

    addi    $s3,                    $s3,                        1                   # $s3 = $s3 + 1 = increment loop counter
    blt     $s3,                    $s1,                        print_space         # If $s3 < $s1, print space
    j       write_loop

print_space:

    move    $a0,                    $s0                                             # $a0 = file descriptor
    la      $a1,                    space                                           # $a1 = address of the space
    la      $a2,                    1                                               # $a2 = 1 = length of the space
    li      $v0,                    15                                              
    syscall
    j       write_loop

    # Functionality: Close the output file

close_file:
    li      $v0,                    16                                              # syscall for closing a file
    move    $a0,                    $s0                                             # $a0 = file descriptor
    syscall

    ########################################################################################################################
    # Step 11: Exit

Exit:
    li      $v0,                    10
    syscall

    ########################################################################################################################
    ########################################################################################################################
    ########################################################################################################################
    ########################################################################################################################
    # Functionality: Input N, M, padding, stride from the first line of the input buffer
    # Arguments: $t0 = address of the first line in the buffer
    # Return: N, M, padding, stride
    # Status: Finished

parse_first_line:

    # Functionality: Parse N, M, padding, stride from the first line of the buffer

    # N (size of the image matrix)

    la      $t1,                    N                                               # $t1 = address of N
    lb      $t2,                    0($t0)                                          # $t2 = first character in the buffer
    sub     $t2,                    $t2,                        '0'                 # $t2 = $t2 - '0' = convert ASCII to integer
    sw      $t2,                    0($t1)                                          # Store N

    # M (size of the kernel matrix)

    la      $t1,                    M                                               # $t1 = address of M
    lb      $t2,                    4($t0)                                          # $t2 = fifth character in the buffer
    sub     $t2,                    $t2,                        '0'                 # $t2 = $t2 - '0' = convert ASCII to integer
    sw      $t2,                    0($t1)                                          # Store M

    # padding (padding value)

    la      $t1,                    padding                                         # $t1 = address of padding
    lb      $t2,                    8($t0)                                          # $t2 = ninth character in the buffer
    sub     $t2,                    $t2,                        '0'                 # $t2 = $t2 - '0' = convert ASCII to integer
    sw      $t2,                    0($t1)                                          # Store padding

    # stride (stride value)

    la      $t1,                    stride                                          # $t1 = address of stride
    lb      $t2,                    12($t0)                                         # $t2 = thirteenth character in the buffer
    sub     $t2,                    $t2,                        '0'                 # $t2 = $t2 - '0' = convert ASCII to integer
    sw      $t2,                    0($t1)                                          # Store stride
    jr      $ra

    ########################################################################################################################
    # Functionality: Convolution operation
    # Arguments: N, M, padding, stride, image, kernel
    # Return: Output matrix
    # Status: Finished

convolution_process:

    lw      $t0,                    N                                               # $t0 = N (size of the image matrix)
    lw      $t1,                    M                                               # $t1 = M (size of the kernel matrix)
    lw      $t2,                    padding                                         # $t2 = padding value
    lw      $t3,                    stride                                          # $t3 = stride value

    # Functionality: Calculate the size of the padded image

    add     $t4,                    $t0,                        $t2                 # $t4 = N + padding
    add     $t4,                    $t4,                        $t2                 # $t4 = N + 2 * padding

    # Functionality: Calculate the size of the output matrix

    sub     $t5,                    $t4,                        $t1                 # $t5 = $t4 - $t1 = N + 2 * padding - M
    div     $t5,                    $t5,                        $t3                 # $t5 = ($t4 - $t1) / $t3 = (N + 2 * padding - M) / stride
    add     $t5,                    $t5,                        1                   # $t5 = $t5 + 1 = ($t4 - $t1) / $t3 + 1

    # Functionality: Initialize loop counters

    li      $t6,                    0                                               # $t6 = row index of the output matrix

convolution_row_loop:

    bge     $t6,                    $t5,                        end_process         # If $t6 >= $t5, end the convolution process
    li      $t7,                    0                                               # $t7 = column index of the output matrix

col_loop:

    bge     $t7,                    $t5,                        next_row            # If $t7 >= $t5, move to the next row

    mtc1    $zero,                  $f0                                             # $f0 = 0.0 = convolution sum

    li      $t8,                    0                                               # $t8 = 0 = kernel row index

kernel_row_loop:

    bge     $t8,                    $t1,                        save_output         # If $t8 >= $t1, save the output
    li      $t9,                    0                                               # $t9 = 0 = kernel column index
    
kernel_col_loop:
    bge     $t9,                    $t1,                        next_kernel_row     # If $t9 >= $t1, move to the next kernel row

    # Functionality: Calculate the corresponding indices in the padded_image
    mul     $s1,                    $t6,                        $t3                 # $s1 = $t6 * $t3 = row index in the padded image
    mul     $s2,                    $t7,                        $t3                 # $s2 = $t7 * $t3 = column index in the padded image

    add     $s1,                    $s1,                        $t8                 # $s1 = $s1 + $t8 = adjust row index by kernel row
    add     $s2,                    $s2,                        $t9                 # $s2 = $s2 + $t9 = adjust column index by kernel column

    # Functionality: Calculate the address in the padded image

    mul     $s3,                    $s1,                        $t4                 # $s3 = $s1 * $t4 = row offset in padded image
    add     $s3,                    $s3,                        $s2                 # $s3 = $s3 + $s2 = column index in padded image
    sll     $s3,                    $s3,                        2                   # $s3 = $s3 << 2 = word align the address
    lwc1    $f1,                    padded_image($s3)                               # $f1 = value from the padded image

    # Functionality: Calculate the address in the kernel

    mul     $s5,                    $t8,                        $t1                 # $s5 = $t8 * $t1 = row offset in kernel
    add     $s5,                    $s5,                        $t9                 # $s5 = $s5 + $t9 = column index in kernel
    sll     $s5,                    $s5,                        2                   # $s5 = $s5 << 2 = word align the address
    lwc1    $f2,                    kernel($s5)                                     # $f2 = value from the kernel

    # Functionality: Multiply and accumulate the convolution sum

    mul.s   $f3,                    $f1,                        $f2                 # $f3 = $f1 * $f2 = padded image value * kernel value
    add.s   $f0,                    $f0,                        $f3                 # $f0 = $f0 + $f3 = convolution sum + padded image value * kernel value

    addi    $t9,                    $t9,                        1                   # $t9 = $t9 + 1 = increment kernel column index
    j       kernel_col_loop

next_kernel_row:
    
    addi    $t8,                    $t8,                        1                   # $t8 = $t8 + 1 = increment kernel row index
    j       kernel_row_loop

save_output:

    # Functionality: Round the convolution sum

    lwc1    $f4,                    scale_factor                                    # $f4 = scale factor (10.0)
    lwc1    $f6,                    round_value                                     # $f6 = round value (0.01)
    lwc1    $f7,                    zero_value                                      # $f7 = zero value (0.0)
    c.lt.s  $f0,                    $f7                                             # If $f0 < 0.0, jump to negative
    bc1t    negative
    j       rounding

negative:

    neg.s   $f6,                    $f6                                             # $f6 = -0.01

rounding:

    mul.s   $f0,                    $f0,                        $f4                 # $f0 = $f0 * 10.0 = scale the value
    add.s   $f0,                    $f0,                        $f6                 # $f0 = $f0 +/- 0.01 = adjust the value
    round.w.s $f5 $f0                                                               # $f5 = integer($f0)
    cvt.s.w $f5,                    $f5                                             # $f5 = float($f5)
    div.s   $f0,                    $f5,                        $f4                 # $f0 = $f5 / 10.0 = scale the value back

    lwc1    $f6,                    round_value                                     # $f6 = round value (0.01)

    # Functionality: Store the rounded result in the output matrix

    mul     $s3,                    $t6,                        $t5                 # $s3 = $t6 * $t5 = row index
    add     $s3,                    $s3,                        $t7                 # $s3 = $s3 + $t7 = column index
    sll     $s3,                    $s3,                        2                   # $s3 = $s3 << 2 = word align the address
    swc1    $f0,                    out($s3)                                        # Store the rounded result in the output matrix

    addi    $t7,                    $t7,                        1                   # $t7 = $t7 + 1 = increment column index
    j       col_loop

next_row:
    
    addi    $t6,                    $t6,                        1                   # $t6 = $t6 + 1 = increment row index
    j       convolution_row_loop

end_process:
    jr      $ra

    ########################################################################################################################
    # Functionality: Error message for file opening error
    # Arguments: None
    # Return: Error message
    # Status: Finished

Error_Input:
    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    error_input                                     # $a0 = address of the error message
    syscall
    j       Exit

    ########################################################################################################################
    # Functionality: Error message for file opening error
    # Arguments: None
    # Return: Error message
    # Status: Finished

Error_Output:
    li      $v0,                    4                                               # syscall for printing string
    la      $a0,                    error_output                                    # $a0 = address of the error message
    syscall
    j       Exit

    ########################################################################################################################
    # Functionality: Error message for size mismatch
    # Arguments: None
    # Return: Error message
    # Status: Finished

Error_size:

    # Functionality: Open the output file (output_matrix.txt) (Finished)

    li      $v0,                    13                                              # syscall for opening a file
    la      $a0,                    output_filename                                 # $a0 = address of the output filename
    li      $a1,                    1                                               # $a1 = 1 = write mode
    li      $a2,                    0
    syscall
    move    $s0,                    $v0                                             # $s0 = file descriptor

    # Functionality: Check for file opening error (Finished)

    bltz    $s0,                    Error_Output                                    # If $s0 < 0, print error message

    li      $v0,                    15                                              # syscall for writing to a file
    move    $a0,                    $s0                                             # $a0 = file descriptor
    la      $a1,                    error_size                                      # $a1 = address of the error message
    la      $a2,                    21                                              # $a2 = 21 = length of the error message
    syscall
    j       Exit

    ########################################################################################################################
    # Functionality: Convert a string of characters to a floating-point number
    # Arguments: $t0 = address of the string
    # Return: Floating-point number in $f0
    # Status: Finished

floating_point_number:

    li      $t5,                    0                                               # $t5 = 0 = Integer part accumulator
    li      $t6,                    0                                               # $t6 = 0 = Fractional part accumulator
    li      $t7,                    1                                               # $t7 = 1 = Divisor
    li      $t8,                    0                                               # $t8 = 0 = Flag to indicate integer part
    li      $s0,                    0                                               # $s0 = 0 = Flag to indicate negative number

convert_character_loop:

    lb      $t9,                    0($t0)                                          # $t9 = current character in the string
    addi    $t0,                    $t0,                        1                   # $t0 = $t0 + 1 = move to the next character
    beq     $t9,                    0,                          end_convert         # If $t9 == null, end of string
    beq     $t9,                    32,                         end_convert         # If $t9 == ' ', end of number
    beq     $t9,                    13,                         end_convert         # If $t9 == '\r', end of number
    beq     $t9,                    46,                         fraction_part       # If $t9 == '.', start of fractional part
    beq     $t9,                    '-',                        negative_part       # If $t9 == '-', start of negative number

    sub     $t9,                    $t9,                        '0'                 # $t9 = $t9 - '0' = convert ASCII to integer
    beq     $t8,                    0,                          integer_part        # If $t8 == 0, start of integer part

    mul     $t6,                    $t6,                        10                  # $t6 = $t6 * 10 = fractional accumulator
    add     $t6,                    $t6,                        $t9                 # $t6 = $t6 + digit = fractional accumulator + digit
    mul     $t7,                    $t7,                        10                  # $t7 = $t7 * 10 = divisor
    j       convert_character_loop                                                  # Continue to next character

integer_part:

    mul     $t5,                    $t5,                        10                  # $t5 = $t5 * 10 = integer accumulator
    add     $t5,                    $t5,                        $t9                 # $t5 = $t5 + digit = integer accumulator + digit
    j       convert_character_loop                                                  # Continue to next character

fraction_part:

    li      $t8,                    1                                               # $t8 = 1 = Flag to indicate fractional part
    j       convert_character_loop

negative_part:

    li      $s0,                    1                                               # $s0 = 1 = Flag to indicate negative number
    j       convert_character_loop
end_convert:
    
    # Functionality: Combine integer and fractional parts

    mtc1    $t5,                    $f0                                             # $f0 = integer accumulator
    cvt.s.w $f0,                    $f0                                             # $f0 = float($f0) = integer part

    mtc1    $t6,                    $f1                                             # $f1 = fractional accumulator
    cvt.s.w $f1,                    $f1                                             # $f1 = float($f1) = fractional part

    mtc1    $t7,                    $f2                                             # $f2 = divisor
    cvt.s.w $f2,                    $f2                                             # $f2 = float($f2) = divisor

    div.s   $f1,                    $f1,                        $f2                 # $f1 = $f1 / $f2 = fractional part / divisor

combine_parts:

    add.s   $f0,                    $f0,                        $f1                 # $f0 = $f0 + $f1 = integer part + fractional part
    beqz    $s0,                    end_floating_point_number                       # If not negative, end the conversion
    neg.s   $f0,                    $f0                                             # $f0 = -($f0) = negative number

end_floating_point_number:
    jr      $ra                                                                     

    ########################################################################################################################

    # Functionality: Convert the floating-point number to a string
    # Arguments: $f12 = floating-point number
    # Return: $a0 = address of the string
    # Status: Finished

float_to_string:

    la      $a0,                    float_string                                    # $a0 = address of the string
    li      $t0,                    0                                               # $t0 = 0 = counter for string length

    # Handle negative numbers
    mfc1    $t1,                    $f12                                            # $t1 = floating-point number as integer
    bltz    $t1,                    handle_negative                                 # If $t1 < 0, handle negative number

process_float:

    # Functionality: Truncate the floating-point number to integer part

    trunc.w.s $f1 $f12                                                              # $f1 = truncate($f12) = integer part
    mfc1    $t1,                    $f1                                             # $t1 = integer part

    # Functionality: Convert the integer part to a string

convert_integer:
    beq     $t1,                    $zero,                      handle_zero         # If $t1 == 0, handle zero
    la      $a1,                    temp_buffer                                     # $a1 = address of the temp buffer
    li      $t2,                    0                                               # $t2 = 0 = counter for temp buffer

integer_loop:

    divu    $t3,                    $t1,                        10                  # $t3 = $t1 / 10 = quotient
    mfhi    $t4                                                                     # $t4 = $t1 % 10 = remainder
    addi    $t4,                    $t4,                        48                  # $t4 = $t4 + '0' = ASCII digit
    sb      $t4,                    0($a1)                                          # Store the digit in temp buffer
    addi    $a1,                    $a1,                        1                   # $a1 = $a1 + 1 = move to the next buffer position
    mflo    $t1                                                                     # $t1 = $t3 = quotient
    bnez    $t1,                    integer_loop                                    # If $t1 != 0, repeat for the next digit

    # Functionality: Reverse the integer part string

    la      $t5,                    temp_buffer                                     # $t5 = address of the temp buffer
    sub     $t6,                    $a1,                        $t5                 # $t6 = $a1 - $t5 = length of the integer part string

reverse_integer:

    addi    $t6,                    $t6,                        -1                  # $t6 = $t6 - 1
    subi    $a1,                    $a1,                        1                   # $a1 = $a1 - 1
    lb      $t3,                    0($a1)                                          # $t3 = current character in the temp buffer
    sb      $t3,                    0($a0)                                          # Store the character in the main buffer
    addi    $a0,                    $a0,                        1                   # $a0 = $a0 + 1 = move to the next buffer position
    bnez    $t6,                    reverse_integer                                 # If $t6 != 0, repeat for the next character

    # Functionality: Append decimal point to the string

fraction:

    li      $t4,                    '.'                                             # $t4 = '.'
    sb      $t4,                    0($a0)                                          # Store the decimal point in main buffer
    addi    $a0,                    $a0,                        1                   # $a0 = $a0 + 1 = move to the next buffer position

    # Functionality: Convert the fractional part to a string

    sub.s   $f12,                   $f12,                       $f1                 # $f12 = $f12 - $f1 = fractional part
    l.s     $f2,                    scale_factor                                    # $f2 = 10.0 = scale factor
    mul.s   $f12,                   $f12,                       $f2                 # $f12 = $f12 * $f2 = fractional part * scale factor = fractional part * 10.0

    trunc.w.s $f1 $f12                                                              # $f1 = truncate($f12) = integer part of the fractional part
    mfc1    $t1,                    $f1                                             # $t1 = integer part of the fractional part
    divu    $t1,                    $t1,                        10
    mfhi    $t1

    # Functionality: Convert the fractional part to a string

    addi    $t1,                    $t1,                        48                  # $t1 = $t1 + '0' = ASCII digit
    sb      $t1,                    0($a0)                                          # Store digit in main buffer
    addi    $a0,                    $a0,                        1                   # $a0 = $a0 + 1 = move to the next buffer position

    # Null-terminate the string
    sb      $zero,                  0($a0)                                          # Null-terminate the string
    la      $a0,                    float_string                                    # $a0 = address of the string
    jr      $ra                                                                     # Return

handle_negative:

    li      $t3,                    '-'                                             # $t3 = '-'
    sb      $t3,                    0($a0)                                          # Store the negative sign in main buffer
    addi    $a0,                    $a0,                        1                   # Move to the next buffer position
    neg.s   $f12,                   $f12                                            # $f12 = -($f12) = positive number
    j       process_float                                                           # Continue processing

handle_zero:

    li      $t3,                    '0'                                             # $t3 = '0'
    sb      $t3,                    0($a0)                                          # Store '0' in main buffer
    addi    $a0,                    $a0,                        1                   # Move to the next buffer position
    j       fraction                                                                # Continue processing