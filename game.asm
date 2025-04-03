#####################################################################
#
# CSCB58 Winter 2025 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Sheharyar Meghani, 1009830195, meghani6, s.meghani@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width: 256 (64 units)
# - Display height: 256 (64 units)
# - Base Address: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4 (choose the one the applies)
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Pickup effects: Golden box pickup lowers water level, Silver box allows player to jump double the normal amount,
# red box increases health

# 2. Moving objects: The enemy which is the water keeps rising as the game progresses with increaseing speed each level

# 3. Different levels: There are three different levels , each higher level has more platforms and higher water speed
# ... (add more if necessary)
# # Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
# # Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

.eqv BASE_ADDRESS    0x10008000
.eqv WIDTH           64
.eqv HEIGHT          64
.eqv SLEEP_MS        40
.eqv peach_color    0xFFDBAC       # Peach color for head
.eqv green_color    0x00FF00       # Green color for body lines
.eqv red_color      0xFF0000       # Red color for body lines
.eqv PLATFORM_COLOR  0x00FFFFFF  # White
.eqv WATER_COLOR     0x000000FF  # Blue
.eqv COLLECT_GIFT   0x00FFD700  # Gold
.eqv COLLECT_COLOR   0x00CD7F32  #
 .eqv JUMP_COLOR   0xFFC0C0C0  # Silver #double jump
.eqv BG_COLOR        0x00000000  # Black


.data
# Player state
jumpamt:    .word 14
plat_per_level:    .word 5
last_key:          .word 0
counter:          .word 0 
player_x:        .word 3
player_y:        .word 58
water_speed:     .word 30
player_health:       .word 4



# Water state
water_level:     .word 63       # Starts at bottom

# Platforms (x, y)
platforms:       .word 1, 59  # Platform 1
                 .word 11, 54 # Platform 2
                 .word 21, 49  # Platform 3
                 .word 31, 44  # Platform 4
                 .word 41, 39  # Platform 5 
                 .word 51, 34 # Platform 6 
                 .word 37, 29  # Platform 7
                 .word 27, 23  # Platform 8
                 .word 17, 19  # Platform 9
                    
                 




# Collectibles (x, y)
collectibles:    .word 13, 53 # Platform 2
                 .word 23, 48  # Platform 3
                 .word 33, 43  # Platform 4
                 .word 43, 38  # Platform 5 
                 .word 53, 33 # Platform 6 
                 .word 39, 28  # Platform 7
                 .word 29, 22  # Platform 8
                 .word 19, 18  # Platform 9
collect_count:   .word 4
collected:       .word 0
collect_colors:  .word COLLECT_COLOR, red_color, COLLECT_GIFT, COLLECT_COLOR,JUMP_COLOR, red_color, COLLECT_GIFT,
 COLLECT_COLOR

# Game state
curr_level:     .word 1
picked_up:      .word 0,0,0,0,0,0,0,0

.text
.globl main

main:
    jal init_game
    j end
    
init_game:
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    # Initialize background
    li   $a0, BASE_ADDRESS   
    li   $a1, BG_COLOR      
    li   $a2, 4096  # Total pixels (64x64)
    jal  draw_pixels        

    # Draw initial water level (3 lines)
    li   $a0, 4          # Number of water lines to draw
    jal  draw_water       # Call draw_water

    lw   $t2, plat_per_level           # Base platform count per level
   

    # Call draw_platforms(platforms1, num_platforms)
    la   $a0, platforms   # Base address of platforms
    move $a1, $t2         # Number of platforms to draw
    jal  draw_platforms
    
        # Call draw_collectibles(collectibles, collect_count)
    la   $a0, collectibles  # Base address of collectibles
    lw   $a1, collect_count # Number of collectibles

    jal  draw_collectibles
    

    jal  draw_player    # draw player 
    jal draw_health
    
    jal main_loop
    
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    jr   $ra               # Return to caller
    

# Function to draw a line of pixels
draw_pixels:
    # Arguments:
    # $a0 = start address
    # $a1 = color
    # $a2 = number of pixels

    move  $t5, $a0      # Store base address in $t0
    move  $t6, $a1      # Store color in $t1
    move  $t7, $a2      # Store number of pixels in $t2

draw_loop:
    beq   $t7, $zero, done_draw   # If no pixels left, exit loop
    sw    $t6, 0($t5)    # Store color at memory address
    addi  $t5, $t5, 4    # Move to the next pixel (4 bytes per pixel)
    subi  $t7, $t7, 1    # Decrease pixel count
    j     draw_loop      # Repeat
    
done_draw:
    jr    $ra     

#function to draw water lines
draw_water:
    # Arguments:
    # $a0 = number of lines to draw
    
    lw   $t0, water_level  # Load current water level (y position)
    move $t1, $a0         # Store number of lines to draw

