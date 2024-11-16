
.data
image:              .space  196                                                 # Image matrix (7x7 floating-point)
kernel:             .space  64                                                  # Kernel matrix (max 4x4 floating-point)
padded_image:       .space  900                                                 # Padded image matrix (15x15 floating-point)
out:                .space  196                                                 # Output matrix (7x7 floating-point)
newline:            .asciiz "\n"                                                # Newline character
buffer:             .space  1024                                                # Buffer
input_filename:     .asciiz "input_matrix.txt"                                  # Input filename
output_filename:    .asciiz "output_matrix.txt"                                 # Output filename
error_input:        .asciiz "Unable to open the input file"
error_output:       .asciiz "Unable to open the input file"
error_size:         .asciiz "Error: size not match"
image_message: .asciiz "Image: "
kernel_message: .asciiz "Kernel: "
padded_image_message: .asciiz "Padded Image: " 
result_message: .asciiz "\nResult: " 
N:                  .word   0
M:                  .word   0
padding:            .word   0
stride:             .word   0
temp_buffer:    .space 32
float_string:       .space  32
scale_factor:       .float  10.0
half_value:         .float 0.5
zero_value:         .float 0.0
space:              .asciiz " "
    ########################################################################################################################
.text
main:
    ########################################################################################################################
    # Step 1: Open the input file (input_matrix.txt) (Finished)

    li      $v0,                    13
    la      $a0,                    input_filename
    li      $a1,                    0
    li      $a2,                    0
    syscall
    move    $s0,                    $v0                                         # $s0 = file descriptor

    ########################################################################################################################
    # Step 2: Check for file opening error (Finished)

    bltz    $s0,                    Error_Input

    ########################################################################################################################
    # Step 3: Read the input file (input_matrix.txt) (Finished)

    li      $v0,                    14
    move    $a0,                    $s0
    la      $a1,                    buffer
    li      $a2,                    1024
    syscall

    ########################################################################################################################
    # Step 4: Read the first line of the input buffer (Finished)

    la      $t0,                    buffer
    jal     parse_first_line

    ########################################################################################################################
    # Step 5: Check if size matches (Finished)

    lw      $t0,                    N
    lw      $t1,                    M
    lw      $t2,                    padding
    add     $t2,                    $t2,                $t2                     # $t2 = 2 * padding
    add     $t0,                    $t0,                $t2                     # $t0 = N + 2 * padding
    blt     $t0,                    $t1,                Error_size              # If N + 2 * padding < M, print error message

    ########################################################################################################################
    # Step 6: Read image matrix and store in `image` (Finished)

read_image_matrix:
    li      $v0,            4
    la      $a0,            image_message
    syscall
    la      $t0,                    buffer
    addi    $t0,                    $t0,                17

    ####
    la      $t1,                    image                                       # $t1 = address of the image matrix
    lw      $t2,                    N                                           # $t2 = N
    mul     $t2,                    $t2,                $t2                     # $t2 = N * N
    li      $t3,                    0                                           # $t3 = 0 (counter for image matrix elements)

parse_image_loop:

    # Functionality: Check if all elements have been parsed

    bge     $t3,                    $t2,                end_parse_image

    # Functionality: Parse the next element in the buffer

    jal     floating_point_number
    swc1    $f0,                    0($t1)                                      # Store the parsed number in the image matrix

    # Test print
    li      $v0,                    2                                           # syscall for printing double
    mov.d   $f12,                   $f0                                         # move x2 to $f12 for printing
    syscall

    li      $v0,                    4
    la      $a0,                    space
    syscall
    #

    # Functionality: Move to the next element in the image matrix

    addi    $t1,                    $t1,                4
    addi    $t3,                    $t3,                1
    j       parse_image_loop
end_parse_image:
    addi    $t0,                    $t0,                1                       # skip newline

###############
   li      $v0,                    4
    la      $a0,                    newline
    syscall

    ########################################################################################################################
    # Step 7: Read kernel matrix and store in `kernel` (Finished)

read_kernel_matrix:
   li      $v0,            4
    la      $a0,           kernel_message
    syscall
    la      $t1,                    kernel                                      # $t1 = address of the kernel matrix
    lw      $t2,                    M                                           # $t2 = M
    mul     $t2,                    $t2,                $t2                     # $t2 = M * M
    li      $t3,                    0                                           # $t3 = 0 (counter for kernel matrix elements)

