    .data

board: .space 48

ALLOCATION_SHIELD: .space 1024

dotstr: .asciiz " . "
hdash: .asciiz "--"
halfspacer: .asciiz "  "

ALLOCATION_SHIELD2: .space 1024

    .text
    .globl board    
    .globl draw_board
    .globl get_capture_char
	.globl set_line_between
	.globl count_captures
	.globl is_line_placed

### TEMP REGISTERS FOR draw_board:
## $t0 : Array indexer
## $t1 : Horizontal Line counter
## $t2 : Vertical Height (NOT the same as tile height)
## $t4 : Vertical Line counter
## $t5/6/7/8: Temps

draw_board:


	# save return address
    subi $sp, $sp, 4
    sw $ra, ($sp)
    
	jal print_abcs

	# $s0 contains width
	# $s1 contains height

	li $t0, 0 # Array indexer
	li $t1, 0 # Horizontal line counter
	li $t4, 0 # Vertical line counter

	# number of total rows drawn (tiles + dots)
	mul $t2, $s1, 2
	addi $t2, $t2, 1
	
	# Hardcoded zero at the beginning
	li $v0, 1
	li $a0, 0
	syscall

db_dot_row:
    li $v0, 4 # print char
    la $a0, dotstr
    syscall
    
    # GET LINE LEFT->RIGHT from below tile
    add $t5, $t0, $t1 # Get address of below tile
    subi $t6, $t2, 1
    bne $t4, $t6, db_horiz_skip_edgecase # check if last row
    
    # EDGE CASE
    sub $t5, $t5, $s0 # subtract row size to get tile above
    lb $t5, board($t5)
    andi $t5, $t5, 4 # 0100
    beqz $t5, db_draw_horiz_blank
    j db_draw_horiz_dash
    
db_horiz_skip_edgecase:
    lb $t5, board($t5)
	andi $t5, $t5, 8 # 1000
	beqz $t5, db_draw_horiz_blank
	
db_draw_horiz_dash:
	# Draw horizontal dash
	li $v0, 4
	la $a0, hdash
	syscall
	
	j db_process_eol
	
db_draw_horiz_blank:
	li $v0, 4
	la $a0, halfspacer
	syscall

    j db_process_eol
    
db_tile_row:

    lb $t7, board($t0)
    move $a0, $t7 # $t7 is used later, I promise
    jal get_capture_char
    move $t6, $v0
    
    # print vert line
    andi $t5, $a0, 0x2 # 0010
    beqz $t5, db_draw_vert_blank
    
    li $v0, 11
    li $a0, 124 # | char
    syscall
    
    j db_end_vert_spacer
db_draw_vert_blank:
	li $v0, 11
	li $a0, 32 # Space
	syscall
	
db_end_vert_spacer:
    
	#li $v0, 11
	li $a0, 32 # Space
	syscall
    
    # print value from get_capture_char function
    move $a0, $t6
    li $v0, 11
    syscall
    
    addi $t0, $t0, 1
    bne $t0, $s0, db_vert_skip_edgecase
    
    # EDGE CASE    
    andi $t7, $t7, 1 # 0001 check for right
    beqz $t7, db_vert_skip_edgecase
    
    li $v0, 4
    la $a0, halfspacer
    syscall

	li $v0, 11
    li $a0, 124
    syscall

    
    j db_process_eol
    
db_vert_skip_edgecase:
    li $v0, 4
	la $a0, halfspacer
	syscall
    
db_process_eol: # checks for end of line, adds newline + other stuff
    # New Lines
    addi $t1, $t1, 1
    
    blt	$t1, $s0, db_skipnewline
    addi $t4, $t4, 1
    andi $t5, $t4, 0x1 # Mask bit for odd numbers
    beqz $t5, db_printnewline
    
    li $v0, 4
    la $a0, dotstr
    syscall
    
db_printnewline:
    li $t1, 0
    li $v0, 11 # print char
    li $a0, 0xA # Newline ascii code
    syscall

    

    beqz $t5, db_printlinenumber
    
    # Align symbols
    li $v0, 4
    la $a0, halfspacer
	syscall
	
	j db_skipnewline
	
db_printlinenumber:
	li $v0, 1
	srl $a0, $t4, 1
	syscall

db_skipnewline:
    andi $t5, $t4, 0x1 # Mask bit for odd numbers
    bge $t4, $t2, db_exit # Loop until all values visited
    
    beqz $t5, db_dot_row
    j db_tile_row
    
    
db_exit:
    
    # RETURN
    lw $t0, ($sp)
    addi $sp, $sp, 4
    jr $t0
# END DRAW FUNCTION


# Function to get the capture symbol for a given tile byte
get_capture_char:
	andi $t8, $a0, 48 # 48 = 0b110000
	beq $t8, 16, bgcc_comp
	beq $t8, 32, bgcc_pl
	
	li $v0, 32 # ' ' space ascii value
	jr $ra
bgcc_comp:
	li $v0, 99 # c ascii value
	jr $ra
bgcc_pl:
	li $v0, 120 # x ascii value
	jr $ra
# END GET_CAPTURE_CHAR FUNCTION


# Print A B C
print_abcs:
	li $t0, 0
	li $t1, 65 # A ascii
	
pabc_loop:
	
	li $v0, 4
	la $a0, halfspacer
	syscall
	
	li $v0, 11
	move $a0, $t1
	syscall
	
	li $v0, 4
	la $a0, halfspacer
	syscall
	
	addi $t1, $t1, 1
	addi $t0, $t0, 1
	ble $t0, $s0, pabc_loop

	# end pabc_loop
	
	# trailing newline
	li $v0, 11
	li $a0, 10
	syscall
	
	jr $ra