water_loop:
    beq  $t1, $zero, water_done  # If no more lines, exit

    # Calculate address: BASE_ADDRESS + 256 * water_level
    li   $t2, BASE_ADDRESS
    li   $t3, 256
    mult $t0, $t3    # water_level * 256
    mflo  $t4
    add  $a0, $t2, $t4    # BASE_ADDRESS + offset

    li   $a1, WATER_COLOR # Water color (blue)
    li   $a2, 64         # One row = 64 pixels
    move $t4,$ra ## save return address
    jal  draw_pixels      # Draw one water line
    move $ra, $t4
    subi $t0, $t0, 1      # Decrease water_level by 1
    subi $t1, $t1, 1      # Decrease loop counter

    j    water_loop       # Repeat

water_done:
    sw   $t0, water_level # Update water_level in memory
    jr   $ra              # Return

# Function to draw platforms
draw_platforms:
    # Arguments:
    # $a0 = base address of platforms
    # $a1 = number of platforms to draw
    
    move $t0, $a0      # Platform array base address
    move $t1, $a1      # Number of platforms
    
platform_loop:
    beq  $t1, $zero, platform_done  # Exit if no platforms left

    # Load platform (x, y)
    lw   $t2, 0($t0)   # Load x
    lw   $t3, 4($t0)   # Load y

    # Compute memory address: BASE_ADDRESS + 256 * y + 4 * x
    li   $t4, BASE_ADDRESS
    li   $t5, 256
    mult $t3, $t5      # y * 256
    mflo $t6
    add  $t6, $t6, $t4 # BASE_ADDRESS + (y * 256)

    sll  $t2, $t2, 2   # x * 4 (each pixel is 4 bytes)
    add  $a0, $t6, $t2 # Final memory address

    li   $a1, PLATFORM_COLOR # Platform color
    li   $a2, 8             # Platform width (5 pixels)
    move $t3, $ra           # Save return address
    jal  draw_pixels        # Draw platform
    move $ra, $t3           # Restore return address

    addi $t0, $t0, 8   # Move to next platform (each entry is 2 words)
    subi $t1, $t1, 1   # Decrease loop counter

    j    platform_loop

platform_done:
    jr   $ra  # Return


# Function to draw a 4x4 box
draw_box:
    # Arguments:
    # $a0 = base address of the box
    # $a1 = color
    # $a2 = width
    
    move   $t2, $a2        # (height of the box)

box_loop:
    beq  $t2, $zero, box_done  # Stop if all rows drawn
    

    move $t3, $ra      # Store ra aside
    jal  draw_pixels    # Draw one row of the box
    move $ra,$t3    # restore ra

    subi $a0, $a0, 256  # Move up to next row
    subi $t2, $t2, 1    # Decrement row counter
    j    box_loop       # Repeat for next row

box_done:
    jr   $ra            # Return


draw_collectibles:
    # Arguments:
    # $a0 = base address of collectibles array
    # $a1 = number of collectibles
    
    move $t0, $a0      # Base address of collectibles
    move $t1, $a1      # Number of collectibles
    la   $t4, collect_colors       # Load colors array base


collect_loop:
    beq  $t1, $zero, collect_done  # Exit if no collectibles left
    

    # Load (x, y) coordinates
    lw   $t2, 0($t0)   # Load x
    lw   $t3, 4($t0)   # Load y
    lw   $a1, 0($t4)               # Load corresponding color

    # Compute memory address: BASE_ADDRESS + 256 * y + 4 * x
    li   $t7, BASE_ADDRESS
    li   $t5, 256
    mult $t3, $t5      # y * 256
    mflo $t6
    add  $t6, $t6, $t7 # BASE_ADDRESS + (y * 256)

    sll  $t2, $t2, 2   # x * 4 (each pixel is 4 bytes)
    add  $a0, $t6, $t2 # Final memory address
    li $a2,3 # width of box


    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  draw_box           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space

    addi $t0, $t0, 8   # Move to next collectible (each entry is 2 words)
    subi $t1, $t1, 1   # Decrease loop counter
    addi $t4, $t4, 4               # Move to next color

    j    collect_loop

collect_done:
    jr   $ra  # Return
    

erase_player:
    # Draws a 4x4 green body, 4x4 red torso, and 2x2 peach head
    lw   $t0, player_x   # Load x
    lw   $t1, player_y   # Load y
erase_green:    
    li   $a1, BG_COLOR    # Load corresponding color

    # Compute memory address: BASE_ADDRESS + 256 * y + 4 * x
    li   $t7, BASE_ADDRESS
    li   $t5, 256
    mult $t1, $t5      # y * 256
    mflo $t6
    add  $t6, $t6, $t7 # BASE_ADDRESS + (y * 256)

    sll  $t3, $t0, 2   # x * 4 (each pixel is 4 bytes)
    add  $a0, $t6, $t3 # Final memory address
    li $a2,4 # width of box
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  draw_box           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space

