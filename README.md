# 2D Game in Assembly

This project is a small 2D game implemented in MIPS assembler and runtime simulator. The game features a player, an enemy and a reward system, displayed on a grid map. The player moves (WASD) to collect rewards while avoiding the enemy, who also chases it. The game ends when the player either achieves a score of 100 or dies by colliding with the enemy or the border of the map.

## Features

- The game is played on a 6x8 grid.
- The player can move up, down, left, or right using the keyboard.
- Whenever the player makes a move, the enemy also makes a move towards the reward.
- Collect rewards (marked as `R` on the map) to increase your score while avoiding the enemy (marked as `E`).
- Reach a score of 100 to win the game.
- Collide with the enemy or the map border.

## Installation

### Dependencies

- [JDK (Java J2SE 1.5 or later)](https://www.oracle.com/java/technologies/downloads/)
- [MARS 4.5](https://dpetersanderson.github.io/download.html)
- Download `game_playerVsEnemy.asm` from this repo.

All need to be installed in order to run the game.

### Running the Game

1. Open MIPS simulator(Mars4_5.jar).
2. Open the `game_playerVsEnemy.asm` file in MARS.
3. Assemble the program.
4. Under Tools, open `Keyboard And Display MMIO Simulator` and press `Connect to MIPS`.
5. Run the program.

- To control your character, write in the text box w, a, s or d to move up, left, down or right.

- To restart the game:

1. Stop running the program.
2. Disconnect, then reset the `Keyboard And Display MMIO Simulator`.
3. Reset MIPS memory and registers(the button with two arrows pointing left).
4. Connect the `Keyboard And Display MMIO Simulator`.
5. Run the program.

## Screenshots

### Game is 🏃‍♂️ :

![](/images/game-running.png)


### Game over screen:

![](/images/game-over.png)


## License

This project is licensed under the MIT License. See the `LICENSE` file for details.