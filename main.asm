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
N:                  .word   0
M:                  .word   0
padding:            .word   0
stride:             .word   0
temp_buffer:    .space 32
float_string:       .space  32
scale_factor:       .float  10.0
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

    lw      $t0,                    N                                           # $t0 = N
    lw      $t1,                    padding                                     # $t1 = padding

    # Calculate the size of the padded image
    add     $t2,                    $t0,                $t1                     # $t2 = $t0 + padding
    add     $t2,                    $t2,                $t1                     # $t2 = $t2 + padding = N_padded

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
    bge     $t5,                    $t2,                pad_pixel               # If row >= N + padding

    # Check if we are in the padding area (column)
    blt     $t6,                    $t1,                pad_pixel               # If column < padding
    bge     $t6,                    $t2,                pad_pixel               # If column >= N + padding

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
    mov.d   $f12,                   $f0                                         # move x2 to $f12 for printing
    syscall

    li      $v0,                    4
    la      $a0,                    space
    syscall
    #
    j       next_pixel

pad_pixel:
   li $t9, 0
   mtc1 $t0, $f0
    cvt.s.w $f0, $f0
    swc1      $f0,                    0($t4)                                      # Store it in the padded image
    # Test print
    li      $v0,                    2                                           # syscall for printing double
    mov.d   $f12,                   $f0                                         # move x2 to $f12 for printing
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

write_loop:
    bge     $s3,                    $s1,                close_file              # If loop counter reaches size, end loop

    # Functionality: Print the next element in the output matrix

    l.s    $f12,                   0($s2)                                       # $f12 = next element in the output matrix
    addiu   $s2,                    $s2,                4                       # Move to the next element in the output matrix

    # Functionality: Write the element to the output file

    jal     float_to_string
    la      $a1,                    float_string
    li      $v0,                    15
    li      $a2,                    3 
    move    $a0,                    $s0                                         # $s0 = file descriptor
    syscall
    
    # Test
    li $v0, 4
la $a0, float_string
syscall
    #
    

    # Functionality: Increment the loop counter and print space if not the last element

    addi    $s3,                    $s3,                1                       # $t2 = $t2 + 1
    blt     $s3,                    $s1,                print_space             # If not the last element, print space
    j       write_loop

print_space:
    move      $a0,                    $s0                       # $a0 = file descriptor
    la    $a1,                    space
    la    $a2,                    1
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

    # Load N, M, padding, and stride values (Finished)

    lw      $s0,                    N                                           # $s0 = N
    lw      $s1,                    M                                           # $s1 = M
    lw      $s2,                    padding                                     # $s2 = padding
    lw      $s3,                    stride                                      # $s3 = stride

    # Calculate the size of the padded image (N_padded = N + 2 * padding) (Finished)

    add     $s4,                    $s0,                $s2                     # $s4 = N + padding
    add     $s4,                    $s4,                $s2                     # $s4 = N + 2 * padding

    # Initialize pointers to image, kernel, and output matrix (Finished)

    la      $s5,                    padded_image
    la      $s6,                    kernel
    la      $s7,                    out

    # Initialize row start at 0 for each kernel window (Finished)

    li      $t0,                    0                                           # $t0 = 0

    # Outer loop for moving kernel window vertically (Finished)

row:

    # Check if remaining rows are enough for another kernel window

    sub     $t1,                    $s4,                $t0                     # $t1 = $s4 - $t0 = N_padded - row start = remaining rows
    blt     $t1,                    $s1,                end_convolution         # If remaining rows < M, end convolution

    # Initialize column start at 0 for each row

    li      $t2,                    0                                           # $t2 = 0

column:

    # Check if remaining columns are enough for another kernel window

    sub     $t3,                    $s4,                $t2                     # $t3 = $s4 - $t2 = N_padded - column start = remaining columns
    blt     $t3,                    $s1,                next_row                # If remaining columns < M, skip to next row

    # Perform convolution at ($t0, $t2)

    # Initialization

    li      $a2,                    0
    mtc1    $a2,                    $f0
    cvt.s.w $f0,                    $f0                                         # $f0 = 0.0 = current_total

    # Convolution calculation (nested loop over kernel elements)

    li      $t4,                    0                                           # kernel_row_index

convolution_row:

    li      $t5,                    0                                           # kernel_column_index

