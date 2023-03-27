######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       4
# - Unit height in pixels:      4
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Global Constant Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

# Colors
COLOR_BLACK:
    .word 0x000000
COLOR_GRAY:
    .word 0x808080
COLOR_WHITE:
    .word 0xffffff
COLOR_RED:
    .word 0xff0000
COLOR_ORANGE:
    .word 0xffa500
COLOR_YELLOW:
    .word 0xffff00
COLOR_GREEN:
    .word 0x00ff00
COLOR_PINK:
    .word 0xff69b4

# Constants
SCREEN_WIDTH:
    .word 256
SCREEN_HEIGHT:
    .word 256
PIXEL_COUNT:
    .word 64
BRICK_WIDTH:
    .word 4
BRICK_HEIGHT:
    .word 1
PADDLE_SIZE:
    .word 9
LIVES:
    .word 3

##############################################################################
# Initialization Data
##############################################################################
# Paddle x-coordinate
PADDLE_X:
    .word 26
# Ball x-coordinate
BALL_X:
    .word 1
# Ball y-coordinate
BALL_Y:
    .word 30
# Ball x-velocity
BALL_DX:
    .word -1
# Ball y-velocity
BALL_DY:
    .word 1

##############################################################################
# Code
##############################################################################
	.text
	# Run the Brick Breaker game.

main:
    # Initialize the keyboard
    lw $s7, ADDR_KBRD               # $s7 = base address for keyboard
    
    li $s5, 0 # $s5 is the score
    jal initialize_score
    
    # Draw the borders around the top and sides
    li $a1, 7
    jal draw_border
    
    # Draw red row of bricks
    lw $a0, COLOR_RED
    li $a1, 11
    jal draw_bricks
    
    # Draw red row of bricks
    lw $a0, COLOR_ORANGE
    li $a1, 15
    jal draw_bricks
    
    # Draw yellow row of bricks
    lw $a0, COLOR_YELLOW
    li $a1, 19
    jal draw_bricks
    
    # Draw green row of bricks
    lw $a0, COLOR_GREEN
    li $a1, 23
    jal draw_bricks
    
    # Draw the lives
    lw $s6, LIVES
    jal draw_lives
    
    # Draw the starting place of the paddle
    # Initialize the paddle register data
    li $a0, 61
    jal initialize_paddle
    
    # Draw the starting place of the ball
    # Initialize the ball register data
    jal initialize_ball

game_loop:
    jal paint_black
    jal move_ball
    jal paint_white

    li $v0, 32
	li $a0, 1
	syscall

    lw $t8, 0($s7)                  # Load first word from keyboard
    beq $t8, 1, key_pressed         # If first word 1, key is pressed

    game_loop_paddle:
        jal draw_paddle
        j game_loop
    

#################################################################################
############# GAME HELPER FUNCTIONS FOR THE PADDLE AND BALL MOVEMENT ############
#################################################################################

paint_white:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_WHITE
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $s0 # Multiply the x location by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by BALL_X
    
    sw $t1, ($t0)
    li $v0, 32
    li $a0, 50
    syscall
    jr $ra

paint_black:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_BLACK
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $s0 # Multiply the x location by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by BALL_X
    
    sw $t1, ($t0)
    jr $ra

