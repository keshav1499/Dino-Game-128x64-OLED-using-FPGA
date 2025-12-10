
# 🐱 Dino Kitty Jump Game (Verilog – FSM Driven Hardware Game!)

Welcome to **Dino Kitty Jump**, a retro-style side-scroller game implemented **entirely in Verilog HDL** and driven by a clean, scalable **Finite State Machine (FSM)** architecture!

This project demonstrates how real hardware games are built:  
**no CPU, no software loop — just pure digital logic running on FPGA fabric.**

Kitty jumps, obstacles move, collisions are detected, and screens render smoothly…  
all by HDL logic synthesized into real gates!

---

## 🎮 Gameplay

Your mission?  
**Help Kitty jump over obstacles** as they scroll toward her!

- Press the button (active-low) → Kitty Jumps  
- Collision → Game Over Screen  
- Press button again → Return to Start Screen  
- Another press → Begin Gameplay

Everything — jumping, running, game-over, and start screen transitions — is controlled by a **properly designed FSM**, making the game modular, scalable, and easy to extend.

---

## 🧠 Features

### ⚙️ **Full FSM-Based Game Architecture**
Both the **gameplay controller** and parts of the **display driver** use FSMs:

- **START → PLAY_RUNNING → PLAY_JUMP → GAME_OVER**
- Clean transitions triggered by button presses (active-low)
- Per-frame timing using `frameNumber` as a pseudo-clock
- Deterministic hardware timing, just like real VLSI digital blocks

### 🐱 Cat Sprite Rendering
- Sprite stored in `cat_sprite.hex`
- Rendered directly via memory lookup in hardware

### ⬆️ Jump Mechanics (FSM-Driven)
- Jump is now a **state**, not just an offset  
- Jump duration controlled by a frame counter inside the FSM

### 📺 SSD1306-Compatible Rendering
- Renders per-pixel patterns based on `pixelIndex`
- Smooth and crisp cat + obstacle graphics

### 💥 Collision Detection
- Hardware collision check using bounding box logic  
- Collision immediately transitions FSM → `GAME_OVER`

### 🚧 Obstacle Motion
- Obstacle moves using frame-synced arithmetic  
- No timers or delays — pure synchronous logic

---

## 🛠️ Hardware Requirements

- Any FPGA with sufficient LUTs/BRAM  
- 27 MHz clock input (modifiable)  
- Active-low push button  
- 128×64 SSD1306 OLED display  
- **GOWIN IDE + Gowin Programmer** (required for synthesis & uploading)

Tested on:

- **Tang Nano 9K** (GW1NR-9)

---

## 🧩 Project Structure

| File | Description |
|------|-------------|
| `jump_controller.v` | Old jump logic (now replaced by FSM-based jump inside game logic) |
| `pattern_generator.v` | **Main game FSM + sprite rendering + collision logic** |
| `screen_driver.v` | FSM-based pixel scanning & OLED page/column management |
| `cat_sprite.hex` | Cat sprite data |

---
```

## 🧠 FSM Overview (Core of the Game)
┌────────────┐ button press ┌──────────────┐
│ START │ ───────────────────▶ │ PLAY_RUNNING │
└────────────┘ └──────┬──────┘
│ collision
button press ▼
┌────────────────┐
│ GAME_OVER │
└──────┬─────────┘
button press
▼
START
```


The jump is handled as a **sub-state** (`PLAY_JUMP`), giving you true scalability:
- Easy to add crouch, dash, slide, double-jump, animations, etc.

---

## ▶️ How to Run

1. Place all Verilog files + HEX assets in the same directory  
2. Open **GOWIN IDE** and import the project  
3. Run *Synthesis → Place & Route → Bitstream*  
4. Upload using **Gowin Programmer**  
5. Wire the OLED pins:
  sclk, sdin, cs, dc, reset → FPGA pins
6. Apply 27 MHz clock (or adjust FRAME_WAIT in driver)  
7. **Enjoy your hardware game! 😺🚀**

---

## 🎥 Demo Videos

https://github.com/user-attachments/assets/462362f6-1a91-4478-90f4-576457fc8292

https://github.com/user-attachments/assets/f4562319-32f7-4648-b21a-2510d46d8811
