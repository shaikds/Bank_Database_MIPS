.data
menu: .asciiz "\nMain Menu:\n1. add_customer\n2. display_customer\n3. update_balance\n4. delete_customer\n5. exit_program\nEnter your choice (1-5): "
invalidChoice: .asciiz "Invalid choice. Please enter a number between 1 and 5.\n"
exitProgram: .asciiz "Exiting program..."
msgEnterID: .asciiz "Enter ID: "
msgEnterName: .asciiz "Enter Name: "
msgEnterBalance: .asciiz "Enter Balance: "
msgEnterNewBalance: .asciiz  "Enter New Balance: "
error: .asciiz "Error: Customer "
error1: .asciiz " already exists\n"
success: .asciiz "Success: Customer "
success1: .asciiz " was added\n"
success2: .asciiz "Success: "
error2: .asciiz "Error: "
deleted: .asciiz " deleted"
newline: .asciiz "\n"
space: .asciiz " "
successDeleteMsg: .asciiz "Success: Customer "
deletedMsg: .asciiz " deleted\n"
errorMsgNotExist: .asciiz "Error:Customer "
notExistMsg: .asciiz " doesn't exist\n"
errorMsgInvalidBalance: .asciiz "Error: The inputted balance isn't valid\n"
comma: .asciiz ","
## -------- ##
## dynamic variables ##
successMsg: .asciiz "Success: Customer was added\n"
.align 2 
idBuffer: .space 4  # Buffer to hold the input ID
.align 2  
balanceBuffer: .space 4  # Buffer to hold the input balance
.align 2  
records_start: .word 0  # Address of the first customer record
.align 2  
num_records: .word 0  # Number of customer records
.align 2  
records_end: .word 0



nameBuffer: .space 101  # Buffer for customer name input
.text
.globl main

main:
    beqz $t9,allocate_new_memory
    # Display menu
    li $v0, 4
    la $a0, menu
    syscall

    # Read user's choice
    li $v0, 5
    syscall
    move $t0, $v0   # Move the input to $t0 for comparison

    # Validate choice
    li $t1, 1       # Lower limit of valid choices
    li $t2, 5       # Upper limit of valid choices
    blt $t0, $t1, invalid_choice
    bgt $t0, $t2, invalid_choice

    # Proceed based on choice
    # Assuming procedures for each option are implemented
    li $t3, 1
    beq $t0, $t3, get_customer_data
    li $t3, 2
    beq $t0, $t3,prepareCustomerInfo
    li $t3, 3
    beq $t0, $t3, prepareUpdate
    li $t3, 4
    beq $t0, $t3, prepareDelete
    li $t3, 5
    beq $t0, $t3, exit_program

    j main         # Loop back to main menu after operation
    
allocate_new_memory:
    # total size needed for one customer: 4 (ID) + 100 (Name) + 4 (Balance) = 108 bytes
    li $a0, 108  # Allocate 108 bytes for a single customer record
    li $v0, 9   # sbrk syscall to allocate memory on the heap
    syscall
    move $t0, $v0  # $t0 now holds the address of the allocated memory block
    li $t9,1
    sw $t0 , records_end
    j main
invalid_choice:
    # Display invalid choice message
    li $v0, 4
    la $a0, invalidChoice
    syscall
    j main         # Return to the main menu
    
    # 2 ----------------
   prepareCustomerInfo:
       # Read user's choice
    li $v0, 4
    la $a0 , msgEnterID
    syscall
    li $v0, 5
    syscall
    move $a3, $v0   # Move the input to $t0 for comparison
    j display_customer
    
    # 3 ------------
    prepareUpdate:
    li $v0,4
    la $a0, msgEnterID
    syscall
    li $v0 ,5
    syscall
    move $a3,$v0 # ID
    li $v0,4
    la $a0, msgEnterNewBalance
    syscall
    li $v0 ,5
    syscall
    move $a2, $v0 # balance
    j update_balance
    
    # 4-----------------
    prepareDelete:
    la $a0, msgEnterID
    syscall
    li $v0,5
    syscall
    move $a0, $v0 # ID
   jal delete_record
    
   
