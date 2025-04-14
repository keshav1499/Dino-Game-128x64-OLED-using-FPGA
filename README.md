# 🐱 Dino Kitty Jump Game (Verilog)

Welcome to **Dino Kitty Jump**, a retro-style side-scroller game implemented in **Verilog HDL**. This adorable cat isn’t just cute—it jumps, dodges obstacles, and flashes with flair when hit!

Designed for FPGA boards with basic ouput support, this project is a great demonstration of sprite rendering, animation, collision detection, and game logic in hardware.

---

## 🎮 Gameplay

Just like the classic dino game, your goal is to **jump over oncoming obstacles**. Press the button to make Kitty jump. If she crashes into an obstacle, the screen flashes white, and the game continues.

- Obstacle animation synced with frame count
- Smooth jumping with 5 vertical levels
- Simple sprite rendering using block RAM
- White screen flash on collision

---

## 🧠 Features

- 🐱 **Cat Sprite Rendering** using `cat_sprite.hex`
- ⬆️ **Smooth Jump Logic** using a 3-bit `jumpOffset`
- 📺 **SSD1306-OLED-compatible pixel rendering**
- 💥 **Collision Detection + White Flash Effect**
- ⏱️ **Frame-synced Animation** using `frameNumber`
- 💾 Memory-based sprite loading via `$readmemh`

---

## 🛠️ Hardware Requirements

- FPGA board (any)
- ~27 MHz clock input  (can be modified)
- Push button input (active low)  
- 128×64 resolution SSD1306 based display

Tested on:
- Tang Nano 9k(Gowin GW1NR-9)

---

## 🧩 Project Structure

| File |               | Description |
|------|-------------|
| `jump_controller.v` | Handles smooth jump transitions with timing logic |
| `pattern_generator.v` | Generates sprite & background patterns per pixel |
| `screen_driver.v` | Converts pixel index to screen coordinates (not shown here) |
| `cat_sprite.hex` | Sprite data for the jumping cat (2 rows × 16 cols) |

---

## ▶️ How to Run

1. Just synthesize the code on your PC, keep all files from src folder
2. Make the necessary connections from top module to the OLED (sclk,sdin,cs,dc,reset), connect these to real world pins
3. Ensure the clock is 27MHZ or change the parameters, e.g FRAME_WAIT... according to your own clock
4. Game ON!!!!


   This is how it plays:

https://github.com/user-attachments/assets/f4562319-32f7-4648-b21a-2510d46d8811