move_ball:
    addi $sp, $sp, -4    # Make space on stack
    sw $ra, 0($sp)       # Store the main $ra on stack
    
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_BLACK
    lw $t2, COLOR_WHITE
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $s0 # Multiply the x location by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by BALL_X
    
    add $t4, $t0, $t9   # Get position below ball
    sub $t5, $t0, 4   # Get position left of ball
    addi $t6, $t0, 4    # Get position right of ball
    sub $t7, $t0, 256  # Get position above ball
    
    lw $t4, 0($t4) # Get color below ball
    lw $t5, 0($t5) # Get color left of ball
    lw $t6, 0($t6) # Get color right of ball
    lw $t7, 0($t7) # Get color above ball
    
    # Check for collision with border
    beq $s0, 1, change_x
    beq $s0, 62, change_x
    beq $s1, 8, change_y
    
    # Check for collision with paddle
    beq $t2, $t4, change_y      # Check if collides with paddle below
    beq $t2, $t5, change_x      # Check if collides with paddle left
    beq $t2, $t6, change_x      # Check if collides with paddle right
    
    lw $t2, COLOR_RED
    
    # Check for collision with red brick
    beq $t2, $t4, change_y_brick_br
    beq $t2, $t7, change_y_brick_ar
    beq $t2, $t5, change_x_brick_lr
    beq $t2, $t6, change_x_brick_rr
    
    # Check for collision with brick
    bne $t1, $t4, change_y_brick_b      # Check if ball collides below
    bne $t1, $t7, change_y_brick_a      # Check if ball collides above
    bne $t1, $t5, change_x_brick_l      # Check if ball collides left
    bne $t1, $t6, change_x_brick_r      # Check if ball collides right
    beq $s1, 63, life_lost      # Check if y = 63 -> game over
    
    increment_ball_coordinates:
        add $s0, $s0, $s2
        add $s1, $s1, $s3
        
    lw $ra, 0($sp)
    addi $sp, $sp, 4   # Move the stack pointer back to the top of the stack
    jr $ra
    
change_x:
    mul $s2, $s2, -1
    j increment_ball_coordinates

change_y:
    mul $s3, $s3, -1
    j increment_ball_coordinates

##########################################################################################
################################# BRICK COLLISION CODE ###################################
##########################################################################################

change_x_brick_l:
    mul $s2, $s2, -1
    j remove_brick_l
    
change_x_brick_r:
    mul $s2, $s2, -1
    j remove_brick_r

change_y_brick_b:
    mul $s3, $s3, -1
    j find_brick_b

change_y_brick_a:
    mul $s3, $s3, -1
    j find_brick_a

remove_brick_l:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_BLACK
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $s0 # Multiply the x location by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by BALL_X
    addi $t0, $t0, -4
    
    li $t2, 0 # Set counter
    remove_l_loop:
        beq $t2, 8, remove_brick_end
        sw $t1, ($t0)
        sub $t0, $t0, 4
        addi $t2, $t2, 1
        j remove_l_loop

remove_brick_r:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_BLACK
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $s0 # Multiply the x location by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by BALL_X
    addi $t0, $t0, 4
    
    li $t2, 0 # Set counter
    remove_r_loop:
        beq $t2, 8, remove_brick_end
        sw $t1, ($t0)
        addi $t0, $t0, 4
        addi $t2, $t2, 1
        j remove_r_loop

find_brick_b:
    
    # Find the closest starting position of a brick to the left
    li $a0, 53
    bge $s0, $a0, remove_brick_b # BALL_X >= 53
    li $a0, 43
    bge $s0, $a0, remove_brick_b # BALL_X >= 43
    li $a0, 33
    bge $s0, $a0, remove_brick_b # BALL_X >= 33
    li $a0, 23
    bge $s0, $a0, remove_brick_b # BALL_X >= 23
    li $a0, 13
    bge $s0, $a0, remove_brick_b # BALL_X >= 13
    li $a0, 3
    bge $s0, $a0, remove_brick_b # BALL_X >= 3

# Input: $a0 : starting x position
remove_brick_b:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_BLACK
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    add $t0, $t0, $t9 # Move down one line to the brick line
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $a0 # Multiply the x location of brick by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by start of brick
    
    li $t2, 0 # Set counter
    remove_b_loop:
        beq $t2, 8, remove_brick_end
        sw $t1, ($t0)
        addi $t0, $t0, 4
        addi $t2, $t2, 1
        j remove_b_loop

find_brick_a:
    
    # Find the closest starting position of a brick to the left
    li $a0, 53
    bge $s0, $a0, remove_brick_a # BALL_X >= 53
    li $a0, 43
    bge $s0, $a0, remove_brick_a # BALL_X >= 43
    li $a0, 33
    bge $s0, $a0, remove_brick_a # BALL_X >= 33
    li $a0, 23
    bge $s0, $a0, remove_brick_a # BALL_X >= 23
    li $a0, 13
    bge $s0, $a0, remove_brick_a # BALL_X >= 13
    li $a0, 3
    bge $s0, $a0, remove_brick_a # BALL_X >= 3


