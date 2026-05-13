Brick Breaker — 8086 Assembly (DOS / VGA Mode 13h)

A fully playable arcade Brick Breaker game written entirely in **16-bit x86 Assembly** for DOS, using **VGA Mode 13h (320×200, 256 colors)**. No C, no libraries — every pixel is pushed directly to video memory at `A000:0000`. Built as a semester project for the Computer Organization & Assembly Language (COAL) course at FAST-NUCES Islamabad.

> **Course:** EE-2003 — Computer Organization and Assembly Language  
> **Program:** BS Software Engineering, Semester 4, Spring 2026  
> **Authors:** Muhammad Bilal, Hafiza Eshal Fatima, Rana Hanan Shafique

---

## What's in the game

Three levels, each with a completely different brick layout.
- A full grid in Level 1

<img width="647" height="398" alt="image" src="https://github.com/user-attachments/assets/4f228626-883b-41e8-adfe-8e627d921e3f" />

- A checkerboard with grey barrier bricks in Level 2.
- 
  <img width="642" height="400" alt="image" src="https://github.com/user-attachments/assets/2b445812-f2c6-4c8d-b43f-08ca117c70b1" />

- A diamond/fortress pattern in Level 3. Grey barrier bricks are indestructible; they bounce the ball without breaking.

<img width="641" height="395" alt="image" src="https://github.com/user-attachments/assets/46871415-7068-4aeb-a123-94eac763e33e" />

- The ball physics try to feel like classic arcade Breakout. The paddle is split into zones — hitting the center sends the ball straight up, while hitting toward the edges deflects it at progressively wider angles. If the paddle is moving at the moment of impact, it nudges the ball horizontally in that direction. Brick collisions use the ball's previous-frame position to figure out whether entry was horizontal or vertical, so side hits reverse `dx` instead of `dy`.

<img width="824" height="578" alt="image" src="https://github.com/user-attachments/assets/ca8c6947-6d8d-438d-bdc1-c717541633a0" />

Power-ups drop from broken bricks at random. Four types: Slow Ball (cyan), Fast Ball (red), Extra Life (green), and Wider Paddle (yellow). A falling power-up that misses the paddle just disappears.

Other things worth mentioning:
- A 3-position fading ball trail for visual feedback
- PC speaker sound effects for paddle hits, brick breaks, and life loss
- Mouse support via `INT 33h` alongside keyboard (Left/Right or A/D)
- A custom 5×7 bitmap font for all in-game text, since `INT 10h AH=09h` doesn't work in graphics mode
- HUD that only redraws score and lives when they actually change
- An LCG-based PRNG (`state * 25173 + 13849`) for power-up spawn chances
- Frame pacing tied to the BIOS tick counter so speed doesn't depend on CPU

---

## Screens

The game has all six required screens plus a few extras:

- Home screen with name entry
- Main menu (Start, Instructions, High Scores, Exit) with arrow-key navigation
- Instructions screen
- High scores screen (in-memory, not saved to disk)
- Gameplay screen with HUD bar at the top
- Pause overlay (press P)
- Level transition screen between levels
- Game Over screen with final score
- Win / Congratulations screen after clearing Level 3

---

## Controls

| Input | Action |
|---|---|
| ← / → or A / D | Move paddle |
| Mouse | Move paddle (smooth tracking) |
| Space | Launch ball |
| P | Pause / Resume |
| Esc | Quit to menu |
| Enter | Confirm selection |

---

## Building and running

You need MASM 6.x (or TASM 5+) and DOSBox. A mouse driver like `CTMOUSE.EXE` is optional but recommended if you want mouse input.

**With MASM in DOSBox:**

```bat
mount c c:"path\to\project\folder"
c:
masm final_game.asm
final_game.exe
```

**With TASM:**

```bat
tasm final_game.asm
tlink /t final_game.obj
final_game.com
```

**Enabling the mouse in DOSBox** — add this to your `dosbox.conf` autoexec section before launching the game:

```
CTMOUSE.EXE
```

---

## Project structure

```
i243152_i243168_i243169_COAL_Iteration3/
├── final_game.asm     # Full source (~4500 lines)
├── HIGHSCOR.DAT
├── LINK.EXE
├── OBJ.EXE
├── TASM.EXE
└── masm
```

The ASM file is organized in sections rather than one flat block of code:

1. Data segment — game state variables, brick layout arrays, palette, font data, strings
2. Graphics primitives — `DRAW_RECT`, `DRAW_RECT_BORDER`, `CLEAR_SCREEN`
3. Text rendering — `DRAW_CHAR`, `DRAW_STRING`, `ITOA`, `STRLEN`
4. HUD — `DRAW_HUD_STATIC`, `UPDATE_HUD_VALUES`
5. Ball and trail — `DRAW_BALL`, `ERASE_BALL`, `UPDATE_TRAIL`
6. Paddle — `DRAW_PADDLE`, `ERASE_PADDLE`
7. Bricks — `DRAW_BRICKS`, `BRICK_BREAK_FX`
8. Power-ups — `SPAWN_POWERUP`, `UPDATE_POWERUP`, `APPLY_POWERUP`
9. Collision — `CHECK_PADDLE_COLLISION`, `CHECK_BRICK_COLLISION`
10. Physics — `MOVE_BALL`, `REPAIR_WALLS`, `REDRAW_BARRIERS_NEAR_BALL`
11. Sound — `SND_PADDLE`, `SND_WALL`, `SND_BRICK`, `SND_POWERUP`, `SND_LIFE_LOST`
12. Screens — `SHOW_GAME_SCREEN`, `SHOW_INSTRUCTIONS`, `SHOW_HIGH_SCORES`, `SHOW_FINAL_WIN`, etc.
13. Entry point and menu loop

---

## Known limitations

- 16-bit real mode only — requires DOS or DOSBox
- High scores are not saved to disk; they reset when the program exits
- Sound is PC speaker only, no sound card support
- No Windows or Linux native build

---

## Authors

| Roll Number | Contribution |
|---|---|
| i24-3168 | Muhammad Bilal |
| i24-3152 | Hafiza Eshal Fatima |
| i24-3169 | Rana Hanan Shafique |

FAST-NUCES Islamabad — BS Software Engineering, Spring 2026