erase_head:    
    li   $a1, BG_COLOR    # Load corresponding color
    subi $t1,$t1,4
    addi $t0,$t0,1

    # Compute memory address: BASE_ADDRESS + 256 * y + 4 * x
    li   $t7, BASE_ADDRESS
    li   $t5, 256
    mult $t1, $t5      # y * 256
    mflo $t6
    add  $t6, $t6, $t7 # BASE_ADDRESS + (y * 256)

    sll  $t3, $t0, 2   # x * 4 (each pixel is 4 bytes)
    add  $a0, $t6, $t3 # Final memory address
    li $a2,2 # width of box
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  draw_box           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    jr   $ra  # Return


draw_player:
    # Draws a 4x4 green body, 4x4 red torso, and 2x2 peach head
    lw   $t0, player_x   # Load x
    lw   $t1, player_y   # Load y
draw_green:    
    li   $a1, green_color    # Load corresponding color

    # Compute memory address: BASE_ADDRESS + 256 * y + 4 * x
    li   $t7, BASE_ADDRESS
    li   $t5, 256
    mult $t1, $t5      # y * 256 
    mflo $t6
    add  $t6, $t6, $t7 # BASE_ADDRESS + (y * 256)

    sll  $t3, $t0, 2   # x * 4 (each pixel is 4 bytes)
    add  $a0, $t6, $t3 # Final memory address
    li $a2,4 # width of box
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  draw_box           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space

draw_head:    
    li   $a1, peach_color    # Load corresponding color
    subi $t1,$t1,4
    addi $t0,$t0,1

    # Compute memory address: BASE_ADDRESS + 256 * y + 4 * x
    li   $t7, BASE_ADDRESS
    li   $t5, 256
    mult $t1, $t5      # y * 256
    mflo $t6
    add  $t6, $t6, $t7 # BASE_ADDRESS + (y * 256)

    sll  $t3, $t0, 2   # x * 4 (each pixel is 4 bytes)
    add  $a0, $t6, $t3 # Final memory address
    li $a2,2 # width of box
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  draw_box           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    jr   $ra  # Return

erase_health:
  
    lw $t0, player_health
    li $t1, 2 # x
erase_health_loop:
    beq  $t0, $zero, erase_health_done  # Exit if no collectibles left
    
    li   $t3, 2   # Load y
    li   $a1, BG_COLOR   # Load corresponding color

    # Compute memory address: BASE_ADDRESS + 256 * y + 4 * x
    li   $t7, BASE_ADDRESS
    li   $t5, 256
    mult $t3, $t5      # y * 256
    mflo $t6
    add  $t6, $t6, $t7 # BASE_ADDRESS + (y * 256)

    sll  $t2, $t1, 2   # x * 4 (each pixel is 4 bytes)
    add  $a0, $t6, $t2 # Final memory address
    li $a2,2 # width of box


    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  draw_box           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space

    subi $t0, $t0, 1   # Move to next collectible (each entry is 2 words)
    addi $t1, $t1, 4   # increase x

    j    erase_health_loop

erase_health_done:
    jr   $ra  # Return
 
draw_health:
  
    lw $t0, player_health
    li $t1, 2 # x
health_loop:
    beq  $t0, $zero, health_done  # Exit if no collectibles left
    
    li   $t3, 2   # Load y
    li   $a1, red_color   # Load corresponding color

    # Compute memory address: BASE_ADDRESS + 256 * y + 4 * x
    li   $t7, BASE_ADDRESS
    li   $t5, 256
    mult $t3, $t5      # y * 256
    mflo $t6
    add  $t6, $t6, $t7 # BASE_ADDRESS + (y * 256)

    sll  $t2, $t1, 2   # x * 4 (each pixel is 4 bytes)
    add  $a0, $t6, $t2 # Final memory address
    li $a2,2 # width of box


    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  draw_box           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space

    subi $t0, $t0, 1   # Move to next collectible (each entry is 2 words)
    addi $t1, $t1, 4   # increase x

    j    health_loop

health_done:
    jr   $ra  # Return
    
    
plat_collision:
    # a0 = x of player
    # a1 = y of player
    la $t5,platforms
    lw $t6,plat_per_level # platforms count

    
plat_collision_loop:
    beq $t6, $zero, plat_collision_done  # If no platforms left, exit loop
    addi $t4,$a1,0
    move $t7, $a0
    # Load platform (x, y)
    lw   $t2, 0($t5)          # Load platform x position into $t2
    lw   $t3, 4($t5)          # Load platform y position into $t3
    li   $t8,6         # Set loop counter to 5

    # Check if player y is at the same height as the platform
y_check_loop:
    beq  $t4, $t3, check_x_position  # If player y == platform y, check x position
    subi $t4, $t4, 1                 # Decrement player y
    subi $t8, $t8, 1                 # Decrement counter
    bnez $t8, y_check_loop           # Repeat until counter reaches 0

    j next_platform                   # If no match found, move to next platform