# Input: $a0: starting x position
remove_brick_a:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_BLACK
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    sub $t0, $t0, $t9 # Move up one line to the brick line
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $a0 # Multiply the x location of brick by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by start of brick
    
    li $t2, 0 # Set counter
    remove_a_loop:
        beq $t2, 8, remove_brick_end
        sw $t1, ($t0)
        addi $t0, $t0, 4
        addi $t2, $t2, 1
        j remove_a_loop
        
        
##########################################################################################
############################### RED BRICK COLLISION CODE #################################
##########################################################################################
change_x_brick_lr:
    mul $s2, $s2, -1
    j remove_brick_lr
    
change_x_brick_rr:
    mul $s2, $s2, -1
    j remove_brick_rr

change_y_brick_br:
    mul $s3, $s3, -1
    j find_brick_br

change_y_brick_ar:
    mul $s3, $s3, -1
    j find_brick_ar


remove_brick_lr:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_PINK
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $s0 # Multiply the x location by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by BALL_X
    addi $t0, $t0, -4
    
    li $t2, 0 # Set counter
    remove_l_loop:
        beq $t2, 8, remove_brick_end
        sw $t1, ($t0)
        sub $t0, $t0, 4
        addi $t2, $t2, 1
        j remove_l_loop

remove_brick_rr:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_PINK
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $s0 # Multiply the x location by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by BALL_X
    addi $t0, $t0, 4
    
    li $t2, 0 # Set counter
    remove_r_loop:
        beq $t2, 8, remove_brick_end
        sw $t1, ($t0)
        addi $t0, $t0, 4
        addi $t2, $t2, 1
        j remove_r_loop

find_brick_br:
    
    # Find the closest starting position of a brick to the left
    li $a0, 53
    bge $s0, $a0, remove_brick_br # BALL_X >= 53
    li $a0, 43
    bge $s0, $a0, remove_brick_br # BALL_X >= 43
    li $a0, 33
    bge $s0, $a0, remove_brick_br # BALL_X >= 33
    li $a0, 23
    bge $s0, $a0, remove_brick_br # BALL_X >= 23
    li $a0, 13
    bge $s0, $a0, remove_brick_br # BALL_X >= 13
    li $a0, 3
    bge $s0, $a0, remove_brick_br # BALL_X >= 3

# Input: $a0 : starting x position
remove_brick_br:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_PINK
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    add $t0, $t0, $t9 # Move down one line to the brick line
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $a0 # Multiply the x location of brick by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by start of brick
    
    li $t2, 0 # Set counter
    remove_b_loop:
        beq $t2, 8, remove_brick_end
        sw $t1, ($t0)
        addi $t0, $t0, 4
        addi $t2, $t2, 1
        j remove_b_loop

find_brick_ar:
    
    # Find the closest starting position of a brick to the left
    li $a0, 53
    bge $s0, $a0, remove_brick_ar # BALL_X >= 53
    li $a0, 43
    bge $s0, $a0, remove_brick_ar # BALL_X >= 43
    li $a0, 33
    bge $s0, $a0, remove_brick_ar # BALL_X >= 33
    li $a0, 23
    bge $s0, $a0, remove_brick_ar # BALL_X >= 23
    li $a0, 13
    bge $s0, $a0, remove_brick_ar # BALL_X >= 13
    li $a0, 3
    bge $s0, $a0, remove_brick_ar # BALL_X >= 3


# Input: $a0: starting x position
remove_brick_ar:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_PINK
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    sub $t0, $t0, $t9 # Move up one line to the brick line
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $a0 # Multiply the x location of brick by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by start of brick
    
    li $t2, 0 # Set counter
    remove_a_loop:
        beq $t2, 8, remove_brick_end
        sw $t1, ($t0)
        addi $t0, $t0, 4
        addi $t2, $t2, 1
        j remove_a_loop

