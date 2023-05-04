.data 
	#sub array to store only the empty tiles
	empty_tiles: .space 48
	three_side_tiles: .space 48
.text

.globl AI_turn

	
AI_turn:
	#load the address of the board array
	la $t0, board
	la $t3, empty_tiles
	la $t5, three_side_tiles
	
	#counters to keep track of array sizes and indexes
	li $t2, 0
	li $t4, 0
	li $t6, 0
	li $t8, 0
	
#loops through the array and adds all the tiles that aren't captured yet to the array
empty_check:

	#check if the tile is not captured and branch if it isn't
	lb $t1, 0($t0)
	andi $t1, $t1, 0x30 # 110000
	bnez $t1, is_captured
	
	#if it sn't captured, then add it to the sub array
	
	#count the number of sides filled and store in $t8
	andi $t7, $t1, 1
	bnez $t7, right
	addi $t8, $t8, 1
right:
	andi $t7, $t1, 2
	bnez $t7, left
	addi $t8, $t8, 1
left:
	andi $t7, $t1, 4
	bnez $t7, down
	addi $t8, $t8, 1
down:
	andi $t7, $t1, 8
	bnez $t7, up
	addi $t8, $t8, 1
up:
	#branch if there are less than 3 sides
	bne $t8, 3, less_sides
	sb $t2, 0($t5)
	addi $t6, $t6, 1
	addi $t5, $t5, 1
	j is_captured
	
less_sides:
	sb $t2, 0($t3)
	addi $t4, $t4, 1
	addi $t3, $t3, 1
	
is_captured:
	
	#check if it is about to go out of bounds of the array
	addi $t2, $t2, 1
	beq  $t2, 48, done_loop
	
	addi $t0, $t0, 1
	j empty_check
	
done_loop:
	#reset the address pointer of the empty array
	la $t3, empty_tiles
	
	#if there is at least one tile with 3 sides filled use that array instead
	beqz $t6, less_three_setup
	la $t3, three_side_tiles
	li $t8, 1
	
	#Generate a random number to randomly select a tile
	li $v0, 42 
	move $a1, $t6		# Set upper bound to number of empty tiles
	syscall     		# generated number will be at $a0
	
	j sub_loop
	
less_three_setup:	
	li $t8, 0
	#Generate a random number to randomly select a tile
	li $v0, 42 
	move $a1, $t4	# Set upper bound to number of empty tiles
	syscall     	#generated number will be at $a0
	
#traverse the loop to get to the index of empty tile
sub_loop:
	beq $a0, 0, sub_loop_done
	addi $t3, $t3, 1
	addi $a0, $a0, -1
	
	j sub_loop
	
sub_loop_done:
	
	#load the index of the empty tile to t1
	lb $t1, ($t3)
	la $t0, board
	#t5 will contain the index of the tile
	move $t5, $t1
	
#loops through the board to get to the empty tile
sub_loop_two:
	beq $t1, 0, sub_loop_two_done
	addi $t0, $t0, 1
	addi $t1, $t1, -1
	
	j sub_loop_two

sub_loop_two_done:

	#gets the tile from board
	lb $t1, 0($t0)
	
	#randomly select an empty side of the tile to fill in
	
side_loop:
	#Generate a random number to randomly select a tile
	li $v0, 42 
	li $a1, 4 # Set upper bound to number of sides
	syscall
	move $t9, $a0
	
	#t3 will contain the mask or selected bit of the side
	li $t3, 1
	
#shift t3 a random amount of times to get a random side
	j shift_loop
shifted:
	#if the randomly selected side is already filled then try again
	and $t4, $t1, $t3
	bnez $t4, side_loop
	
	#depending on what side it is, get the indicies of the dots connecting it
	beq $t9, 0, set_top
	beq $t9, 1, set_bottom
	beq $t9, 2, set_left
	beq $t9, 3, set_right
	
found_where:
	
	#store the ra
	subi $sp, $sp, 8
	sw $ra, ($sp)
	sw $t8, 4($sp)
	
	#call the function from board to set the line
	jal set_line_between
	
	lw $t8, 4($sp)
	lw $ra, ($sp)
	addi $sp, $sp, 8
	
	#check if tile is meant to be captured, jump to exit
	bne $t8, 1, exit
	
	#AI gets another turn if it captures a tile
	j AI_turn
	
exit:
	jr $ra
	
#shifts the number left x amount of times
shift_loop:
	beq $a0, 0, shifted
	sll $t3, $t3, 1
	addi $a0, $a0, -1

	j shift_loop
	
	
set_top:
    li $t6, 8
    div $t5, $t6
    mfhi $a0
    mflo $a1

    addi $a2, $a0, 1
    move $a3, $a1

    j found_where

set_left:
    li $t6, 8
    div $t5, $t6
    mfhi $a0
    mflo $a1

    move $a2, $a0
    addi $a3, $a1, 1
    j found_where

set_right:
    li $t6, 8
    div $t5, $t6
    mfhi $a0
    mflo $a1

    addi $a0, $a0, 1
    addi $a2, $a0, 2
    move $a3, $a1
    j found_where

set_bottom:
    li $t6, 8
    div $t5, $t6
    mfhi $a0
    mflo $a1

    addi $a1, $a1, 1
    move $a2, $a0
    addi $a3, $a1, 1
    j found_where