parse_kernel_loop:

    # Functionality: Check if all elements have been parsed

    bge     $t3,                    $t2,                end_parse_kernel

    # Functionality: Parse the next element in the buffer

    jal     floating_point_number
    swc1    $f0,                    0($t1)                                      # Store the parsed number in the kernel matrix

    # Test print
    li      $v0,                    2                                           # syscall for printing double
    mov.d   $f12,                   $f0                                         # move x2 to $f12 for printing
    syscall

    li      $v0,                    4
    la      $a0,                    space
    syscall
    #

    # Functionality: Move to the next element in the kernel matrix

    addi    $t1,                    $t1,                4
    addi    $t3,                    $t3,                1
    j       parse_kernel_loop

end_parse_kernel:
###############
   li      $v0,                    4
    la      $a0,                    newline
    syscall
    ########################################################################################################################
    # Step 8: Pad the image matrix with zeros (Unfinished)

padding_image:
   li $v0, 4
la $a0, padded_image_message
syscall
    lw      $t0,                    N                                           # $t0 = N
    lw      $t1,                    padding                                     # $t1 = padding

    # Calculate the size of the padded image
    add     $t2,                    $t0,                $t1                     # $t2 = $t0 + $t1 = N + padding
    move    $s7                  $t2
    add     $t2,                    $t2,                $t1                     # $t2 = $t2 + $t1 = N + padding * 2

    # Initialize pointers
    la      $t3,                    image                                       # $t3 points to the original image
    la      $t4,                    padded_image                                # $t4 points to the padded image
    
    ########################################################################################################################

    # Initialize row counter
    li      $t5,                    0                                           # $t5 = row counter

row_loop:
    li      $t6,                    0                                           # Reset column counter

column_loop:
    # Check if we are in the padding area (row)
    blt     $t5,                    $t1,                pad_pixel               # If row < padding
    bge     $t5,                    $s7,                pad_pixel               # If row >= N + padding

    # Check if we are in the padding area (column)
    blt     $t6,                    $t1,                pad_pixel               # If column < padding
    bge     $t6,                    $s7,                pad_pixel               # If column >= N + padding

    # Otherwise, copy the original image pixel
    sub     $t7,                    $t5,                $t1                     # $t7 = $t5 - $t1 = row - padding
    mul     $t7,                    $t7,                $t0                     # $t7 = $t7 * $t0 = (row - padding) * N
    sub     $t8,                    $t6,                $t1                     # $t8 = $t6 - $t1 = column - padding
    add     $t7,                    $t7,                $t8                     # $t7 = $t7 + $t8 = (row - padding) * N + (column - padding)
    sll     $t7,                    $t7,                2                       # $t7 = $t7 << 2 = 4 * ((row - padding) * N + (column - padding))
    add     $t7, $t3, $t7           # $t7 = address of the original image pixel
    lwc1    $f0, 0($t7)             # Load the original image pixel (float)
    swc1    $f0, 0($t4)             # Store it in the padded image (float)
    # Test print
    li      $v0,                    2                                           # syscall for printing double
    mov.s   $f12,                   $f0                                         # move x2 to $f12 for printing
    syscall

    li      $v0,                    4
    la      $a0,                    space
    syscall
    #
    j       next_pixel

pad_pixel:
   li $t9, 0
   mtc1 $t9, $f0
    cvt.s.w $f0, $f0
    swc1      $f0,                    0($t4)                                      # Store it in the padded image
    # Test print
    li      $v0,                    2                                           # syscall for printing double
    mov.s   $f12,                   $f0                                         # move x2 to $f12 for printing
    syscall

    li      $v0,                    4
    la      $a0,                    space
    syscall
    #
next_pixel:
    addi    $t6,                    $t6,                1                       # Increment column counter
    addi    $t4,                    $t4,                4                       # Move the padded image pointer
    bne     $t6,                    $t2,                column_loop             # Check if end of row

    addi    $t5,                    $t5,                1                       # Increment row counter
    bne     $t5,                    $t2,                row_loop                # Check if end of image

    ########################################################################################################################
    # Step 9: Convolution operation (Unfinished)

    jal     convolution_process

    ########################################################################################################################
    # Step 10: Print output result to terminal and output_matrix.txt (Unfinished)
    