# 1 ----------------
get_customer_data:
    # Input Customer ID
    li $v0, 4
    la $a0, msgEnterID
    syscall
    li $v0, 5
    syscall
    sw $v0, idBuffer # Store ID
    # Input Customer Name
    li $v0, 4
    la $a0, msgEnterName
    syscall
    li $v0, 8
    la $a0, nameBuffer
    li $a1, 100
    syscall

    # Input Customer Balance
    li $v0, 4
    la $a0, msgEnterBalance
    syscall
    li $v0, 5
    syscall
    sw $v0, balanceBuffer 

    lw $v0, idBuffer
    j check_customer_exists
	
check_customer_exists:

    # Load the starting address and number of records
    lw $t4, records_start   # $t4 will hold the current address to check
    lw $t5, num_records     # $t5 will hold the number of records
    bnez $a3, check_only  # If $a3 is not zero, jump to check_only
    # Check if customer ID exists by calling add_customer with a special flag
    lw $a0, idBuffer      # Load ID
    la $a1, nameBuffer    # Placeholder, not used in this check
    li $a2, 0             # Placeholder, not used in this check
    li $a3, 1             # Flag to indicate we're just checking for existence
    jal check_only      # Jump to add_customer, which will return here afterwards

jump_to_main:
    # If ID exists, add_customer will display an error and we return to main menu
    bnez $v1, main
    j add_new_customer

add_new_customer:
    # Prepare arguments for add_customer
    lw $a0, idBuffer      # Load ID
    la $a1, nameBuffer    # Address of the name
    lw $a2, balanceBuffer # Load balance
    li $a3, 0             # Reset flag to indicate full add operation
    jal add_customer      # Call add_customer
    j main                # Return to main menu

check_only:
    # Assume ID is not found initially
    li $v1, 0
     lw $t5 ,num_records
    
    # Start checking loop
    j check_loop

check_loop:
    # Exit loop if no more records to check
    beqz $t5,jump_to_main   # If $t5 is 0, all records have been checked

    # Load the current record's ID
    lw $t6, 0($t4)  # Load the ID at the current address

    # Compare the current record's ID with the input ID
    beq $t6, $v0, id_found  # If they're equal, ID is found

    # Move to the next record if current ID does not match
    addi $t4, $t4, 108  # Move to the next customer record
    addi $t5, $t5, -1   # Decrement the record count
    j check_loop        # Continue checking the next record

id_found:
    # ID is found, set $v1 to 1
    li $v1, 1
        # Display Error message
    li $v0, 4
    la $a0, error
    syscall
	lw $a0, idBuffer    # Move the value from $t9 to $a0, the argument register for syscalls
	li $v0, 1        # Set $v0 to 1 to indicate that you want to print an integer
	syscall 
    li $v0, 4
    la $a0, error1
    syscall
    j jump_to_main

# Stub procedures for each option, to be implemented
# add_customer function
# Arguments:
#   $a0 - ID
#   $a1 - Address of name
#   $a2 - Balance
add_customer:
    # Stack frame setup
    addi $sp, $sp, -32
    sw $ra, 28($sp)
    sw $fp, 24($sp)
    move $fp, $sp
    lw $s5, records_end 
    # Allocate space for a new customer record
    move $t7, $s7
    bnez $s7, continue
    li $v0, 9              # sbrk syscall for memory allocation
    li $a0, 0            # Size for one customer record 
    syscall
    lw $s5, records_end
    beqz $s5, t7_records_end
    move $t7, $v0          # Store the address of the new record in $t7
    t7_records_end:
    la $t2, records_end
    sw $s5, 0($t2)
    j continue
    continue:
    # Check if allocation was successful
    addi $s5, $s5 , 108
    addi $s7,$t7 108
    beqz $t7, allocation_error  # Jump to error handling if allocation failed

        la $t0, records_start  # Load the address of the first record into $t0
    lw $t1, 0($t0)         # Dereference to get the actual starting address of the records

    lw $t2, num_records     # Load the record number into $t2
    

    li $t3, 108            # Load the record size into $t3
    mul $t4, $t2, $t3      # Multiply record_num by 108 to get the offset
    add $t7, $t1, $t4     # Add the offset to the starting address to get the new address
    beqz $t7,load_add
    j continue1
