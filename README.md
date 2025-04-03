Project Description:
A dynamic platformer game where the player must escape rising water by navigating platforms and collecting power-ups. Written in MIPS Assembly for the CSCB58 course.

Key Features Implemented:

Pickup Effects

Gold Boxes: Lower water level by 2 units

Silver Boxes: Double jump height (20 units)

Red Boxes: Increase player health

Moving Hazards

Water rises continuously with increasing speed:
Level 1: 30ms/line Level 2: 15ms/line Level 3: 9ms/line

Progressive Levels

3 distinct levels with:

Increasing platforms (5→7→9)

More collectibles (4→6→8)

Faster water speeds

Health System

4 heart containers displayed bottom-left

Water contact reduces health

Health packs restore hearts

Technical Specifications:

Display: 256x256 pixels (64x64 units)

Unit Size: 4x4 pixels

Base Address: 0x10008000 ($gp)

Built using MARS MIPS simulator

Controls:

A: Move left

D: Move right

W: Jump (normal 14 units/double 20 units)

R: Restart game

Q: Quit game

How to Play:

Collect all boxes to unlock next level

Avoid touching the rising water

Use silver boxes for big jumps

Reach the top platforms before water rises

Setup & Running:

Use MARS simulator with:

Bitmap Display (configured to spec)

Keyboard input

Assemble and run the .asm file

Press R to start

Video Demonstration:
[Insert YouTube/MyMedia URL here]

Author: Sheharyar Meghani (1009830195)
Course: CSCB58 Winter 2025 - University of Toronto Scarborough