output_result:
    lw      $t0,                    N                                           # $t0 = N
    lw      $t1,                    M                                           # $t1 = M
    lw      $t2,                    padding                                     # $t2 = padding
    lw      $t3,                    stride                                      # $t3 = stride

    add     $t4,                    $t2,                $t2                     # $t4 = 2 * padding
    add     $t5,                    $t0,                $t4                     # $t5 = N + 2 * padding
    sub     $t5,                    $t5,                $t1                     # $t5 = N + 2 * padding - M

    div     $t5,                    $t3
    mflo    $t5                                                                 # $t5 = (N + 2 * padding - M) / s

    addi    $s1,                    $t5,                1                       # $s1 = (N + 2 * padding - M) / s + 1
    mul     $s1,                    $s1,                $s1                     # $t5 = ((N + 2 * padding - M) / s + 1) ^ 2 = output_matrix_size

    # Functionality: Open the output file (output_matrix.txt) (Finished)

    li      $v0,                    13
    la      $a0,                    output_filename
    li      $a1,                    1
    li      $a2,                    0
    syscall
    move    $s0,                    $v0                                         # $s0 = file descriptor

    # Functionality: Check for file opening error (Finished)

    bltz    $s0,                    Error_Output

    # Functionality: Print the output matrix to the output file (output_matrix.txt)
    # Arguments: out, output_matrix_size
    # Return: Output matrix in the output file
    # Status: Finished

    la      $s2,                    out
    li      $s3,                    0                                           # Counter for output matrix elements
   li      $v0,            4
    la      $a0,            result_message
    syscall
write_loop:
    bge     $s3,                    $s1,                close_file              # If loop counter reaches size, end loop

    # Functionality: Print the next element in the output matrix

    l.s    $f12,                   0($s2)                                       # $f12 = next element in the output matrix
    addiu   $s2,                    $s2,                4                       # Move to the next element in the output matrix

    # Functionality: Write the element to the output file

    jal     float_to_string

    la      $s4, float_string  # $s4 = address of the float_string
    li      $s5, 0             # $s5 = 0 = counter for the float_string

count_length:
    lb      $t0, 0($s4)       # Current byte in the string
    beq     $t0, $zero, end_count  # If null terminator, end counting
    addi    $s4, $s4, 1        # $s4 = $s4 + 1 = move to the next byte
    addi    $s5, $s5, 1        # $s5 = $s5 + 1 = increment counter
    j       count_length
end_count:

    li      $v0,                    15
    move    $a0,                    $s0                                         # $s0 = file descriptor
    la      $a1,                    float_string
    move    $a2,                    $s5                                         # $a2 = length of the float_string 
    syscall
    
    # Test
    li $v0, 4
la $a0, float_string
syscall
li $v0, 4
la $a0, space
syscall
    #
    

    # Functionality: Increment the loop counter and print space if not the last element

    addi    $s3,                    $s3,                1                       # $t2 = $t2 + 1
    blt     $s3,                    $s1,                print_space             # If not the last element, print space
    j       write_loop

print_space:
    move      $a0,                    $s0                       # $a0 = file descriptor
    la      $a1,                    space
    la      $a2,                    1
    li      $v0,                    15
    syscall
    j       write_loop

    # Functionality: Close the output file

close_file:
    li      $v0,                    16
    move    $a0,                    $s0
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
    # N (size of input image)
    la      $t1,                    N
    lb      $t2,                    0($t0)
    sub     $t2,                    $t2,                '0'
    sw      $t2,                    0($t1)
    # M (size of kernel)
    la      $t1,                    M
    lb      $t2,                    4($t0)
    sub     $t2,                    $t2,                '0'
    sw      $t2,                    0($t1)
    # padding (padding size)
    la      $t1,                    padding
    lb      $t2,                    8($t0)
    sub     $t2,                    $t2,                '0'
    sw      $t2,                    0($t1)
    # stride (stride size)
    la      $t1,                    stride
    lb      $t2,                    12($t0)
    sub     $t2,                    $t2,                '0'
    sw      $t2,                    0($t1)
    jr      $ra

    ########################################################################################################################
    # Functionality: Convolution operation
    # Arguments: N, M, padding, stride, image, kernel
    # Return: Output matrix
    # Status: Finished

