# Videopac G700 / Odyssey2 for FPGA.

### This is an FPGA implementation of the Magnavox Oddysey2/Videopac G700 based on FPGA videopac by Arnim Laeuger and ported to MiSTer (With additional work from wsoltys) by [Jamie Dickson](https://github.com/Kitrinx).

## Features
 * Switch between Odyssey2 and Videopac mode.
 * Fully working keyboard.
 * Joystick buttons for keys 0-9.
 * Composite/RGB palettes.
 * loadable **VDC ROM charset** for some custom roms.
 * Correct Sound, timings and better collision detection.
 * "The Voice" peripheral (alpha).
 * available for **MiSTer**,**MiST** and **SiDi** FPGA. (more to come).
 

## Installation
Copy the *.rbf file to your SD card. Create an **Videopac** folder on the card, and place Odyssey2/Videopac roms (\*.BIN) inside this folder. XROM dumps (at the moment only known Musician and 4 in a row) must be renamed to \*.rom.

When loading a ROM, most games will prompt the user with "SELECT GAME". Press 0-9 on the keyboard or mapped controller button to play the game. Unfortunately, there is no on-screen display of the game options, so looking at the [instruction manuals](https://videopac.weebly.com/) may be helpful in selecting a game. Note that the system did not have a well defined player 1 or player 2 controller, they would alternate on a game-to-game basis. You may need to swap controllers to use the input.

## Known Issues

* The roms of "**the voice**" need to be replaced by the origial ones.
* Still a few glitches.

## Thanks to:

* **René van den Enden** Videopac guru. helped us via email and posted lots of information on [videopac.nl](http://www.videopac.nl)
* **Mejias3D** Support on videopac internals and 8048 assembler programming.
* **avlixa** For the **ZXDOS** port.
* **Antonio Sanchez** For the LX16 port.
* **Wilco2009** For the SD-cart for the real console and for helping with hardware internals and tricks his [sd cartridge](https://wilco2009.blogspot.com/2020/) for the real console is a must!.

## Some ROMS.
*  You can download almost all the console roms from the [René van dem Enden](http://www.ozyr.com/rene/VP_O2-roms777.zip) site. This .zip file contains 220 games and is 765 kB. 
* Also the **wilco2009** SD collection [here](https://1drv.ms/u/s!Avo9sa7McTNBjbJPgZ2FjR_3bj3Pig). 