# END PRINT_ABC FUNCTION

set_line_between:
	subi $sp, $sp, 4
	sw $ra, ($sp)

	# $a0 : dot 1 x
	# $a1 : dot 1 y
	# $a2 : dot 2 x
	# $a3 : dot 2 y
	
	# assuming input already validated
	beq $a0, $a2, slb_vline # if both x values are the same, the line is vertical

slb_hline:
	# Top address = board offset: (minX + s0 * d1Y)
	# Bottom address = board offset: (maxX + s0 * d1Y)
	move $t0, $a0
	move $t1, $a2
	jal min_t0_t1
	# minX is in $v0
	
	subi $t8, $a1, 1 # align
	subi $v0, $v0, 1 # align

	li $t5, -1
	blt $v0, $t5, slb_hline_s2
	
	mul $t0, $s0, $t8 # s0 * d1Y
	add $t0, $t0, $v0 # + minX

	lb $t1, board($t0)
	ori $t1, $t1, 4 # 0100
	jal internal_t1_check_square
	sb $t1, board($t0)

slb_hline_s2:

	addi $t8, $t8, 1
	bge $t8, $s1, slb_exit 		# USING S1 AS HEIGHT

	add $t0, $t0, $s0

	lb $t1, board($t0)
	ori $t1, $t1, 8 # 1000
	jal internal_t1_check_square
	sb $t1, board($t0)

	j slb_exit
slb_vline:

	# Left address = board offset: (s0 * minY + d1X) - 1
	# Right address = board offset: (s0 * maxY + d1X) - 1

	move $t0, $a1
	move $t1, $a3
	jal min_t0_t1
	# minX is in $v0
	
	subi $v0, $v0, 1
	
	mul $t0, $v0, $s0 # s0 * d1Y
	add $t0, $t0, $a0 # + minX
	subi $t0, $t0, 1 # align
	
	bltz $v0, slb_vline_s2
	
	lb $t1, board($t0)
	ori $t1, $t1, 0x1 # 0001 right
	jal internal_t1_check_square
	sb $t1, board($t0)
	
slb_vline_s2:
	addi $t0, $t0, 1
	beq $v0, $s0, slb_exit
	
	lb $t1, board($t0)
	ori $t1, $t1, 0x2 # 0010 left
	jal internal_t1_check_square
	sb $t1, board($t0)

slb_exit:
	lw $t0, ($sp)
	addi $sp, $sp, 4

	jr $t0

# END SET_LINE_BETWEEN FUNCTION

min_t0_t1: # For internal (set_line_between function) use only /// uses t0 and t1 as argument registers to avoid needing to cache argument registers
	slt $t2, $t0, $t1
	beqz $t2, mt01_t0l

	move $v0, $t1
	jr $ra
mt01_t0l:
	move $v0, $t0
	jr $ra
	
	
internal_t1_check_square: # For internal (set_line_between function) use only // uses $t1 as argument registers to avoid needing to cache argument registers
	bne $t1, 0xF, it1cs_end # 0xF == 0b001111
	
	beqz $s2, it1cs_playertile
	
	# Computer tile:
	ori $t1, $t1, 0x20 # 0x20 == 0b100000
	jr $ra
	
it1cs_playertile:
	# Player tile:
	ori $t1, $t1, 0x10 # 0x10 == 0b010000
it1cs_end:
	jr $ra
	
count_captures:
	mul $t1, $s0, $s1 # Length
	li $t2, 0 # Counter
	
	li $v0, 0 # Player Capture Counter
	li $v1, 0 # Computer Capture Counter
	
cc_loop:
	bge $t2, $t1, cc_end

	lb $t0, board($t2)
	andi $t0, $t0, 0x30 # 0x30 == 0b110000
	
	beq $t0, 0x20, cc_add_player
	beq $t0, 0x10, cc_add_computer
	j cc_loop_end
	
cc_add_player:
	addi $v0, $v0, 1
	j cc_loop_end
cc_add_computer:
	addi $v1, $v1, 1
	
cc_loop_end:
	addi $t2, $t2, 1
	j cc_loop

cc_end:
	jr $ra
# END COUNT_CAPTURES FUNCTION

is_line_placed:
	addi $sp, $sp, -4
	sw	$ra, 0($sp)

	# $a0 : x1
	# $a1 : y1
	# $a2 : x2
	# $a3 : y2

	beq $a0, $a2, ilp_vert

	move $t0, $a1
	move $t1, $a3
	jal min_t0_t1

	subi $v0, $v0, 1

	blt $v0, -1, ilp_horiz_edgecase

	mul $t0, $s0, $v0
	add $t0, $t0, $a0

	lb $t1, board($t0)
	andi $t1, $t1, 4 # 0100

	j ilp_set_valid

ilp_horiz_edgecase:	
	add $t0, $t0, $s0
	lb $t1, board($t0)
	andi $t1, $t1, 8 # 1000

	j ilp_set_valid
ilp_vert:

	move $t0, $a0
	move $t1, $a2
	jal min_t0_t1

	mul $t0, $a1, $s0
	add $t0, $t0, $v0
	subi $t0, $t0, 1

	bltz $v0, ilp_vert_edgecase

	lb $t1, board($t0)
	andi $t1, $t1, 1 # 0001

	j ilp_set_valid
ilp_vert_edgecase:

	addi $t0, $t0, 1
	
	lb $t1, board($t0)
	andi $t1, $t1, 2 # 0010

	j ilp_set_valid

ilp_set_valid:

	# $t1 contains masked value
	seq $v0, $t1, $zero
	beqz $v0, ilp_is_valid

	li $v0, 0

ilp_exit:
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	jr $t0

ilp_is_valid:
	li $v0, 1
	j ilp_exit
