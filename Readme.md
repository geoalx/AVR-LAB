# ADC Read, Display and PWM on ATMega16

[![Microchip Studio](https://img.shields.io/badge/built%20with-Microchip%20Studio-orange)](https://www.microchip.com/en-us/tools-resources/develop/microchip-studio)
[![ATMega16](https://img.shields.io/badge/built%20for-ATMega16-red)](https://www.microchip.com/en-us/product/ATmega16)

This project is a part of a course "Microcontrollers Lab" of National Technical University of Athens. The grade of this project was 10/10. 

## Abstract

This project was built for the [ATmega16](https://www.microchip.com/en-us/product/ATmega16) microcontroller and to be compatible with [EasyAVR6](https://www.mikroe.com/easyavr6) development board.

### Exercise 1

The goals of this project was:

- Read ADC input and display it with 2 decimal precision.
- Increase the PB3 duty cyrcle by 1 while pressing the button "1" in the keypad.
- Decrease the PB3 duty cyrcle by 1 while pressing the button "2" in the keypad.

The duty circle of the  PWM has a 4kHz frequency.

The code for this project is written in C with imported functions written in AVR Assembly.

### Exercise 2

The goals of this project was:
 - Read ADC value from a CO gas sensor every 100ms and display it in led as levels.
 - If value is above a certain ammount (70 ppm) print "GAS DETECTED" on a screen and if levels drops again print "CLEAR".
 - If password "14" is pressed on the keypad print "WELCOME 14" and open a certain LED for 4 seconds. If password is incorrect blink led for 4 seconds (0.5 second on, 0.5 second off).

The code for whis exercise is written both in C and AVR Assembly.