remove_brick_end:
    jal increment_score
    beq $s5, 30, winner
    j increment_ball_coordinates

##########################################################################################
############################### SCORING AND HELPER FUNCS #################################
##########################################################################################

increment_score:
    addi $sp, $sp, -4    # Make space on stack
    sw $ra, 0($sp)       # Store the main $ra on stack
    
    jal cover_score
    addi $s5, $s5, 1
    
    lw $a0, ADDR_DSPL # Load display address
    lw $a1, COLOR_WHITE
    
    jal draw_nums
    j nums_done

cover_score:
    addi $sp, $sp, -4    # Make space on stack
    sw $ra, 0($sp)       # Store the main $ra on stack

    # Draw the current score in black
    lw $a0, ADDR_DSPL # Load display address
    lw $a1, COLOR_BLACK
    
    addi $a0, $a0, 260
    
    jal num_clear
    addi $a0, $a0, 16
    jal num_clear
    
    j nums_done
    
draw_nums:
    addi $sp, $sp, -4    # Make space on stack
    sw $ra, 0($sp)       # Store the main $ra on stack

    li $t8, 0
    addi $a0, $a0, 260
    
    li $t0, 10
    div $s5, $t0
    mfhi $t2
    mflo $t1

tens_digit:
    # Paint the 10s digit
    beq $t1, 3, d3
    beq $t1, 2, d2
    beq $t1, 1, d1
    bgez $t1, d0

ones_digit:
    addi $t8, $t8, 1
    # Paint the 1s digit
    addi $a0, $a0, 16
    beq $t2, 9, d9
    beq $t2, 8, d8
    beq $t2, 7, d7
    beq $t2, 6, d6
    beq $t2, 5, d5
    beq $t2, 4, d4
    beq $t2, 3, d3
    beq $t2, 2, d2
    beq $t2, 1, d1
    bgez $t2, d0
    
    j nums_done

d0:
    jal draw_0
    beq $t8, $zero, ones_digit
    j nums_done
d1:
    jal draw_1
    beq $t8, $zero, ones_digit
    j nums_done
d2:
    jal draw_2
    beq $t8, $zero, ones_digit
    j nums_done
d3:
    jal draw_3
    beq $t8, $zero, ones_digit
    j nums_done
d4:
    jal draw_4
    beq $t8, $zero, ones_digit
    j nums_done
d5:
    jal draw_5
    beq $t8, $zero, ones_digit
    j nums_done
d6:
    jal draw_6
    beq $t8, $zero, ones_digit
    j nums_done
d7:
    jal draw_7
    beq $t8, $zero, ones_digit
    j nums_done
d8:
    jal draw_8
    beq $t8, $zero, ones_digit
    j nums_done
d9:
    jal draw_9
    beq $t8, $zero, ones_digit
    j nums_done

nums_done: 
    lw $ra, 0($sp)
    addi $sp, $sp, 4   # Move the stack pointer back to the top of the stack
    jr $ra # jump back to increment_score
    

##############################################
### KEYBOARD FUNCTIONS AND PADDLE MOVEMENT ###
##############################################
key_pressed:
    lw $a0, 4($s7) # Load second word from keyboard
    
    beq $a0, 0x71, quit # Check if the key q was pressed
    beq $a0, 0x61, move_left # Check if the key a was pressed
    beq $a0, 0x64, move_right # Check if the key d was pressed
    beq $a0, 0x70, pause # Check if the key p was pressed
    
    j game_loop_paddle # Return back to main

draw_paddle:
    lw $t0, ADDR_DSPL
    lw $t1, COLOR_WHITE
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, 57 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $s4 # Multiply the x location by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by PADDLE_X
    
    li $t4, 0
    lw $t5, PADDLE_SIZE
    paddle_loop:
        beq $t4, $t5, paddle_loop_exit
        sw $t1, ($t0)
        addi $t4, $t4, 1
        addi $t0, $t0, 4
        j paddle_loop
    
    paddle_loop_exit:
        jr $ra