convolution_process:
    lw      $t0, N                  # Load N (original image size)
    lw      $t1, M                  # Load M (kernel size)
    lw      $t2, padding            # Load padding size
    lw      $t3, stride             # Load stride size

    # Calculate padded size: padded_size = N + 2 * padding
    add     $t4, $t0, $t2
    add     $t4, $t4, $t2           # $t4 = padded_size (N + 2 * padding)

    # Calculate output size: output_size = (padded_size - M) / stride + 1
    sub     $t5, $t4, $t1           # $t5 = padded_size - M
    div     $t5, $t5, $t3           # $t5 = (padded_size - M) / stride
    add     $t5, $t5, 1             # $t5 = output_size

    # Initialize indices for the output
    li      $t6, 0                  # Row index of the output

convolution_row_loop:
    bge     $t6, $t5, end_process   # Exit if row index exceeds output size
    li      $t7, 0                  # Column index of the output

col_loop:
    bge     $t7, $t5, next_row      # Exit if column index exceeds output size

    # Initialize convolution sum to 0.0
    mtc1    $zero, $f0              # Set convolution sum to 0.0

    # Loop through the kernel
    li      $t8, 0                  # Kernel row index
kernel_row_loop:
    bge     $t8, $t1, save_output   # Exit if kernel row exceeds M

    li      $t9, 0                  # Kernel column index
kernel_col_loop:
    bge     $t9, $t1, next_kernel_row # Exit if kernel column exceeds M

    # Calculate the corresponding indices in the padded_image
    mul     $s1, $t6, $t3           # Calculate the row offset in the padded image based on stride
    mul     $s2, $t7, $t3           # Calculate the column offset in the padded image based on stride

    add     $s1, $s1, $t8           # Adjust row index by kernel row
    add     $s2, $s2, $t9           # Adjust column index by kernel column

    # Calculate address in the padded image
    mul     $s3, $s1, $t4           # Multiply row index by padded image width (padded_size)
    add     $s3, $s3, $s2           # Add column index
    sll     $s3, $s3, 2             # Word align the address
    lwc1    $f1, padded_image($s3)  # Load the value from the padded image

    # Load kernel value
    mul     $s5, $t8, $t1           # Kernel row offset
    add     $s5, $s5, $t9           # Add kernel column index
    sll     $s5, $s5, 2             # Word align the address
    lwc1    $f2, kernel($s5)        # Load the value from the kernel

    # Perform multiplication and accumulation
    mul.s   $f3, $f1, $f2           # Multiply padded_image and kernel values
    add.s   $f0, $f0, $f3           # Add to the convolution sum

    # Increment kernel column index
    addi    $t9, $t9, 1
    j       kernel_col_loop

next_kernel_row:
    # Increment kernel row index
    addi    $t8, $t8, 1
    j       kernel_row_loop

save_output:
    # Round the convolution sum to 1 decimal place
    lwc1    $f4, scale_factor       # Load scale factor (10.0)
    lwc1    $f6, half_value         # Load half value (0.5)
    lwc1    $f7, zero_value         # Load zero value (0.0)
    c.lt.s  $f0, $f7                # Check if the value is negative
    bc1t negative
    j      rounding

negative:
    neg.s $f6, $f6
rounding:
    mul.s   $f0, $f0, $f4           # Multiply by scale factor
    add.s  $f0, $f0, $f6           # Add half value
    round.w.s $f5, $f0              # Round to the nearest integer
    cvt.s.w $f5, $f5                # Convert back to float
    div.s   $f0, $f5, $f4           # Divide by scale factor

    lwc1    $f6, half_value
    # Store the result in the output array
    mul     $s3, $t6, $t5           # Row offset in output
    add     $s3, $s3, $t7           # Add column index
    sll     $s3, $s3, 2             # Word align
    swc1    $f0, out($s3)           # Store the rounded result

    # Increment output column index
    addi    $t7, $t7, 1
    j       col_loop

next_row:
    # Increment output row index
    addi    $t6, $t6, 1
    j       convolution_row_loop

