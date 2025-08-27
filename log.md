# Project Log
Created: 2025-08-25T20:20:27.552Z

## How To Use
Every hour you work on your project, you need to log it! A log should include the date, time started and time finished, what you added or changed, an image of your current game, and any other relevant information to prove you worked for an hour during that time. In addition, you need to commit every hour after writing your log.

## Why Do This
We need you to log your work to verify that you worked on your project for an x amount of time! We will be reviewing your log and and your project. If we find that your hours seem inflated, you seem to be doing fraud, or you didn't log your hours correctly, we reserve the right to reject some hours from your log or all hours. Please make sure you're corectly logging your hours.

## Log

### Entry 1 - 2 hours 35 min
Date: 8/26/2025
Time range: 15:10 - 17:45
Description: Added a square the player can move with the gamepad. It took forever to get the vga working because it gave some stupid "XML" error whenever i had certain parts of code that only fixed itsef when i changed the rgb outputs to be a "reg". I didn't realize there was even an error tho until like like 20 mins into debugging because it was at the top for some reason :sob:
Once I got a pixel displaying The controls were way too fast so I tried to limit it to once per frame like the flappy bird example but for some reason I couldn't get it to work until I realized the flappy bird example had the "reset" variable negated (acting like "reset_n")
![video](https://hc-cdn.hel1.your-objectstorage.com/s/v3/c26833a6ed819d19de6d1bf33b0f2aa1cc7c0db3_2025-08-26_18-46-59.mp4)

### Entry 2 - 1 hours 25 min
Date: 8/26/2025
Time range: 19:15 - 20:40
Description: I changed the display code to upscale the positions returned by the game logic and draw a background on valid cells. I had to add paramaters to the snak_logic and vga_display modules but otherwise its not too big a change. I may make them wires later to allow for playing many size games, but I would need to calculate or hardcode scale factors for each size.
![screenshot](https://hc-cdn.hel1.your-objectstorage.com/s/v3/31b8956596b8d1fcae11fa939c30927e146e5bd5_image.png)

### Entry 3 - x hours x min
Date: 8/27/2025
Time range: 15:30 - x
Redid logic to store a grid of snake states. I figured out that representing the snake position would take 4 bytes (4'b0000) is invalid (double up) so it can be used to indicate absense. For now I decided to only use one bit to indicate presence and add the full states later.
![screenshot](https://hc-cdn.hel1.your-objectstorage.com/s/v3/c6005d70e4fd2d383cf42e4a6ea0aa7771dec073_image.png)