draw_paddle_black:
    lw $t0, ADDR_DSPL
    lw $t1, COLOR_BLACK
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, 57 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $s4 # Multiply the x location by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by PADDLE_X
    
    li $t4, 0
    lw $t5, PADDLE_SIZE
    paddle_black_loop:
        beq $t4, $t5, paddle_black_loop_exit
        sw $t1, ($t0)
        addi $t4, $t4, 1
        addi $t0, $t0, 4
        j paddle_loop
    
    paddle_black_loop_exit:
        jr $ra

move_left:
    jal draw_paddle_black
    beq $s4, 1, game_loop_paddle
    addi $s4, $s4, -1   # Decrement paddle_x by 1
    j game_loop_paddle  # Go back to the game loop

move_right:
    jal draw_paddle_black
    beq $s4, 54, game_loop_paddle
    addi $s4, $s4, 1   # Decrement paddle_x by 1
    j game_loop_paddle  # Go back to the game loop

pause:
    li 		$v0, 32
	li 		$a0, 1
	syscall

    lw $t8, 0($s7)                   # Load first word from keyboard
    beq $t8, 1, key_pressed_pause         # If first word 1, key is pressed
    j pause
    
    key_pressed_pause:
        lw $a0, 4($s7)
        beq $a0, 0x70, game_loop_paddle
        beq $a0, 0x71, quit
        j pause

life_lost:
    addi $s6, $s6, -1
    jal draw_lives
    jal draw_paddle_black
    lw $a1, COLOR_WHITE
    beq $s6, 0, game_over
    
continue_playing:
    jal draw_letter_C
    jal draw_letter_R
    jal draw_letter_Q
    
    li      $v0, 32
    li      $a0, 1
    syscall

    lw $t8, 0($s7)                   # Load first word from keyboard
    beq $t8, 1, key_pressed_continue_playing  # If first word 1, key is pressed
    j continue_playing
    
key_pressed_continue_playing:
    lw $a0, 4($s7)
    
    beq $a0, 0x63, continue          # Check for 'c' key
    beq $a0, 0x71, quit              # Check for 'q' key
    beq $a0, 0x72, main              # Check for 'r' key
    j continue_playing

# Lives = 0
game_over:
    jal draw_dot
    jal draw_letter_R
    jal draw_letter_Q
    
    li      $v0, 32
    li      $a0, 1
    syscall

    lw $t8, 0($s7)                   # Load first word from keyboard
    beq $t8, 1, key_pressed_restart  # If first word 1, key is pressed
    j game_over
    
key_pressed_restart:
    lw $a0, 4($s7)
    beq $a0, 0x71, quit
    beq $a0, 0x72, main
    j game_over


winner:
    # Draw W in place of the dot
    jal draw_paddle_black
    addi $s6, $s6, -1 
    add $s5, $s5, $s6
    jal increment_score
    
winner_screen:
    jal draw_letter_W
    jal draw_letter_R
    jal draw_letter_Q
    
    li      $v0, 32
    li      $a0, 1
    syscall

    lw $t8, 0($s7)                   # Load first word from keyboard
    beq $t8, 1, key_pressed_restart  # If first word 1, key is pressed
    j winner_screen
    
key_pressed_restart:
    lw $a0, 4($s7)
    beq $a0, 0x71, quit
    beq $a0, 0x72, main
    j winner_screen


quit:
    li $v0, 10                      # Quit gracefully
	syscall

#################################################################################
############# MAIN HELPER FUNCTIONS FOR THE LEVEL AND SCREEN LAYOUT #############
#################################################################################

### BORDER ###
# Draw the border around the top and sides of the screen
# Inputs:
#   $a1 - row number
# Outputs:
draw_border:
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_GRAY # Set color to gray
    
    lw $t9, SCREEN_WIDTH # Load screen width
    mul $t8, $t9, $a1 # Multiply the line I want the border on my the screen
    add $t0, $t0, $t8
    
    # Draw top border
    li $t2, 0 # x-coordinate
    li $t3, 0 # y-coordinate
    lw $t4, PIXEL_COUNT # Number of pixels to draw
    