next_platform:
    addi $t5, $t5, 8          # Move to next platform (each platform is 2 words: x and y)
    subi $t6, $t6, 1          # Decrement number of platforms to check
    j plat_collision_loop     # Repeat for next platform

check_x_position:
    li   $t8, 4            # Set loop counter to 4

x_check_loop:
    bge  $t7, $t2, check_x_upper_bound  # If player_x >= platform_x, check upper bound
    addi $t7, $t7, 1        # Increase player x by 1
    subi $t8, $t8, 1        # Decrease counter
    bnez $t8, x_check_loop  # Repeat if counter is not zero

    j next_platform         # If no match found, move to next platform
check_x_upper_bound:
    addi $t4, $t2, 8         # Calculate platform x + 8
    ble $t7, $t4, player_on_platform   # If player_x <= platform_x + 8, on platform
    j next_platform

player_on_platform:
    # Here, player is on the platform. Set necessary flags or update values.
    move $v0, $t2                 # Set v0 to x of platform (player is colliding with platform)
    move $v1, $t3

    j done         # return
    
plat_collision_done:  # check also for screen edges and set v0,v1 accordingly
    bgt $a0,-1,check_edge
    li $v0,-7
    j done
check_edge:
    blt $a0,60,check_edge_up
    li $v0,65
    j done
check_edge_up:
    bgt $a1,10,check_edge_down
    li $v0,1 # to indicate change in coordinates
    li $v1,11
    j done
check_edge_down:
    lw $t5,water_level
    blt $a1,$t5,done
    li $v0,1 # to indicate change in coordinates
    addi $v1,$t5,1
    j done


done:
    jr   $ra  # Return
    
    
check_keyboard:
    #Check if a key is pressed, then handle movement
    li $t9, 0xffff0000
    lw $t8, 0($t9)
    beq $t8, 1, keypress_happened
    jr $ra
keypress_happened:
    lw $t0, player_x
    lw $t1, player_y
    lw $t2, 4($t9)
    beq $t2, 0x61, respond_to_a  # If 'a' is pressed
    beq $t2, 0x64, respond_to_d  # If 'd' is pressed
    beq $t2, 0x77, respond_to_w  # If 'w' is pressed
    beq $t2, 0x72, restart  # If 'r' is pressed
    beq $t2, 0x71, end  # If 'q' is pressed
return:
    jr $ra              # Return if no recognized key is pressed

respond_to_a:
    # Handle 'a' key press (move left, for example)
    # Add your movement logic here
    li $t2,0x61
    sw   $t2,last_key
    subi $t0,$t0,3 #move plater to left by 3 units
    move $a0,$t0
    move $a1, $t1
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    li $v0,0
    jal  plat_collision           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    beq $v0, 0, no_collision  # If collision detected, adjust x
    beq $v0, 1, no_collision
    add $t0, $v0, 9
    
no_collision:
    addi $sp, $sp, -12     # Allocate space on the stack (4 bytes each for $ra, $t0, and $t1)
    sw   $ra, 8($sp)       # Save return address
    sw   $t0, 4($sp)       # Save $t0 (player_x)
    sw   $t1, 0($sp)       # Save $t1 (player_y)

    jal  erase_player      # Call erase_player

    lw   $t0, 4($sp)       # Restore $t0 (player_x)
    lw   $t1, 0($sp)       # Restore $t1 (player_y)
    
    sw   $t0, player_x     # Store updated player_x
    sw   $t1, player_y     # Store updated player_y

    jal  draw_player       # Call draw_player

    lw   $ra, 8($sp)       # Restore return address
    addi $sp, $sp, 12      # Deallocate stack space

    jr   $ra               # Return
    
respond_to_d:
    # Handle 'd' key press (move left, for example)
    # Add your movement logic here
    li $t2,0x64
    sw   $t2,last_key
    addi $t0,$t0,3 # move player to right by 3 units
    move $a0,$t0
    move $a1, $t1
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    li $v0,0
    jal  plat_collision           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    beq $v0, 0, no_collision  # If collision detected, adjust x
    beq $v0, 1, no_collision
    sub $t0, $v0, 5
    j no_collision

respond_to_w:
    # Handle 'w' key press (move left, for example)
    # Add your movement logic here
    
key_valid:
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  on_ground           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    bne $v0,1,return
    li $t2,0x77
    sw   $t2,last_key
    lw $t2,jumpamt # load jump amount
    sub $t1,$t1,$t2 #move player up by jumpamt units
    li $t2,14 # reset jump amount if double jump is activated
    sw $t2,jumpamt
    move $a0,$t0
    move $a1, $t1
    addi $a1, $a1,5
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    li $v0,0
    jal  plat_collision           
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    beq $v0, 0, no_collision  # If collision detected, adjust y
    addi $t1, $v1, 7
    j no_collision
    