load_add:
    move $t7,$s5
    continue1:
    # Store Customer ID at the beginning of the record
    lw $t1, idBuffer       # Load the customer ID from buffer
    sw $t1, 0($t7)         # Store the ID in the new record
    # Store Customer Name
    la $t2, nameBuffer     # Load the address of the name buffer
    addi $t3, $t7, 4       # Calculate the address for the name within the record
    li $t9, 24            # Assuming name is 100 bytes, we'll move 4 bytes at a time, so we need 25 iterations



store_name_loop:
    lw $t5, 0($t2)         # Load 4 bytes of the name
    sw $t5, 0($t3)         # Store 4 bytes of the name into the record
    addi $t2, $t2, 4       # Move to the next 4 bytes of the name buffer
    addi $t3, $t3, 4       # Move to the next 4 bytes in the record
    addi $t9, $t9, -1      # Decrement the loop counter
    bnez $t9, store_name_loop  # Continue loop until all name bytes are copied

    # Store Customer Balance
    lw $t6, balanceBuffer  # Load the customer balance from buffer
    sw $t6, 104($t7)       # Store the balance at the correct offset

    # Check if this is the first record and update records_start if necessary
    lw $t8, records_start
    beqz $t8, update_start_address  # If records_start is 0, this is the first record
   

continue_adding:
    # Increment the number of records
    lw $t9, num_records
    addi $t9, $t9, 1
   sw $t9, num_records

    # Display success message
    li $v0, 4
    la $a0, success
    syscall
	lw $a0, idBuffer    # Move the value from $t9 to $a0, the argument register for syscalls
	li $v0, 1        # Set $v0 to 1 to indicate that you want to print an integer
	syscall 
    li $v0, 4
    la $a0, success1
    syscall
    li $t9,0
    j end_add_customer  # Jump to the end of add_customer function to clean up and return

update_start_address:
	# Update records_start with the new start address held in $t7
la $t0, records_start   # Load the address of records_start into $t0
sw $t7, 0($t0)          # Store the address in $t7 into records_start

# Now, assuming you want to store the address held in records_end 108 bytes offset from records_start
lw $t1, records_start   # Load the start address from records_start into $t1
la $t2, records_end     # Load the address of records_end label into $t2
sw $s7, 0($t2)        # Store the address of records_end 108 bytes offset from the address in records_start

    j continue_adding      # Continue with adding the record
end_add_customer:
la $s2, records_end
sw $s7, 0($s2)
    # Restore the stack pointer and frame pointer if they were modified
    move $sp, $fp         # Set stack pointer back to frame pointer
    lw $fp, 24($sp)       # Restore the original frame pointer
    lw $ra, 28($sp)       # Restore the return address
    addi $sp, $sp, 32     # Adjust the stack pointer back, assuming 32 bytes were used for the frame

    jr $ra                # Jump back to the return address to continue execution in the caller function

allocation_error:
    j end_add_customer

#------------------------------#

display_customer:

    # Initialize
    lw $s0, records_start  # Load the address of the first record
    lw $s1, num_records    # Load the number of records

search_loop:
    beqz $s1, customer_not_found  # Exit loop if all records have been checked

    # Load the current record's ID
    lw $s2, 0($s0)  # Load the ID at the current address\

    # Compare the current record's ID with the input ID
    beq $s2, $a3, customer_found

    # Move to the next record
    addi $s0, $s0, 108  # Move to the next customer record
    addi $s1, $s1, -1   # Decrement the record count
    j search_loop

customer_found:
    # Print success message
    li $v0, 4
    la $a0, success2
    syscall
  
	
    # Print Customer ID
    move $a0, $s2       # Move the ID to $a0
    li $v0, 1           # Set $v0 to 1 to print an integer
    syscall

    # Print comma
    li $v0, 4
    la $a0, comma
    syscall
    la $a0, space
    syscall
 

    la $a0, 4($s0)  # LOAD NAME ADDRESS
    j find_and_replace_newline2