draw_top_border:
    sw $t1, ($t0) # Set color
    addi $t0, $t0, 4 # Move to next pixel
    addi $t2, $t2, 1 # Increment x-coordinate
    bne $t2, $t4, draw_top_border # Repeat for each pixel
    
    # Draw left border
    li $t3, 0 # y-coordinate
    sub $t4, $t4, 5 # Number of pixels to draw -> 59
draw_left_border:
    sw $t1, ($t0) # Set color
    add $t0, $t0, $t9 # Move to next pixel
    addi $t3, $t3, 1 # Increment y-coordinate
    bne $t3, $t4, draw_left_border # Repeat for each pixel
    
    # Draw right border
    lw $t0, ADDR_DSPL # Reset display address
    add $t8, $t8, $t9 # Shift down a row
    subi $t8, $t8, 4 # Back one pixel to be on the top-right corner of the border
    add $t0, $t0, $t8
    li $t3, 0 # y-coordinate
draw_right_border:
    sw $t1, ($t0) # Set color
    add $t0, $t0, $t9 # Move to next pixel
    addi $t3, $t3, 1 # Increment y-coordinate
    bne $t3, $t4, draw_right_border # Repeat for each pixel
    
    jr $ra

### BRICKS ###
# Draws a row of bricks of the given color
# Inputs:
#   $a0 - color
#   $a1 - row number
# Outputs:
#   none
draw_bricks:
    addi $sp, $sp, -4    # Make space on stack
    sw $ra, 0($sp)       # Store the main $ra on stack
    
    # Calculate the starting coordinate
    lw $t0, ADDR_DSPL # Load display address
    
    lw $t1, SCREEN_HEIGHT # Load screen height
    mul $t2, $t1, $a1 # Multiply the line I want the brick on my the screen height
    
    add $t0, $t0, $t2 # Go to row 8
    addi $t0, $t0, 12 # Move 4 pixels into row 8 so the first brick is started there
    
    li $t3, 0 # Ten bricks total per row

draw_brick_loop:
    beq $t3, 6, draw_brick_end
    jal draw_brick
    addi $t3, $t3, 1 # Increment counter $t3
    j draw_brick_loop
    
draw_brick: # Brute force create a brick since the loop was overly complicated
    sw $a0, ($t0)
    addi $t0, $t0, 4
    sw $a0, ($t0)
    addi $t0, $t0, 4
    sw $a0, ($t0)
    addi $t0, $t0, 4
    sw $a0, ($t0)
    addi $t0, $t0, 4
    sw $a0, ($t0)
    addi $t0, $t0, 4
    sw $a0, ($t0)
    addi $t0, $t0, 4
    sw $a0, ($t0)
    addi $t0, $t0, 4
    sw $a0, ($t0)
    addi $t0, $t0, 4
    addi $t0, $t0, 8
    jr $ra # Return back to drawBrickLoop
    
draw_brick_end:
    lw $ra, 0($sp) 
    addi $sp, $sp, 4   # Move the stack pointer back to the top of the stack
    jr $ra             # Return back to main

### PADDLE ###
initialize_paddle:
    addi $sp, $sp, -4    # Make space on stack
    sw $ra, 0($sp)       # Store the main $ra on stack
    lw $s4, PADDLE_X
    lw $a1, COLOR_BLACK
    jal draw_letter_C
    jal draw_letter_R
    jal draw_letter_Q
    jal draw_letter_W
    jal draw_dot
    lw $ra, 0($sp) 
    addi $sp, $sp, 4   # Move the stack pointer back to the top of the stack
    jr $ra

### BALL ###
initialize_ball:
    lw $s0, BALL_X
    lw $s1, BALL_Y
    lw $s2, BALL_DX
    lw $s3, BALL_DY
    
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, COLOR_WHITE
    
    lw $t9, SCREEN_HEIGHT # Load screen width
    mul $t8, $t9, $s1 # Multiply the line I want the ball to start on by 
    add $t0, $t0, $t8 # Move down to line specified by BALL_Y
    
    li $t3, 4 # Load pixel size
    mul $t8, $t3, $s0 # Multiply the x location by pixel size
    add $t0, $t0, $t8 # Move over the pixels specified by BALL_X
    
    sw $t1, ($t0)
    jr $ra