on_ground: # checks if player is on platforms or water
    lw $t8, player_x
    lw $t9, player_y 
    la $t5,platforms
    lw $t6,plat_per_level # number of platforms
    
on_ground_loop:
    beq $t6, $zero, on_ground_done  # If no platforms left, exit loop
    # Load platform (x, y)
    lw   $t2, 0($t5)          # Load platform x position into $t2
    lw   $t3, 4($t5)          # Load platform y position into $t3
    subi $t3,$t3,1
    beq $t9,$t3,check_x
next_ground:
    addi $t5, $t5, 8          # Move to next platform (each platform is 2 words: x and y)
    subi $t6, $t6, 1          # Decrement number of platforms to check
    j on_ground_loop
check_x:
    li   $t4, 4            # Set loop counter to 4
    move $t7,$t8

x_loop:
    bge  $t7, $t2, check_x_upper  # If player_x >= platform_x, check upper bound
    addi $t7, $t7, 1        # Increase player x by 1
    subi $t4, $t4, 1        # Decrease counter
    bnez $t4, x_loop  # Repeat if counter is not zero

    j next_ground         # If no match found, move to next platform
check_x_upper:
    addi $t4, $t2, 8          # Calculate platform x + 8
    ble $t7, $t4, ground_yes   # If player_x <= platform_x + 8, on platform
    j next_ground

ground_yes:
    li $v0,1 

on_ground_done:
    lw $t4,water_level
    subi $t4,$t4,0
    blt $t9,$t4,no_water # see players y is inside water
    li $v0,1
no_water: 
    jr $ra



  
    
move_down:
    # checks if player is not on platform and should be moved down
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  on_ground           
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    beq $v0,1,no_move_down
    lw $t0,player_x
    lw $t1,player_y
    addi $t1,$t1,2
    move $a0,$t0
    move $a1, $t1
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    li $v0,0
    jal  plat_collision          
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    beq $v0, 0, no_collision  # If collision detected, adjust y
    subi $t1,$v1,1
    j no_collision
    
    
no_move_down:
    jr $ra





update_health:
    # load players y
    lw $t0,player_y
    addi $t0,$t0,1
    #load water line
    lw $t1,water_level
    blt $t0,$t1,no_need
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  erase_health           # Draw health
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    lw $t2,player_health
    subi $t2,$t2,1
    sw $t2,player_health
    beq $t2,0,restart
    
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  draw_health           # Draw health
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    

no_need:
    jr $ra

pick_up:
    li $v0,-1
    lw $a0,player_x
    lw $a1,player_y
    # a1 = y of player
    la $t5,collectibles
    lw $t6,collect_count # number of collectibles
    
pick_up_loop:
    beq $t6, $zero, pick_up_done  # If no items left, exit loop

    move $t7, $a0
    # Load item (x, y)
    lw   $t2, 0($t5)          # Load item x position into $t2
    lw   $t3, 4($t5)          # Load item y position into $t3
    

    # Check if player y is at the same height of item
y_check:
    beq  $a1, $t3, check_x_item  # If player y == item y, check x position

    j next_pick_up                  # If no match found, move to next item

next_pick_up:
    addi $t5, $t5, 8          # Move to next item (each platform is 2 words: x and y)
    subi $t6, $t6, 1          # Decrement number of items to check
    j pick_up_loop     # Repeat for next item

check_x_item:
    li   $t8, 4            # Set loop counter to 4

x_item_loop:
    bge  $t7, $t2, item_x_upper_bound  # If player_x >= item_x, check upper bound
    addi $t7, $t7, 1        # Increase player x by 1
    subi $t8, $t8, 1        # Decrease counter
    bnez $t8, x_item_loop  # Repeat if counter is not zero

    j next_pick_up         # If no match found, move to next item
item_x_upper_bound:
    addi $t4, $t2, 3          # Calculate item x + 3
    ble $t7, $t4, player_on_pick_up   # If player_x <= item_x + 3, on item
    j next_pick_up

player_on_pick_up:
    # Here, player is on the item. Set necessary flags or update values.
    lw $v0,collect_count
    sub $v0, $v0,$t6                # Set v0 to collectibles-t6

    j pick_up_done         # return



pick_up_done:
    jr   $ra  # Return
    
    
    
    
check_collect:
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  pick_up          
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    beq $v0,-1,no_collect
    li $t1,4
    mult $t1,$v0
    mflo $t1 # index to check
    la $t0,picked_up
    add $t0,$t0,$t1
    lw $t2,0($t0)
    beq $t2,0,yes_collect
    jr $ra
yes_collect:
    li $t2,1
    sw $t2,0($t0)
    lw $t2,collected
    lw $t3,collect_count
    addi $t2,$t2,1
    sw $t2,collected
    beq $t2,$t3,all_collected
    la $t5,collect_colors #check is gold item is picked up
    add $t5,$t5,$t1
    lw $t6,0($t5)
    li $t7,COLLECT_GIFT
    beq $t6,$t7,gift_collect
    li $t7,JUMP_COLOR
    beq $t6,$t7,jump_collect
    li $t7,red_color
    beq $t6,$t7,health_collect
    jr $ra
