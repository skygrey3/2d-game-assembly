.data
	# matrix used for generating the map at the start
	# map updates are handled on display using ASCII 7 cursor, not by reprinting data
	map:	.word 35, 35, 35, 35, 35, 35, 35, 35	# }
		.word 35, 32, 32, 32, 32, 32, 32, 35	# }
		.word 35, 32, 32, 32, 32, 32, 32, 35	# } map matrix
		.word 35, 32, 32, 32, 32, 32, 32, 35	# } with column-major 
		.word 35, 32, 32, 32, 32, 32, 32, 35	# } order
		.word 35, 35, 35, 35, 35, 35, 35, 35	# } 6x8
		
	scoreText:	.word 83, 99, 111, 114, 101, 58, 32		# "Score: "
	gameOverText:	.word 71, 65, 77, 69, 32, 79, 86, 69, 82	# "GAME OVER"
	#  player struct, where the first and second elemets, 
	#  0(player) and 4(player) are the x and y coordinates respectively
	player:	.word 1			# player.x
		.word 2			# player.y
	enemy:	.word 0			# enemy.x
		.word 0			# enemy.y
	reward:	.word 0			# reward.x
		.word 0			# reward.y
	score:	.word 0			# stores score value
	kb_buf_size: 	.word 0
	kb_buf: 	.space 1000
	kb_buf_limit:	.word 1000