continue:
    lw $a0, COLOR_BLACK
    jal draw_lives
    lw $a0, COLOR_RED
    jal draw_lives
    jal initialize_paddle
    jal initialize_ball
    j game_loop

# Input: $a0: color
draw_lives:
    addi $sp, $sp, -4    # Make space on stack
    sw $ra, 0($sp)       # Store the main $ra on stack
    # Draw the lives as 2 x 2 boxes above the top border on the right of the screen
    lw $t0, ADDR_DSPL # Load display address
    lw $t1, SCREEN_HEIGHT # Load screen height
    add $t3, $zero, $s6 # Load lives
    
    # Move the display down 5 pixels
    li $t5, 4
    mul $t8, $t1, $t5
    add $t0, $t0, $t8
    # Move the display over 55 pixels
    li $t5, 4
    li $t7, 55
    mul $t8, $t7, $t5
    add $t0, $t0, $t8
    
    li $t5, 3
    sub $t6, $t5, $t3
    lw $a0, COLOR_RED
lives_loop:
    blez $t3, lost_loop
    jal draw_box
    addi $t3, $t3, -1
    addi $t0, $t0, 4 # Move to next pixel
    addi $t0, $t0, 4 # Move to next pixel
    j lives_loop

lost_loop:
    lw $a0, COLOR_BLACK
    blez $t6, lives_end
    jal draw_box
    addi $t6, $t6, -1
    addi $t0, $t0, 4 # Move to next pixel
    addi $t0, $t0, 4 # Move to next pixel
    j lost_loop

draw_box:
    sw $a0, ($t0) # Set color
    add $t0, $t0, $t1 # Move to next pixel
    sw $a0, ($t0) # Set color
    addi $t0, $t0, 4 # Move to next pixel
    sw $a0, ($t0) # Set color
    sub $t0, $t0, $t1 # Move back to previous pixel
    sw $a0, ($t0) # Set color
    jr $ra

lives_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4   # Move the stack pointer back to the top of the stack
    jr $ra

initialize_score:
    addi $sp, $sp, -4    # Make space on stack
    sw $ra, 0($sp)       # Store the main $ra on stack
    
    lw $a0, ADDR_DSPL # Load display address
    
    addi $a0, $a0, 260
    lw $a1, COLOR_BLACK
    
    jal num_clear
    addi $a0, $a0, 16
    jal num_clear
    
    lw $a0, ADDR_DSPL # Load display address
    
    addi $a0, $a0, 260
    lw $a1, COLOR_WHITE
    
    jal draw_0
    addi $a0, $a0, 16
    jal draw_0
    addi $a0, $a0, 16
    jal draw_0
    addi $a0, $a0, 16
    jal draw_0
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4   # Move the stack pointer back to the top of the stack
    jr $ra
    

#################################################
############## LETTERS AND NUMBERS ##############
#################################################

# * * * 
# *     *
# * * *
# *     *
# *     *
# Input: $a1: color
draw_letter_R:
    lw $t0, ADDR_DSPL # Load display address
    lw $t3, SCREEN_HEIGHT # Load screen height
    li $t4, 5

# Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 31 pixels
    li $t2, 4
    li $t7, 30
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_left_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 31
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 32
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw right column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 33
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
    add $t0, $t0, $t3 # Move to next pixel
draw_right_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

jr $ra

#   * * 
# *     *
# *
# *     *
#   * *
# Input: $a1: color
draw_letter_C:
    lw $t0, ADDR_DSPL # Load display address
    lw $t3, SCREEN_HEIGHT # Load screen height
    li $t4, 5

# Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 31 pixels
    li $t2, 4
    li $t7, 20
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_left_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 21
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 22
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw right column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 33 pixels
    li $t2, 4
    li $t7, 23
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_right_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

jr $ra