gift_collect:
    lw $t0,water_level
    li   $t2, BASE_ADDRESS
    li   $t3, 256
    mult $t0, $t3    # water_level * 256
    mflo  $t4
    add  $a0, $t2, $t4    # BASE_ADDRESS + offset

    li   $a1, BG_COLOR # black
    li   $a2, 64         # One row = 64 pixels
    move $t4,$ra ## save return address
    jal  draw_pixels      # erase one water line
    move $ra, $t4
    
    add  $a0, $t3, $a0
    move $t4,$ra ## save return address
    jal  draw_pixels      # Draw one water line
    move $ra, $t4
    addi $t0,$t0,2
    sw $t0,water_level
    jr $ra

jump_collect:
    la $t0,jumpamt
    li $t1,20
    sw $t1,0($t0)
    jr $ra

health_collect:
    la $t0,player_health
    lw $t1,0($t0)
    addi $t1,$t1,1
    sw $t1,0($t0)
        addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal  draw_health           # Draw 4x4 collectible box
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4       # Deallocate stack space
    jr $ra
    
all_collected:
    j change_level
no_collect:
    jr $ra
   
   
    
change_level:
    # display you win first
    # Initialize background
    li   $a0, BASE_ADDRESS   
    li   $a1, BG_COLOR      
    li   $a2, 4096  # Total pixels (64x64)
    jal  draw_pixels  
    
    # draw you win!
    
    li   $t0, BASE_ADDRESS  # Screen start address
    li   $t1, 25            # Center row (assuming 64x64 screen)
    li   $t2, 20            # Approximate starting column for text
    li   $a1, 0x00FF00      # Green color
    mul  $t4, $t1, 256      # Multiply column by 256 ( column offset)
    mul  $t2, $t2, 4      # Multiply row by 4 (row offset)
    add  $t4, $t4, $t2      # Add column offset
    add  $t0, $t0, $t4      # Compute final address
    
        # Draw "W"
    li   $t4, 7             # 6 vertical pixels
    draw_W_vertical1:
        move  $a0, $t0       # Start address
        li    $a2, 1         # One pixel at a time
        jal   draw_pixels    
        addi  $t0, $t0, 256 # Move down by one row 256
        subi  $t4, $t4, 1    # Decrease counter
        bgtz  $t4, draw_W_vertical1

    addi  $t0, $t0, 0        # Move to next column
    li   $a2, 4             # 3 pixels horizontally
    move $a0, $t0           # Start address for horizontal line
    jal   draw_pixels       
    addi  $t0, $t0, 12       # Move to next column
    move $t9,$t0
    subi  $t0, $t0, 256      # Move to next row

    li   $t4, 7             # 6 vertical pixels
    draw_W_vertical2:
        move  $a0, $t0       # Start address
        li    $a2, 1         # One pixel at a time
        jal   draw_pixels    
        subi  $t0, $t0, 256 # Move down by one row 256
        subi  $t4, $t4, 1    # Decrease counter
        bgtz  $t4, draw_W_vertical2
    
    move $t0,$t9

    addi  $t0, $t0, 4       # Move to next column
    li   $a2, 3             # 3 pixels horizontally
    move $a0, $t0           # Start address for horizontal line
    jal   draw_pixels       
    addi  $t0, $t0, 8       # Move to next column
    move $t9,$t0
    subi  $t0, $t0, 256      # Move to next column

    li   $t4, 7             # 6 vertical pixels
    draw_W_vertical3:
        move  $a0, $t0       # Start address
        li    $a2, 1         # One pixel at a time
        jal   draw_pixels    
        subi  $t0, $t0, 256 # Move down by one row 256
        subi  $t4, $t4, 1    # Decrease counter
        bgtz  $t4, draw_W_vertical3

    move $t0,$t9
    addi $t0,$t0,24
    move $t9,$t0

    # Draw "I"
    li   $t4, 8             # 6 pixels vertically
    draw_I:
        move  $a0, $t0       # Start address
        li    $a2, 1         # One pixel at a time
        jal   draw_pixels    
        subi  $t0, $t0, 256
        subi  $t4, $t4, 1    # Decrease counter
        bgtz  $t4, draw_I
        
    move $t0,$t9
    addi  $t0, $t0, 24       # Move to next column
    
    li   $t4, 8             # 6 pixels vertically
    draw_N:
        move  $a0, $t0       # Start address
        li    $a2, 1         # One pixel at a time
        jal   draw_pixels    
        subi  $t0, $t0, 256
        subi  $t4, $t4, 1    # Decrease counter
        bgtz  $t4, draw_N
    
    addi  $t0, $t0, 260       # Move to next column
    li   $a2, 3             # 3 pixels horizontally
    move $a0, $t0           # Start address for horizontal line
    jal   draw_pixels       
    addi  $t0, $t0, 8       # Move to next column
    move $t9,$t0
    addi  $t0, $t0, 256      # Move to next column
    li   $t4, 7             # 8 pixels vertically
    draw_N2:
        move  $a0, $t0       # Start address
        li    $a2, 1         # One pixel at a time
        jal   draw_pixels    
        addi  $t0, $t0, 256
        subi  $t4, $t4, 1    # Decrease counter
        bgtz  $t4, draw_N2
    
    li $v0, 32
    li $a0, 1200 # Wait one second (1000 milliseconds)
    syscall 
    
    #change level and data
    
    lw $t0,curr_level
    beq $t0,3,end
    beq $t0,1,go_two
    beq $t0,2,go_three