end_process:
    jr      $ra
      

    ########################################################################################################################
    # Functionality: Error message for file opening error
    # Arguments: None
    # Return: Error message
    # Status: Finished

Error_Input:
    li      $v0,                    4
    la      $a0,                    error_input
    syscall
    j       Exit

    ########################################################################################################################
    # Functionality: Error message for file opening error
    # Arguments: None
    # Return: Error message
    # Status: Finished

Error_Output:
    li      $v0,                    4
    la      $a0,                    error_output
    syscall
    j       Exit

    ########################################################################################################################
    # Functionality: Error message for size mismatch
    # Arguments: None
    # Return: Error message
    # Status: Finished

Error_size:
 # Functionality: Open the output file (output_matrix.txt) (Finished)

    li      $v0,                    13
    la      $a0,                    output_filename
    li      $a1,                    1
    li      $a2,                    0
    syscall
    move    $s0,                    $v0                                         # $s0 = file descriptor

    # Functionality: Check for file opening error (Finished)

    bltz    $s0,                    Error_Output
    
    li      $v0,                    15
    move    $a0, $s0
    la      $a1,                    error_size
    la      $a2,                    21
    syscall
    j       Exit

    ########################################################################################################################
    # Functionality: Convert a string of characters to a floating-point number
    # Arguments: $t0 = address of the string
    # Return: Floating-point number in $f0
    # Status: Unfinished

floating_point_number:

    # Initialize registers
    li      $t5,                    0                                           # Integer part accumulator
    li      $t6,                    0                                           # Fractional part accumulator
    li      $t7,                    1                                           # Fractional divisor (to divide the fraction part)
    li      $t8,                    0                                           # Flag to indicate the fractional part
    li      $s0                    0                                           # Flag to indicate negative number

convert_character_loop:
    lb      $t9,                    0($t0)                                      # Load next character from buffer
    addi    $t0,                    $t0,                1                       # Move buffer pointer to next character
    beq     $t9,                    0,                  end_convert             # If space, number ends here
    beq     $t9,                    32,                 end_convert             # If space, number ends here
    beq     $t9,                    13,                 end_convert             # If  \r, number ends here
    beq     $t9,                    46,                 fraction_part           # If '.', switch to fractional part
    beq     $t9,                    '-'                   negative_part

    # Convert character to integer value
    sub     $t9,                    $t9,                '0'                     # Convert ASCII to integer
    beq     $t8,                    0,                  integer_part            # If in integer part, process as integer

    # Process fractional part
    mul     $t6,                    $t6,                10                      # $t6 = $t6 * 10 = fractional accumulator
    add     $t6,                    $t6,                $t9                     # $t6 = $t6 + digit = fractional accumulator + digit
    mul     $t7,                    $t7,                10                      # $t7 = $t7 * 10 = divisor
    j       convert_character_loop                                              # Continue to next character

integer_part:
    mul     $t5,                    $t5,                10                      # Shift integer accumulator by 10
    add     $t5,                    $t5,                $t9                     # Add digit to integer part
    j       convert_character_loop                                              # Continue to next character

fraction_part:
    li      $t8,                    1                                           # Set flag to indicate fractional part
    j       convert_character_loop
negative_part:
   li       $s0,                   1
   j convert_character_loop
end_convert:
    # Combine integer and fractional parts into a floating-point number
    mtc1    $t5,                    $f0                                         # Move integer part to $f0
    cvt.s.w $f0,                    $f0                                         # Convert integer part to floating-point

    # Divide fractional part by divisor to align it
    mtc1    $t6,                    $f1                                         # Move fractional part to $f1
    cvt.s.w $f1,                    $f1                                         # Convert fractional part to floating-point
    mtc1    $t7,                    $f2                                         # Move divisor to $f2
    cvt.s.w $f2,                    $f2                                         # Convert divisor to floating-point

    div.s   $f1,                    $f1,                $f2                     # Divide fractional part by divisor

combine_parts:
    add.s   $f0,                    $f0,                $f1                     # Add integer and fractional parts
    beqz    $s0,        end_floating_point_number
    neg.s   $f0, $f0
    