#   * * 
# *     *
# *     *
# *     *
#   * *   *
# Input: $a1: color
draw_letter_Q:
    lw $t0, ADDR_DSPL # Load display address
    lw $t3, SCREEN_HEIGHT # Load screen height
    li $t4, 5

# Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 31 pixels
    li $t2, 4
    li $t7, 40
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_left_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 41
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 42
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw right column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 33 pixels
    li $t2, 4
    li $t7, 43
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_right_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    
draw_final_pixel:
    # Draw right column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 33 pixels
    li $t2, 4
    li $t7, 44
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

jr $ra

# 
#   * * 
# * * * *
#   * * 
#
draw_dot:
lw $t0, ADDR_DSPL # Load display address
    lw $t3, SCREEN_HEIGHT # Load screen height
    li $t4, 5

# Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 31 pixels
    li $t2, 4
    li $t7, 20
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_left_column:
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 21
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 22
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw right column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 33 pixels
    li $t2, 4
    li $t7, 23
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_right_column:
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

jr $ra

# *       *
# *       *
# *   *   *
# *   *   *
#   * * *
draw_letter_W:
lw $t0, ADDR_DSPL # Load display address
    lw $t3, SCREEN_HEIGHT # Load screen height
    li $t4, 5

# Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 31 pixels
    li $t2, 4
    li $t7, 19
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_left_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 20
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 21
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw middle column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 32 pixels
    li $t2, 4
    li $t7, 22
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_middle_column:
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    # Draw right column
    lw $t0, ADDR_DSPL # Reset display address
    # Move the display down 32 pixels
    li $t2, 32
    mul $t8, $t3, $t2
    add $t0, $t0, $t8
# Move the display over 33 pixels
    li $t2, 4
    li $t7, 23
    mul $t8, $t7, $t2
    add $t0, $t0, $t8
draw_right_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

jr $ra

#   * 
# *   *
# *   *
# *   *
#   * 
# Input: 
#   $a0: location
#   $a1: color  
draw_0:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0

draw_left_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

jr $ra

#     * 
#   * *
#     *
#     *
#   * * *
# Input: 
#   $a0: location
#   $a1: color  
draw_1:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0
    
draw_left_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

jr $ra


#   * * 
#       *
#     *
#   *
#   * * *
# Input: 
#   $a0: location
#   $a1: color  
draw_2:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0

draw_left_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

jr $ra


#   * *  
#       *
#     * *
#       *
#   * * 
# Input: 
#   $a0: location
#   $a1: color  
draw_3:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0

draw_left_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel

jr $ra

#   *   * 
#   *   *
#     * *
#       *
#       *
# Input: 
#   $a0: location
#   $a1: color  
draw_4:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0

draw_left_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

jr $ra


#   * * * 
#   *
#   * *
#       *
#   * *
# Input: 
#   $a0: location
#   $a1: color  
draw_5:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0

draw_left_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    
jr $ra

#     * * 
#   *
#   * * 
#   *   *
#     * 
# Input: 
#   $a0: location
#   $a1: color  
draw_6:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0

draw_left_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color


    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    
jr $ra

#   * * * 
#       *
#       *
#       *
#       *
# Input: 
#   $a0: location
#   $a1: color  
draw_7:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0

draw_left_column:
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    
jr $ra

#     *  
#   *   *
#     * 
#   *   *
#     * 
# Input: 
#   $a0: location
#   $a1: color  
draw_8:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0

draw_left_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    
    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    
jr $ra

#     *  
#   *   *
#     * *
#       *
#       *
# Input: 
#   $a0: location
#   $a1: color  
draw_9:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0
    
draw_left_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    
jr $ra

#   * * * 
#   * * *
#   * * *
#   * * * 
#   * * *
# Input: 
#   $a0: location
#   $a1: color  
num_clear:
    lw $t3, SCREEN_HEIGHT
    add $t0, $zero, $a0
    
draw_left_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 4
draw_middle_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color

    add $t0, $zero, $a0
    addi $t0, $t0, 8
draw_right_column:
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    add $t0, $t0, $t3 # Move to next pixel
    sw $a1, ($t0) # Set color
    
jr $ra