find_and_replace_newline2:
    lb $t1, 0($a0)        # Load the next byte of the string into $t1
    beqz $t1, print_string2 # If the byte is 0, we've reached the end of the string; go to print
    li $t2, 0x0A          # Load the ASCII value of '\n' into $t2
    bne $t1, $t2, next_char2 # If the current byte is not '\n', continue to the next byte
    sb $zero, 0($a0)      # Replace '\n' with 0 
    j print_string2        # Go to print the string

next_char2:
    addi $a0, $a0, 1      # Move to the next byte in the string
    j find_and_replace_newline2 # Check the next character

print_string2:
    li $v0, 4             # System call for print_string
    syscall               # Print the string


    # Print Customer Name
    addi $a0, $s0, 4    # Calculate the address for the name within the record
    li $v0, 4           # Set $v0 to 4 to print a string
    syscall

    # Print comma
    li $v0, 4
    la $a0, comma
    syscall
   la $a0, space
    syscall

    # Print Customer Balance
    lw $a0, 104($s0)  # Calculate the address for the balance within the record
    li $v0, 1           # Set $v0 to 1 to print an integer
    syscall

    # Print newline
    li $v0, 4
    la $a0, newline
    syscall
    j end_function

customer_not_found:
    # Print error message
    li $v0, 4
    la $a0, error
    syscall
    # Print Customer ID
    move $a0, $a3      # The ID is already in $a0
    li $v0, 1
    syscall   

    # Print not exist message
    li $v0, 4
    la $a0, notExistMsg
    syscall
       la $a0 , newline
    syscall
    j end_function
end_function:
    # Return to caller
    j main
    #------------------------------------#
update_balance:
    # Initialize
    lw $s0, records_start  # Load the address of the first record
    lw $s1, num_records    # Load the number of records
    move $t7,$a3 	   # Sstore new ID in $s2
    move $s3, $a2          # Store new balance in $s3

update_search_loop:
    beqz $s1, update_customer_not_found  # Exit loop if all records have been checked

    # Load the current record's ID
    lw $s2, 0($s0)  # Load the ID at the current address


    # Compare the current record's ID with the input ID
    beq $s2, $t7, validate_balance

    # Move to the next record
    addi $s0, $s0, 108  # Move to the next customer record
    addi $s1, $s1, -1   # Decrement the record count
    j update_search_loop


validate_balance:
    # Check if the new balance is valid
    bltz $s3, update_invalid_balance  # If balance is less than 0
    li $t0, 99999
    bgt $s3, $t0, update_invalid_balance  # If balance is greater than 99999

    # Update the balance
    sw $s3, 104($s0)  # Store the new balance at the correct offset

    # Print success message
    li $v0, 4
    la $a0, success2
    syscall
    # ID
    li $v0, 1
    move $a0, $s2
    syscall
         # Print success message
    li $v0, 4
    la $a0, comma
    syscall
la $a0, space
    syscall
       # Print Customer Name
       la $a0, 4($s0)
    la $t2, nameBuffer  # $t2 points to the start of nameBuffer
    j find_and_replace_newline
find_and_replace_newline:
    lb $t1, 0($a0)        # Load the next byte of the string into $t1
    beqz $t1, print_string # If the byte is 0, we've reached the end of the string; go to print
    li $t2, 0x0A          # Load the ASCII value of '\n' into $t2
    bne $t1, $t2, next_char # If the current byte is not '\n', continue to the next byte
    sb $zero, 0($a0)      # Replace '\n' with 0 
    j print_string        # Go to print the string

next_char:
    addi $a0, $a0, 1      # Move to the next byte in the string
    j find_and_replace_newline # Check the next character

print_string:
    li $v0, 4             # System call for print_string
    syscall               # Print the string

        addi $a0, $s0,4    # Calculate the address for the name within the record
    li $v0, 4           # Set $v0 to 4 to print a string
    syscall
   
     # Print success message
    li $v0, 4
    la $a0, comma
    syscall
  la $a0, space
    syscall
    #" New Balance "
    li $v0 ,1
    move $a0, $s3
    syscall
    li $v0,4
   la $a0 , newline
    syscall
    j end_function