go_three:
    li $t0, 0
    sw $t0, last_key      # Reset last_key
    sw $t0, counter       # Reset counter
    sw $t0, collected     # Reset collected
    
    li $t0, 9
    sw $t0, plat_per_level      # Reset player_x
    

    li $t0, 3
    sw $t0, player_x      # Reset player_x

    li $t0, 58
    sw $t0, player_y      # Reset player_y

    li $t0, 9
    sw $t0, water_speed   # Reset water_speed

    li $t0, 4 
    sw $t0, player_health # Reset player_health


    li $t0, 63
    sw $t0, water_level   # Reset water_level

    li $t0, 3
    sw $t0, curr_level    # Reset curr_level
    
    # Reset picked_up array
    la $t1, picked_up     # Load base address of picked_up array
    lw $t2, collect_count          # Number of elements in the array
reset_level_loop3:
    sw $zero, 0($t1)      # Store 0 at current array index
    addiu $t1, $t1, 4     # Move to the next element
    sub $t2, $t2, 1       # Decrement counter
    bnez $t2, reset_level_loop3  # Loop if not done
    
    li $t0, 8
    sw $t0, collect_count      # Reset collectibles count

    # Call init_game
    jal init_game
    
go_two:
    li $t0, 0
    sw $t0, last_key      # Reset last_key
    sw $t0, counter       # Reset counter
    sw $t0, collected     # Reset collected
    
    li $t0, 7
    sw $t0, plat_per_level      # Reset player_x
    
 
    li $t0, 3
    sw $t0, player_x      # Reset player_x

    li $t0, 58
    sw $t0, player_y      # Reset player_y

    li $t0, 15
    sw $t0, water_speed   # Reset water_speed

    li $t0, 4 
    sw $t0, player_health # Reset player_health


    li $t0, 63
    sw $t0, water_level   # Reset water_level

    li $t0, 2
    sw $t0, curr_level    # Reset curr_level
    
    # Reset picked_up array
    la $t1, picked_up     # Load base address of picked_up array
    lw $t2, collect_count          # Number of elements in the array
reset_level_loop:
    sw $zero, 0($t1)      # Store 0 at current array index
    addiu $t1, $t1, 4     # Move to the next element
    sub $t2, $t2, 1       # Decrement counter
    bnez $t2, reset_level_loop  # Loop if not done
    
    li $t0, 6
    sw $t0, collect_count      # Reset collectibles count

    # Call init_game
    jal init_game    

    
           
    
    

    
   
    
main_loop:
    lw $t3,counter
    addi $t3,$t3,1
    sw $t3, counter
    addi $sp, $sp, -4      # Allocate space on the stack
    sw   $ra, 0($sp)       # Save return address
    jal move_down
    jal check_keyboard
    jal check_collect
    
    
    
    
    
    
    
    
    lw $t4,counter
    lw $t5,water_speed
    bne $t4,$t5,repeat #check if time to increase water
draw_line:
    jal update_health
    li $t4,0
    sw $t4, counter #reset counter
    li   $a0, 1          # Number of water lines to draw
    jal  draw_water       # Call draw_water
    
repeat:
    lw   $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4
    li $v0, 32
    li $a0, 40 # Wait one second (1000 milliseconds)
    syscall
    j main_loop
    

restart:
    lw $t7,player_health
    bne $t7,0,no_lose
