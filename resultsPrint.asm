.data
	#prints game results
	player_win: .asciiz "Player won with this amount of tiles >>> "
	computer_win: .asciiz "AI won with this amount of tiles >>> "
	tie_msg: .asciiz "The player has tied with the AI"
	
.text

li $s0, 8
li $s1, 6

jal draw_board
game_loop:

	#call main fron userInput to do the player's turn
	li $s2, 1
	jal user_input
	li $s2, 0
	jal AI_turn
	jal draw_board
	
	#call the board's count function
	jal count_captures
	add $t2, $v0, $v1
	#t0 contains the player tiles and t1 contains the computer tiles
	move $t0, $v0
	move $t1, $v1
   	li $t3, 48   # Load total number of boxes
   	
   	
   	beq $t2, $t3, end_game   # Check if all boxes have been captured
	j game_loop
	
end_game:

	#check if a tie, player win, or AI win
	beq $t0, $t1, tie
	slt $t5, $t0, $t1
	beq $t5, 1, player1_wins
	j player2_wins

player1_wins:
    	li $v0, 4   # Print string syscall
    	la $a0, player_win
    	syscall
    	
    	move $a0, $t0   # Load number of boxes captured by player 1 into argument register
    	li $v0, 1   # Print integer syscall
    	syscall

    	j end

player2_wins:
    	li $v0, 4   # Print string syscall
    	la $a0, computer_win
    	syscall
    	
    	move $a0, $t1  # Load number of boxes captured by player 2 into argument register
    	li $v0, 1   # Print integer syscall
    	syscall

    	j end
tie:
	li $v0, 4   # Print string syscall
    	la $a0, tie_msg
    	syscall
    	j end

end:
    	li $v0, 10   # Exit syscall
    	syscall