.text
	main:
	####	start of code from [1]	####
		# inputHandler function setup   
		li $t0, 0xffff0000 	# control register addr.
		li $t1, 0 		# } disable interrupt
		sw $t1, ($t0) 		# } 
	####	end of code from [1]	####
		
		# initiasizing map variables
		li $s0, 6		# n = 6
		li $s1, 8		# m = 8
		li $s2, 0		# i index
		li $s3, 0		# j index
		la $s4, map		# map matrix adress/pointer
		jal genPlayer		# generating player
		jal genEnemy		# generating enemy
		jal genReward		# generating reward
		jal genScore		# printing score text
		jal printScore		# printing score value
		jal printMap		# print map

	# main game loop 
	# loops until score reaches 100
	game:
		jal inputHandler	# waiting for input; when received, moves player
		jal collisionCheck	# checking if player collided with something (wall or enemy)
		jal enemyTurn		# moving enemy towards reward
		jal rewardHandler	# if reward has been collected, regenerate it and update score
		jal collisionCheck	# checking if player collided with something again
		lw $t0, score		# } checking win con:
		blt $t0, 100, game	# } if score >= 100, end game
	# game reaches end when the player dies or reaches 100 score
	end:
		# game over screen
		jal clearScreen		# clearing display
		jal genScore		# printing score text
		jal printScore		# printing score value
		jal gameOver		# printing game over screen
		li $v0, 10		# } exiting program
		syscall			# }
	
	# generates a random player position
	# used at the start of the game
	genPlayer:
		# generating player.y = random int from interval [1, n - 1]
		li $v0, 42  		# random int system call
		subi $t0, $s0, 2	# upper bound = n - 2
		add $a1, $a1, $t0	# setting upper bound
		syscall    		# generating random int in [0, n - 2]
		addi $a0, $a0, 1	# random int ++
		la $t0, player		# }
		sw $a0, 4($t0)		# } saving player.y in memory
		
		li $a1, 0		# resetting register
		# generating player.x = random int from interval [1, m - 1]
		li $v0, 42  		# random int system call
		subi $t0, $s1, 2	# upper bound = m - 2
		add $a1, $a1, $t0	# setting upper bound
		syscall    		# generating random int in [0, m - 2]
		addi $a0, $a0, 1	# random int ++
		la $t0, player		# }
		sw $a0, 0($t0)		# } saving player.x in memory 
		
		li $a0, 0		# }
		li $a1, 0		# } resetting used registers
		# return of genPlayer
		jr $ra
		
	# generates a random enemy position (making sure to not be on top of player)
	# used at the start of the game	
	genEnemy:
		li $a0, 0		# } clearing registers bcuz bugs
		li $a1, 0		# } 
		# generating reward.y = random int from interval [1, n - 1]
		li $v0, 42  		# random int system call
		subi $t0, $s0, 2	# upper bound = n - 2
		add $a1, $a1, $t0	# setting upper bound
		syscall    		# generating random int in [0, n - 2]
		addi $a0, $a0, 1	# random int ++
		la $t0, enemy		# }
		sw $a0, 4($t0)		# } saving enemy.y in memory
		
		li $a1, 0		# resetting register
		# generating reward.x = random int from interval [1, m - 1]
		li $v0, 42  		# random int system call
		subi $t0, $s1, 2	# upper bound = m - 2
		add $a1, $a1, $t0	# setting upper bound
		syscall    		# generating random int in [0, m - 2]
		addi $a0, $a0, 1	# random int ++
		la $t0, enemy		# }
		sw $a0, 0($t0)		# } saving enemy.x in memory 
		
		# checking if enemy is on top of player
		# if true, regen reward
		la $t1, player			# loading player pos
		lw $t2, 0($t0)			# enemy.x
		lw $t3, 4($t0)			# enemy.y
		lw $t4, 0($t1)			# player.x
		lw $t5, 4($t1)			# player.y
		j condition3			# redirects to first condition of 'if'
	condition4:
		beq $t3, $t5, genEnemy		# (cond1) ... and enemy.y == player.y, regen enemy
		j else2				# else continue
	condition3:
		beq $t2, $t4, condition4	# if enemy.x == player.x ... (cond2)
	else2:
		li $a0, 0		# }
		li $a1, 0		# } resetting used registers
		jr $ra			# returning
	
	# generates a random reward position (and making sure to not be on top of player or enemy)
	genReward:
		li $a0, 0		# } clearing registers bcuz bugs
		li $a1, 0		# } 
		# generating reward.y = random int from interval [1, n - 1]
		li $v0, 42  		# random int system call
		subi $t0, $s0, 2	# upper bound = n - 2
		add $a1, $a1, $t0	# setting upper bound
		syscall    		# generating random int in [0, n - 2]
		addi $a0, $a0, 1	# random int ++
		la $t0, reward		# }
		sw $a0, 4($t0)		# } saving reward.y in memory
		
		li $a1, 0		# resetting register
		# generating reward.x = random int from interval [1, m - 1]
		li $v0, 42  		# random int system call
		subi $t0, $s1, 2	# upper bound = m - 2
		add $a1, $a1, $t0	# setting upper bound
		syscall    		# generating random int in [0, m - 2]
		addi $a0, $a0, 1	# random int ++
		la $t0, reward		# }
		sw $a0, 0($t0)		# } saving reward.x in memory 
		
		# checking if reward is on top of player
		# if true, regen reward
		la $t1, player			# loading player pos
		lw $t2, 0($t0)			# reward.x
		lw $t3, 4($t0)			# reward.y
		lw $t4, 0($t1)			# player.x
		lw $t5, 4($t1)			# player.y
		j condition1
	condition2:
		beq $t3, $t5, genReward		# (cond1) ... and reward.y == player.y, regen reward
		j else1				# else continue
	condition1:
		beq $t2, $t4, condition2	# if reward.x == player.x ... (cond2)
	else1:
		# checking if reward is on top of enemy
		# if true, regen reward
		la $t1, enemy			# loading enemy pos
		lw $t2, 0($t0)			# reward.x
		lw $t3, 4($t0)			# reward.y
		lw $t4, 0($t1)			# enemy.x
		lw $t5, 4($t1)			# enemy.y
		j condition5
	condition6:
		beq $t3, $t5, genReward		# (cond1) ... and reward.y == enemy.y, regen reward
		j else3				# else continue
	condition5:
		beq $t2, $t4, condition6	# if reward.x == enemy.x ... (cond2)
	else3:
		li $a0, 0		# }
		li $a1, 0		# } resetting used registers
		jr $ra			# return
	
	# prints out the score text on display
	genScore:
		li $t5, 0
		li $t6, 7
		la $t4, scoreText
	genScoreLoop:
		beq $t5, $t6, exitGenScore	# when i == 7, end loop
		lw $a0, ($t4)		# loading current letter
		# printing current letter on screen
		li $t0, 0
		li $a2, 0
		add $t0, $t0, $t4	# }
		add $a2, $a2, $t5	# } carring over letter pos and current letter
		li $a3, -1		# } 
		move $t3, $a0		# } 
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
		add $t4, $t4, 4		# index++
		add $t5, $t5, 1		# i++
		j genScoreLoop
	exitGenScore:
		jr $ra			# exiting genScore
	
	# prints out the map on display
	# if the game ends, redirects to game over screen
	printMap: 
		# saving player in initial map matrix
		la $a0, map		# fetching map adress
		la $a1, player		# fetching player adress
		lw $a2, 0($a1)		# loading player.x from memory
		lw $a3, 4($a1)		# loading player.y from memory
		mul $t0, $a3, $s1	# } 
		add $t0, $t0, $a2	# } index = 4 * (player.y * 8 + player.x)
		mul $t0, $t0, 4		# }
		add $a0, $t0, $a0	# } 
		
		li $t1, 80		# } map[index] = 'P'
		sw $t1, ($a0)		# }
		
		# saving enemy in initial map matrix
		la $a0, map		# fetching map adress
		la $a1, enemy		# fetching enemy adress
		lw $a2, 0($a1)		# loading enemy.x from memory
		lw $a3, 4($a1)		# loading enemy.y from memory
		mul $t0, $a3, $s1	# } 
		add $t0, $t0, $a2	# } index = 4 * (enemy.y * 8 + enemy.x)
		mul $t0, $t0, 4		# }
		add $a0, $t0, $a0	# } 
		
		li $t1, 69		# } map[index] = 'E'
		sw $t1, ($a0)		# }
		
		# saving reward in initial map matrix
		la $a0, map		# fetching map adress
		la $a1, reward		# fetching reward adress
		lw $a2, 0($a1)		# loading reward.x from memory
		lw $a3, 4($a1)		# loading reward.y from memory
		mul $t0, $a3, $s1	# } 
		add $t0, $t0, $a2	# } index = 4 * (reward.y * 8 + reward.x)
		mul $t0, $t0, 4		# }
		add $a0, $t0, $a0	# } 
		
		li $t1, 82		# } map[index] = 'R'
		sw $t1, ($a0)		# }
		
		add $a1, $s4, 0		# copying map adress
		# point cursor to (1, 0), which is the starting pos of the map
		li $t0, 0		# load x value
		mul $t1, $t0, 1048576	# bitshift x value 20 bits
		li $t0, 1		# load y value
		mul $t2, $t0, 256	# bitshift x value 8 bits
		add $t2, $t2, $t1	# } adding x, y and 7 (ASCII bell) value
		addi $t2, $t2, 7	# }  
		sw $t2, 0xffff000c($zero)	# Write to the Transmitter Data register
	printMapLoop:
		slt $t0, $s2, $s0		# } if not i < n, exit
		beq $t0, $zero, exitGameState	# }
		columns:
		beq $s3, $s1, exitColumns	# when j == 8, end loop
		lw $a0, ($a1)		# } 
	# printing current map character
	wait1:	lw $t0, 0xffff0008	# control register
		andi $t0, $t0, 1	# preparing bits in $t0
		beq $t0, $zero, wait1	# if not ready, loop until ready
		sb $a0, 0xffff000c($zero)	# placing current char in data register
		addi $a1, $a1, 4 	# index++
		add $s3, $s3, 1		# j++
		j columns
		exitColumns:
		li $s3, 0			# reseting column counter: j = 0
		addi $s2, $s2, 1		# i++
		# moving cursor to the beginning of next line: (i + 1, 0)
		li $t0, 0		# } load x value (always 0 in this case)
		mul $t1, $t0, 1048576	# bitshift x value 20 bits
		li $t0, 1		# } load y value:
		add $t0, $t0, $s2	# } y = i + 1 (changes from line to line)
		mul $t2, $t0, 256	# bitshift x value 8 bits
		add $t2, $t2, $t1	# } 
		addi $t2, $t2, 7	# } adding x, y and 7 (ASCII bell) value 
		sw $t2, 0xffff000c($zero)	# Write to the Transmitter Data register
		# continuing loop
		j printMapLoop
	exitGameState:
		li $s2, 0			# } resetting counter variables
		li $s3, 0			# }
		jr $ra
	
	inputHandler:
		j poll		# sort of scanf("%s", move)
	inputCheck:
		la $t1, kb_buf 		# load address of buffer
		lw $t2, kb_buf_size 	# current size of buffer
		# if the buffer does not contain anything, retry
		beq $t2, $zero, inputHandler
		# If the buffer contains more than one letter, clear it and retry
		bne $t2, 1, clearBuffer
		
		# load character from buffer
		lw $t0, 0($t1)
		# checking if the input is w, a, s or d
		li $t3, 119			# ASCII for 'w'
		beq $t0, $t3, moveUp		#
		li $t3, 97			# ASCII for 'a'
		beq $t0, $t3, moveLeft		# 
		li $t3, 115			# ASCII for 's'
		beq $t0, $t3, moveDown		# 
		li $t3, 100			# ASCII for 'd'
		beq $t0, $t3, moveRight		# 
		li $t3, 87			# ASCII for 'W'
		beq $t0, $t3, moveUp		# 
		li $t3, 65			# ASCII for 'A'
		beq $t0, $t3, moveLeft		# 
		li $t3, 83			# ASCII for 'S'
		beq $t0, $t3, moveDown		# 
		li $t3, 68			# ASCII for 'D'
		beq $t0, $t3, moveRight		#
		# wrong letter, so clear buffer and retry
		j clearBuffer
		
		#### start of code taken from [1] ####
	poll:
		li $t0, 0xffff0000 	# keyboard control register
		lw $t1, ($t0) 		# read keyboard control register
		andi $t1, $t1, 1 	# check data bit
		beq $t1, $zero, exitPoll# if not ready, exit
		# pull data from keyboard and store in buffer
		lw $t3, 4($t0) 		# load current character from kb data
		la $t1, kb_buf 		# load address of buffer
		lw $t2, kb_buf_size 	# current size of buffer
		#### end of code taken from [1] ####
		
		lw $t4, kb_buf_limit	# load the maximum size of buffer
		beq $t2, $t4, exitPoll	# if the buffer is full, exit
		
		#### start of code taken from [1] ####
		add $t1, $t1, $t2 	# move buffer pointer to next free spot
		sb $t3, 0($t1) 		# store byte (sb) character into buffer
		# update buffer metadata
		add $t2, $t2, 1 	# increment buffer size
		sw $t2, kb_buf_size 	# push new size back to memory
	exitPoll:
		j inputCheck 		# return to inputHandler
		#### end of code taken from [1] ####
		
	clearBuffer:			# while sizeBuffer != 0:
		la $t1, kb_buf 		# load address of buffer
		lw $t2, kb_buf_size 	# load current size of buffer	
		sb $zero, 0($t1)	# store null where bufferPointer is	
		subi $t1, $t1, 1	# bufferPointer++
		subi $t2, $t2, 1	# sizeBuffer--
		bnez $t2, clearBuffer	# if sizeBuffer == 0, exit loop
		sw $zero, kb_buf_size	# reset size in memory
		# if no move has been made, go back to waiting for input
		beq $t9, 0, inputHandler# if noMoreMoves == True, exit
	exitInput:
		li $t9, 0 		# resetting move check variable (noMoreMoves = 0)
		jr $ra			# returning inputHandler
	
	moveUp:
		la $a1, player		# fetching player adress
		lw $a2, 0($a1)		# loading player.x from memory
		lw $a3, 4($a1)		# loading player.y from memory
		
		# clearing old player position with empty space
		li $t3, 32		# ASCII 32 = ' '
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, ' ')
		move $ra, $s7		# loading stored return adress
		
		# updating player struct memory
		subi $a3, $a3, 1 	# player.y--
		sw $a3, 4($a1)		# saving player.y value to memory
		
		# writing 'P' in new player position
		li $t3, 80		# ASCII 80 = 'P'
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, 'P')
		move $ra, $s7		# loading stored return adress
		
		li $t9, 1 		# noMoreMoves = True
		j clearBuffer		# exiting
	moveDown:
		la $a1, player		# fetching player adress
		lw $a2, 0($a1)		# loading player.x from memory
		lw $a3, 4($a1)		# loading player.y from memory
		
		# clearing old player position with empty space
		li $t3, 32		# ASCII 32 = ' '
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, ' ')
		move $ra, $s7		# loading stored return adress
		
		# updating player struct memory
		addi $a3, $a3, 1 	# player.y++
		sw $a3, 4($a1)		# saving player.y value to memory
		
		# writing 'P' in new player position
		li $t3, 80		# ASCII 80 = 'P'
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, 'P')
		move $ra, $s7		# loading stored return adress
		
		li $t9, 1 		# noMoreMoves = True
		j clearBuffer		# exiting
	moveLeft:
		la $a1, player		# fetching player adress
		lw $a2, 0($a1)		# loading player.x from memory
		lw $a3, 4($a1)		# loading player.y from memory
		
		# clearing old player position with empty space
		li $t3, 32		# ASCII 32 = ' '
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, ' ')
		move $ra, $s7		# loading stored return adress
		
		# updating player struct memory
		subi $a2, $a2, 1 	# player.x--
		sw $a2, 0($a1)		# saving player.x value to memory
		
		# writing 'P' in new player position
		li $t3, 80		# ASCII 80 = 'P'
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, 'P')
		move $ra, $s7		# loading stored return adress
		
		li $t9, 1 		# noMoreMoves = True
		j clearBuffer		# exiting
	moveRight:
		la $a1, player		# fetching player adress
		lw $a2, 0($a1)		# loading player.x from memory
		lw $a3, 4($a1)		# loading player.y from memory
		
		# clearing old player position with empty space
		li $t3, 32		# ASCII 32 = ' '
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, ' ')
		move $ra, $s7		# loading stored return adress
		
		# updating player struct memory
		addi $a2, $a2, 1 	# player.x++
		sw $a2, 0($a1)		# saving player.x value to memory
		
		# writing 'P' in new player position
		li $t3, 80		# ASCII 80 = 'P'
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, 'P')
		move $ra, $s7		# loading stored return adress
		
		li $t9, 1 		# noMoreMoves = True
		j clearBuffer		# exiting
	
	# moves enemy towards reward
	enemyTurn:
		# loading enemy pos t0 (t1, t2)
		la $t0, enemy
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		# loading player pos to (t5, t6)
		la $t4, player
		lw $t5, 0($t4)
		lw $t6, 4($t4)
		# if current enemy is on updated player, dont clear current enemy pos before moving it 
		# t8 = 1 means dont clear, t8 = 0 means clear
		bne $t1, $t5, else5		# if enemy.x == player.x...
		bne $t2, $t6, else5		# ... and enemy.y == player.y set t8 to not clear
		li $t8, 1			# setting t8 to 1
	else5:
		# loading rewad pos to (t4, t5)
		la $t4, reward
		lw $t5, 0($t4)
		lw $t6, 4($t4)
		# comparing enemy pos to reward pos (in order to figure out where to move)
		blt $t1, $t5, enemyRight	# if enemy.x < reward.x, move right
		blt $t2, $t6, enemyDown		# if enemy.y < reward.y, move down
		blt $t5, $t1, enemyLeft		# if enemy.x > reward.x, move left
		blt $t6, $t2, enemyUp		# if enemy.y > reward.y, move up
		j exitEnemyTurn			# exiting function if no move can be made
	enemyRight:
		beq $t8, 1, ifNoClear1	# checking if we clear or not
		# moves cursor to (enemy.x, enemy.y) position and writes ' ' (space)
		addi $a2, $t1, 0	# carring over enemy.x
		addi $a3, $t2, 0	# carring over enemy.y
		li $t3, 32		# ASCII 32 for space char
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
	# this jump makes sure the P char is not cleared when the player is behind the enemy
	ifNoClear1:
		# updating enemy pos
		la $t0, enemy		# }
		lw $t1, 0($t0)		# } loading enemy pos to (t1, t2)
		lw $t2, 4($t0)		# }
		addi $t1, $t1, 1	# enemy.x++
		sw $t1, 0($t0)		# saving new enemy.x into memory
		
		# moves cursor to (enemy.x, enemy.y) position and writes 'E'
		addi $a2, $t1, 0	# carring over enemy.x
		addi $a3, $t2, 0	# carring over enemy.y
		li $t3, 69		# ASCII 69 for E char
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
		li $t8, 0		# resetting t8
		j exitEnemyTurn		# exiting function once a move has been made 
	enemyLeft:
		beq $t8, 1, ifNoClear2	# checking if we clear or not
		# moves cursor to (enemy.x, enemy.y) position and writes ' ' (space)
		addi $a2, $t1, 0	# carring over enemy.x
		addi $a3, $t2, 0	# carring over enemy.y
		li $t3, 32		# ASCII 32 for space char
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
	ifNoClear2:
		# updating enemy pos
		la $t0, enemy		# }
		lw $t1, 0($t0)		# } loading enemy pos to (t1, t2)
		lw $t2, 4($t0)		# }
		addi $t1, $t1, -1	# enemy.x--
		sw $t1, 0($t0)		# saving new enemy.x into memory
		
		# moves cursor to (enemy.x, enemy.y) position and writes 'E'
		addi $a2, $t1, 0	# carring over enemy.x
		addi $a3, $t2, 0	# carring over enemy.y
		li $t3, 69		# ASCII 69 for E char
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
		li $t8, 0		# resetting t8 
		j exitEnemyTurn		# exiting function once a move has been made
	enemyUp:
		beq $t8, 1, ifNoClear3	# checking if we clear or not
		# moves cursor to (enemy.x, enemy.y) position and writes ' ' (space)
		addi $a2, $t1, 0	# carring over enemy.x
		addi $a3, $t2, 0	# carring over enemy.y
		li $t3, 32		# ASCII 32 for space char
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
	ifNoClear3:
		# updating enemy pos
		la $t0, enemy		# }
		lw $t1, 0($t0)		# } loading enemy pos to (t1, t2)
		lw $t2, 4($t0)		# }
		addi $t2, $t2, -1	# enemy.y--
		sw $t2, 4($t0)		# saving new enemy.y into memory
		
		# moves cursor to (enemy.x, enemy.y) position and writes 'E'
		addi $a2, $t1, 0	# carring over enemy.x
		addi $a3, $t2, 0	# carring over enemy.y
		li $t3, 69		# ASCII 69 for E char
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
		li $t8, 0		# resetting t8 
		j exitEnemyTurn		# exiting function once a move has been made
	enemyDown:
		beq $t8, 1, ifNoClear4	# checking if we clear or not
		# moves cursor to (enemy.x, enemy.y) position and writes ' ' (space)
		addi $a2, $t1, 0	# carring over enemy.x
		addi $a3, $t2, 0	# carring over enemy.y
		li $t3, 32		# ASCII 32 for space char
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
	ifNoClear4:
		# updating enemy pos
		la $t0, enemy		# }
		lw $t1, 0($t0)		# } loading enemy pos to (t1, t2)
		lw $t2, 4($t0)		# }
		addi $t2, $t2, 1	# enemy.y++
		sw $t2, 4($t0)		# saving new enemy.y into memory
		
		# moves cursor to (enemy.x, enemy.y) position and writes 'E'
		addi $a2, $t1, 0	# carring over enemy.x
		addi $a3, $t2, 0	# carring over enemy.y
		li $t3, 69		# ASCII 69 for E char
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
		li $t8, 0		# resetting t8 
		j exitEnemyTurn		# exiting function once a move has been made
	exitEnemyTurn:
		jr $ra			# returning to main game loop
	
	# checking for collisions, in which case 'kill' the player by ending the game
	collisionCheck:
		# loading player pos
		la $t0, player		# player adress
		lw $t1, 0($t0)		# player.x
		lw $t2, 4($t0)		# player.y
		# checking for collision on x axis
		beq $t1, 0, end		# left wall
		addi $t3, $s1, -1	# right border: x = m - 1
		beq $t1, $t3, end	# right wall
		# checking for collision on y axis
		beq $t2, 0, end		# top wall
		addi $t3, $s0, -1	# bottom border: y = n - 1 (no offset for score cuz its built-in)
		beq $t2, $t3, end	# bottom wall
		# loading enemy pos
		la $t3, enemy		# enemy adress
		lw $t4, 0($t3)		# enemy.x
		lw $t5, 4($t3)		# enemy.y
		j condition7
	condition8:
		beq $t2, $t5, end		# (cond1) ... and player.y == enemy.y, end game
		j else4				# else continue
	condition7:
		beq $t1, $t4, condition8	# if player.x == enemy.x ... (cond2)
	else4:
		jr $ra			# returning to main game loop
		
	# clearing the whole screen using ASCII 12
	clearScreen:
		lw $t0, 0xffff0008	# Copy the control register into t0 register
		andi $t0, $t0, 1	# mask off all of the bits in $t0 except the ready bit
		li $a0, 12		# loading ASCII 12 char
		sb $a0, 0xffff000c($zero)	# copying 12 into the data register
		jr $ra			# returning clearScreen
	
	# prints 'GAME OVER' on screen
	gameOver:
		li $t5, 0		# i = 0
		li $t6, 9		# t6 = 9
		la $t4, gameOverText
	# enumerating gameOverText and prints each letter
	gameOverLoop:
		beq $t5, $t6, exitGameOver	# when i == 9, end loop
		lw $a0, ($t4)		# loading current letter
		# printing current letter on screen
		li $t0, 0		# resetting temp register
		li $a2, 0		# x = 0	(i gets added to it each loop)
		add $t0, $t0, $t4	# }
		add $a2, $a2, $t5	# } carring over letter pos and current letter
		li $a3, 0		# } 
		move $t3, $a0		# } 
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print current letter
		move $ra, $s7		# loading stored return adress
		add $t4, $t4, 4		# index++
		add $t5, $t5, 1		# i++
		j gameOverLoop
	exitGameOver:
		jr $ra			# returning gameOver
	
	# if reward has been collected, regenerate it and update score (both in memory and on-screen)
	rewardHandler:
		# checking if reward is not on top of player, in which case exit function
		la $t0, reward			# loading reward pos
		lw $t2, 0($t0)			# reward.x
		lw $t3, 4($t0)			# reward.y
		la $t1, enemy			# loading enemy pos
		lw $t4, 0($t1)			# enemy.x
		lw $t5, 4($t1)			# enemy.y
		bne $t2, $t4, else6		# if reward.x != player.x ...
		bne $t3, $t5, else6		# ... or reward.y != player.y, regen reward
		j enemyCollectedReward
	else6:
		la $t1, player			# loading player pos
		lw $t4, 0($t1)			# player.x
		lw $t5, 4($t1)			# player.y
		bne $t2, $t4, exitRewardHandler	# if reward.x != player.x ...
		bne $t3, $t5, exitRewardHandler	# ... or reward.y != player.y, regen reward
		# increasing score by 5
		la $t0, score		# loading score adress
		lw $t1, ($t0)		# loading score from memory
		addi $t1, $t1, 5	# score += 5
		sw $t1, ($t0)		# saving score to memory
	# respawns reward the same way, just without increasing score
	enemyCollectedReward:
		# generating reward using genReward
		move $s7, $ra		# storing return adress
		jal genReward		# generating reward
		move $ra, $s7		# loading stored return adress
		# printing reward on screen
		la $t0, reward		# } 
		lw $a2, 0($t0)		# } carring over reward pos and 'R' char
		lw $a3, 4($t0)		# } 
		li $t3, 82		# } 
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, 'R')
		move $ra, $s7		# loading stored return adress
		# update score on screen
		move $s6, $ra		# storing return adress
		jal printScore		# calling function to print updated score
		move $ra, $s6		# loading stored return adress
	exitRewardHandler:
		jr $ra		# return to game loop
		
	# moves cursor to ($a2, $a3) position and writes $t3
	cursorFunction:
		addi $t0, $a2, 0	# load x value
		mul $t1, $t0, 1048576	# bitshift x value 20 bits
		addi $t0, $a3, 1	# load y value
		mul $t2, $t0, 256	# bitshift x value 8 bits
		add $t2, $t2, $t1	# } 
		addi $t2, $t2, 7	# } adding x, y and 7 (ASCII bell) value 
		sw $t2, 0xffff000c($zero)	# Write to the Transmitter Data register
		
		# writing $t3 in (x, y)
		# # x = $a2	y = $a3
	wait2:	lw $t0, 0xffff0008	# control register
		andi $t0, $t0, 1	# preparing bits in $t0
		beq $t0, $zero, wait2	# if not ready, loop until ready
		move $a0, $t3		# $a0 = $t3
		sb $a0, 0xffff000c($zero)	# placing $a0 (=$t3) in data register
		
		jr $ra
		
	# updates score on display
	printScore:
		la $t0, score
		lw $t1, ($t0)
		div $t2, $t1, 10	# t2 = tens of score
		mul $t3, $t2, 10	# t3 = t2 * 10
		sub $t4, $t1, $t3	# t4 = ones of score
		
		li $t5, 6		# score.x in memory
		addi $a2, $t5, 0	# score.x passed in cursor function
		li $a3, -1		# score.y passed in cursor function
		bne $t2, 0, tens	# if score >= 10, print tens
	ones:
		# printing ones
		add $t3, $t4, 48	# carring over letter pos and current letter
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
		j exitPrintScore
	tens:
		# printing tens
		beq $t2, 10, hundreds	# if score == 100, prints hundreds
	tensContinue:
		add $t3, $t2, 48	# carring over letter pos and current letter
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
		addi $t5, $t5, 1	# score.x++
		addi $a2, $t5, 0	# score.x updated
		li $a3, -1		# score.y 
		j ones			# print ones after tens
	hundreds:
		# printing hundreds
		add $t3, $zero, 49	# carring over letter pos and current letter
		move $s7, $ra		# storing return adress
		jal cursorFunction	# print(reward, letter)
		move $ra, $s7		# loading stored return adress
		li $t2, 0		# making sure tens prints 0
		addi $t5, $t5, 1	# score.x++
		addi $a2, $t5, 0	# score.x updated
		li $a3, -1		# score.y 
		j tensContinue		# print tens after hundreds
	
	exitPrintScore:
		jr $ra			# returning to game loop
							
	# [1] Lecture 15-1, IO and Interrupts, James Stovold (2024)