update_invalid_balance:
    # Print error message for invalid balance
    li $v0, 4
    la $a0, errorMsgInvalidBalance
    syscall
    j update_end_function

update_customer_not_found:
    # Print error message for customer not found
    li $v0, 4
    la $a0, error
    syscall
    move $a0, $t7  # The ID is already in $a0
    li $v0, 1
    syscall
    # Print not exist message
    li $v0, 4
    la $a0, notExistMsg
    syscall
    la $a0 , newline
    syscall
update_end_function:
    j main

#------------------------------------------------_#
delete_record:
# delete_customer function
# Arguments:
# $a0 - ID to search for and delete

    # Initialize
    lw $s0, records_start  # Address of the first record
    lw $s1, num_records    # Total number of records
    move $s2, $a0
del_search_loop:
    beqz $s1, del_customer_not_found  # If all records have been checked

    lw $s2, 0($s0)         # Load the ID from the current record
    beq $s2, $a0, del_delete_record  # If the ID matches, go to delete

    # Move to the next record
    addi $s0, $s0, 108     # Advance to the next record
    addi $s1, $s1, -1      # Decrement the remaining record count
    j del_search_loop

del_delete_record:
    addi $t0, $s0, 108     # Address of the next record

shift_records_loop:
    beqz $s1, del_update_records  # If no more records to shift

    lw $t1, 0($t0)         # Load word from the next record
    sw $t1, 0($s0)         # Store it in the current position
    addi $t0, $t0, 4     # Move to the next byte in the source
    addi $s0, $s0, 4     # Move to the next byte in the destination
    li $t5, 104
    
    del_copy_name:
    lb $t1, 0($t0)       # Load 1 byte from the source
    sb $t1, 0($s0)       # Store the byte to the destination

    addi $t0, $t0, 1     # Move to the next byte in the source
    addi $s0, $s0, 1     # Move to the next byte in the destination
    addi $t5,$t5,-1
    bnez $t5, del_copy_name # If the counter hasn't reached 0, continue looping


    addi $t0, $t0, 0    # Advance to the next source record
    addi $s0, $s0, 0     # Advance to the next target position
    addi $s1, $s1, -1      # Decrement the remaining record count
    j shift_records_loop

del_update_records:
    lw $t2, num_records
    addi $t2, $t2, -1      # Decrement the total record count
    sw $t2, num_records

    # Print success message
    li $v0, 4
    la $a0, successDeleteMsg
    syscall

    move $a0, $s2  # ID is already in $a0
    li $v0, 1      # Print ID
    syscall

    li $v0, 4
    la $a0, deletedMsg
    syscall

    j clear_last_record

del_customer_not_found:
    # Print error message
    li $v0, 4
    la $a0, errorMsgNotExist
    syscall

    move $a0, $s2  # ID is already in $a0
    li $v0, 1      # Print ID
    syscall

    li $v0, 4
    la $a0, notExistMsg
    syscall
    j del_end_function

clear_last_record:
    lw $t3, records_start   # Load the start of records
    li $t4, 108             # Size of each record
    mul $t4, $t4, $t2       # Calculate the offset to the last record
    add $t3, $t3, $t4       # $t3 now points to the start of the last record

    li $t5, 27        # Number of word-sized pieces in a record
clear_loop:
    sw $zero, 0($t3)        # Clear a word-sized chunk of the last record
    addi $t3, $t3, 4        # Move to the next word-sized chunk
    addi $t5, $t5, -1       # Decrement the loop counter
    bnez $t5, clear_loop    # Repeat until the entire record is cleared

del_end_function:
    lw $s5, records_start
    la $s6, records_end  # Load the address of records_end into $t1
    lw $t7,records_end


    bgt $t7,$s5, decreaseEndRecords 
    j finish_deletion

      decreaseEndRecords:
    	addi $t7, $t7, -108   # Calculate the new address by subtracting 108 from $s6
    	sw $t7, 0($s6)        # Store the value at the new address
    	j finish_deletion
    	
    finish_deletion:
    li $t9 ,1
    j main  
exit_program:
    li $v0,4
    la $a0, exitProgram
    syscall
    li $v0, 10     # Exit syscall
    syscall