convolution_column:

    # Functionality: Calculate the address of the current element in the padded image and kernel
    # Arguments: $t0 = row_start, $t2 = column_start, $t4 = kernel_row_index, $t5 = kernel_column_index
    # Return: Address of the current element in the padded image and kernel
    # Status: Finished

    mul     $t6,                    $s4,                $t4                     # $t6 = $s4 * $t4 = N_padded * kernel_row_index (current_row)
    add     $t6,                    $t6,                $t2                     # $t6 = $t6 + $t2 = current_row + column_start (current_column)
    add     $t6,                    $t6,                $t0                     # $t6 = $t6 + $t0 = current_column + row_start (current_element)
    add     $t6,                    $t6,                $t5                     # $t6 = $t6 + $t5 = current_element + kernel_column_index (current_kernel_element)
    sll     $t6,                    $t6,                2                       # $t6 = $t6 << 2 = 4 * current_kernel_element
    add     $t6,                    $s5,                $t6                     # $t6 = $s5 + $t6 = address of the current element in the padded image

    # Functionality: Calculate the address of the current element in the kernel
    # Arguments: $t4 = kernel_row_index, $t5 = kernel_column_index
    # Return: Address of the current element in the kernel
    # Status: Finished

    mul     $t7,                    $t4,                $s1                     # $t7 = $t4 * $s1 = kernel_row_index * M (current_row)
    add     $t7,                    $t7,                $t5                     # $t7 = $t7 + $t5 = current_row + kernel_column_index (current_kernel_element)
    sll     $t7,                    $t7,                2                       # $t7 = $t7 << 2 = 4 * current_kernel_element
    add     $t7,                    $s6,                $t7                     # $t7 = $s6 + $t7 = address of the current element in the kernel

    # Functionality: Load the current element in the padded image and kernel
    # Arguments: $t6 = address of the current element in the padded image, $t7 = address of the current element in the kernel
    # Return: Current element in the padded image and kernel
    # Status: Finished

    lwc1    $f1,                    0($t6)                                      # $f1 = padded_image_element
    lwc1    $f2,                    0($t7)                                      # $f2 = kernel_element

    mul.s   $f3,                    $f1,                $f2                     # $f3 = $f1 * $f2 = padded_image_element * kernel_element
    add.s   $f0,                    $f0,                $f3                     # $f0 = $f0 + $f3 = current_total + padded_image_element * kernel_element

    # Functionality: Move to the next column in the kernel

    addi    $t5,                    $t5,                1
    bne     $t5,                    $s1,                convolution_column      # If kernel_column_index < M, repeat for the next column

    # Functionality: Move to the next row in the kernel

    addi    $t4,                    $t4,                1
    bne     $t4,                    $s1,                convolution_row         # If kernel_row_index < M, repeat for the next row

    # Functionality: Normalize the convolution result by dividing by 10
    # Arguments: $f0 = current_total
    # Return: Normalized convolution result

    li      $t8,                    10                                          # Load 10 into $t8
    mtc1    $t8,                    $f4                                         # $f4 = 10.0
    cvt.s.w $f4,                    $f4                                         # $f4 = 10.0

    mul.s   $f0,                    $f0,                $f4                     # $f0 = $f0 * 10.0 = current_total * 10.0
    round.w.s $f0,                    $f0                                        # $f0 = round($f0) = rounded_current_total
    cvt.s.w $f0,                    $f0                                         # $f0 = (int)rounded_current_total
    div.s   $f0,                    $f0,                $f4                     # $f0 = $f0 / 10.0 = (int)rounded_current_total / 10.0 = normalized_current_total

    # Functionality: Store the normalized convolution result in the output matrix
    # Arguments: $f0 = normalized_current_total
    # Return: Output matrix with the normalized convolution result

    swc1    $f0,                    0($s7)
    
     # Test print
    li      $v0,                    2                                           # syscall for printing double
    mov.d   $f12,                   $f0                                         # move x2 to $f12 for printing
    syscall

    li      $v0,                    4
    la      $a0,                    space
    syscall
    #

    # Functionality: Move the output matrix pointer to the next element

    add     $t2,                    $t2,                $s3
    addi    $s7,                    $s7,                4
    j       column

    # Functionality: Move the image matrix pointer to the next row

next_row:
    add     $t0,                    $t0,                $s3
    j       row

    # Functionality: End of convolution operation

end_convolution:

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
    li      $v0,                    4
    la      $a0,                    error_size
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

convert_character_loop:
    lb      $t9,                    0($t0)                                      # Load next character from buffer
    addi    $t0,                    $t0,                1                       # Move buffer pointer to next character
    beq     $t9,                    0,                  end_convert             # If space, number ends here
    beq     $t9,                    32,                 end_convert             # If space, number ends here
    beq     $t9,                    13,                 end_convert             # If  \r, number ends here
    beq     $t9,                    46,                 fraction_part           # If '.', switch to fractional part

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
    j       process_float                # Continue processing