end_floating_point_number: 
    jr      $ra                                                                 # Return with result in $f0

    ########################################################################################################################

    # Functionality: Convert the floating-point number to a string
    # Arguments: $f12 = floating-point number
    # Return: $a0 = address of the string
    # Status: ????
float_to_string:
    la      $a0, float_string            # $a0 = address of the string
    li      $t0, 0                       # $t0 = 0 = counter for string length

    # Handle negative numbers
    mfc1    $t1, $f12                    # $t1 = floating-point number as integer
    bltz    $t1, handle_negative         # If $t1 < 0, handle negative number

process_float:
    
    # Functionality: Truncate the floating-point number to integer part

    trunc.w.s $f1, $f12                  # $f1 = truncate($f12) = integer part
    mfc1    $t1, $f1                     # $t1 = integer part

    # Functionality: Convert the integer part to a string

convert_integer:
    beq     $t1, $zero, handle_zero      # If integer part is zero, handle zero
    la      $a1, temp_buffer             # $a1 = address of the temp buffer
    li      $t2, 0                       # $t2 = 0 = counter for temp buffer

integer_loop:

    divu    $t3, $t1, 10                 # $t3 = $t1 / 10 = quotient
    mfhi    $t4                          # $t4 = $t1 % 10 = remainder
    addi    $t4, $t4, 48                 # $t4 = $t4 + '0' = ASCII digit
    sb      $t4, 0($a1)                  # Store digit in temp buffer
    addi    $a1, $a1, 1                  # $a1 = $a1 + 1 = move to the next buffer position
    mflo    $t1                          # $t1 = $t3 = quotient
    bnez    $t1, integer_loop            # If $t1 != 0, repeat for the next digit

    # Functionality: Reverse the integer part string

    la      $t5, temp_buffer             # $t5 = address of the temp buffer
    sub     $t6, $a1, $t5                # $t6 = $a1 - $t5 = length of the integer part string

reverse_integer:
    addi    $t6, $t6, -1                 # $t6 = $t6 - 1
    subi    $a1, $a1, 1                  # $a1 = $a1 - 1
    lb      $t3, 0($a1)                  # Load character from temporary buffer
    sb      $t3, 0($a0)                  # Store character in main buffer
    addi    $a0, $a0, 1                  # $a0 = $a0 + 1 = move to the next buffer position
    bnez    $t6, reverse_integer         # If $t6 != 0, repeat for the next character

    # Functionality: Append decimal point to the string
    #
fraction:
#
    li      $t4, '.'                     # $t4 = '.'
    sb      $t4, 0($a0)                  # Store decimal point in main buffer
    addi    $a0, $a0, 1                  # $a0 = $a0 + 1 = move to the next buffer position

    # Functionality: Convert the fractional part to a string

    sub.s   $f12, $f12, $f1              # $f12 = $f12 - $f1 = fractional part
    l.s     $f2, scale_factor            # $f2 = 10.0 = scale factor
    mul.s   $f12, $f12, $f2              # $f12 = $f12 * $f2 = fractional part * scale factor = fractional part * 10.0
    
    trunc.w.s $f1, $f12                  # $f1 = truncate($f12) = integer part of the fractional part
    mfc1    $t1, $f1                     # $t1 = integer part of the fractional part
    divu $t1, $t1, 10
    mfhi $t1
    # Functionality: Convert the fractional part to a string

    addi    $t1, $t1, 48                 # $t1 = $t1 + '0' = ASCII digit
    sb      $t1, 0($a0)                  # Store digit in main buffer
    addi    $a0, $a0, 1                  # $a0 = $a0 + 1 = move to the next buffer position

    # Null-terminate the string
    sb      $zero, 0($a0)                # Null-terminate the string
    la      $a0, float_string            # $a0 = address of the string
    jr      $ra                          # Return

handle_negative:

    li      $t3, '-'                     # #t3 = '-'
    sb      $t3, 0($a0)                  # Store in main buffer
    addi    $a0, $a0, 1                  # Move forward in main buffer
    neg.s   $f12, $f12                   # $f12 = -$f12
    j       process_float                # Continue processing

handle_zero:

    li      $t3, '0'                     # $t3 = '0'
    sb      $t3, 0($a0)                  # Store in main buffer
    addi    $a0, $a0, 1                  # Move forward in main buffer
    #
    j       fraction                # Continue processing
    #