draw_fail:
    li   $a0, BASE_ADDRESS   
    li   $a1, BG_COLOR      
    li   $a2, 4096  # Total pixels (64x64)
    jal  draw_pixels   
    
    li   $t0, BASE_ADDRESS  # Screen start address
    li   $t1, 25            # Center row (assuming 64x64 screen)
    li   $t2, 14            # Approximate starting column for text
    li   $a1, red_color      # red color
    mul  $t4, $t1, 256      # Multiply column by 256 ( column offset)
    mul  $t2, $t2, 4      # Multiply row by 4 (row offset)
    add  $t4, $t4, $t2      # Add column offset
    add  $t0, $t0, $t4      # Compute final address
    
        # Draw "L"
    li   $t4, 12             # 12 vertical pixels
    draw_L_vertical:
        move  $a0, $t0       # Start address
        li    $a2, 1         # One pixel at a time
        jal   draw_pixels    
        addi  $t0, $t0, 256 # Move down by one row 256
        subi  $t4, $t4, 1    # Decrease counter
        bgtz  $t4, draw_L_vertical

    
    li   $a2, 6             # 6 pixels horizontally
    move $a0, $t0           # Start address for horizontal line
    jal   draw_pixels       
    addi  $t0, $t0, 36      # Move to next column
    move $t9,$t0

    li   $t4, 12             # 6 vertical pixels
draw_O_left:
    move  $a0, $t0
    li    $a2, 1
    jal   draw_pixels
    subi  $t0, $t0, 256
    subi  $t4, $t4, 1
    bgtz  $t4, draw_O_left

# Right vertical of O (3 columns right)
addi $t0, $t9, 20       # 3 columns * 4 bytes
li   $t4, 12
draw_O_right:
    move  $a0, $t0
    li    $a2, 1
    jal   draw_pixels
    subi  $t0, $t0, 256
    subi  $t4, $t4, 1
    bgtz  $t4, draw_O_right

# Top horizontal of O
move $a0, $t9        
li   $a2, 5             
jal  draw_pixels

# Bottom horizontal of O
addi $a0, $t9, 0        # Start at left +1 column
subi $a0, $a0, 2816     # 7 rows down (7*256 = 1792)
jal  draw_pixels

addi $t0, $t9, 40     # Move to next letter (O is 4 columns wide)


# Top horizontal of S
move $t9, $t0
li   $a2, 6
addi $a0, $t0,0
jal  draw_pixels


addi $s1,$t0,5

# Middle horizontal of S (6 pixels down)
subi $t0, $t9, 1536      # 6 rows down (6*256)

move $a0, $t0
jal  draw_pixels

# Bottom horizontal of S (4 rows down from top)
subi $t0, $t0, 1280     # 4 rows (4*256)
move $a0, $t0
jal  draw_pixels

# Vertical from top to middle (left side)
addi $t0, $t0,1280

li   $t4, 6
draw_S_left:
    move  $a0, $t0
    li    $a2, 1
    jal   draw_pixels
    subi  $t0, $t0, 256
    subi  $t4, $t4, 1
    bgtz  $t4, draw_S_left

# Vertical from middle to bottom (right side)
li   $t4, 7
addi $t0,$t0,1556

draw_S_right:
    move  $a0, $t0
    li    $a2, 1
    jal   draw_pixels
    addi  $t0, $t0, 256
    subi  $t4, $t4, 1
    bgtz  $t4, draw_S_right

addi $t0, $t9, 36       # Move to next letter
# Vertical line of E
move $t9, $t0
li   $t4, 11
draw_E_vertical:
    move  $a0, $t0
    li    $a2, 1
    jal   draw_pixels
    subi  $t0, $t0, 256
    subi  $t4, $t4, 1
    bgtz  $t4, draw_E_vertical

# Top horizontal
subi $t0,$t0,0
move $a0, $t0
li   $a2, 5
jal  draw_pixels

# Middle horizontal
addi $a0, $a0, 1280     # 4 rows down
jal  draw_pixels

# Bottom horizontal
addi $a0, $a0, 1536     # 4 rows down
jal  draw_pixels

li $v0, 32
li $a0, 1000            # Wait 700ms
syscall

    
no_lose:
    li $t0, 0
    sw $t0, last_key      # Reset last_key
    sw $t0, counter       # Reset counter
    sw $t0, collected     # Reset collected
    
    li $t0, 5
    sw $t0, plat_per_level      # Reset player_x
    

    li $t0, 3
    sw $t0, player_x      # Reset player_x

    li $t0, 58
    sw $t0, player_y      # Reset player_y

    li $t0, 30
    sw $t0, water_speed   # Reset water_speed

    li $t0, 4 
    sw $t0, player_health # Reset player_health


    li $t0, 63
    sw $t0, water_level   # Reset water_level

    li $t0, 1
    sw $t0, curr_level    # Reset curr_level
    
    # Reset picked_up array
    la $t1, picked_up     # Load base address of picked_up array
    lw $t2, collect_count          # Number of elements in the array
reset_loop:
    sw $zero, 0($t1)      # Store 0 at current array index
    addiu $t1, $t1, 4     # Move to the next element
    sub $t2, $t2, 1       # Decrement counter
    bnez $t2, reset_loop  # Loop if not done
    
    li $t0, 4
    sw $t0, collect_count      # Reset collectibles count

    # Call init_game
    jal init_game 

    
    
end:
    # Properly terminate the program
    li $v0, 10              # Exit syscall
    syscall
    

