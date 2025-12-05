# HtmlGame — CyberMonkeyArcade (Gomoku + Breakout)
2nd Project for learning code
 
A beginner-friendly web mini-arcade: **Gomoku (Five-in-a-row) vs AI cyberpunk monkey** + **Breakout** in one page, with a neon cyberpunk UI and an animated attractor background video.

## Features
- 🎮 **2-in-1 Arcade**
  - Gomoku: Human vs AI (Easy / Normal / Hard)
  - Breakout: Keyboard-controlled brick breaker
- 🌌 **Cyberpunk UI**: neon colors, glassy panels, glow effects
- 🦋 **Attractor Background**: Manim-rendered Lorenz attractor video (`/static/attractor.mp4`)
- 🔊 Simple sound effects + turn timer (Gomoku)

## Quick Start (macOS)
### 1) Create and activate a virtual environment
```bash
cd /Users/gaochao/PycharmProjects/MonkeyGo
python3 -m venv .venv
source .venv/bin/activate
2) Install dependencies
bash
复制代码
pip install -U pip
pip install flask
3) Run the server
bash
复制代码
python -m backend.app
4) Open in browser
Visit: http://127.0.0.1:5000

How to Play
Gomoku (Five-in-a-row)
Click on the board to place a piece.

Make 5 in a row (horizontal / vertical / diagonal) to win.

Difficulty:

Easy: more random mistakes

Normal: heuristic-based

Hard: shallow two-step lookahead

Turn timer: if time runs out, the system places a random move to prevent freezing.

Breakout
Move paddle: Left/Right arrow or A/D

Start/Pause: Space

Break all bricks to clear the stage.

Project Structure
php
复制代码
HtmlGame/
├─ backend/
│  ├─ app.py            # Flask server + API endpoints
│  ├─ game.py           # Gomoku rules + win checking
│  └─ ai_monkey.py      # AI logic (easy/normal/hard)
├─ frontend/
│  ├─ templates/
│  │  └─ index.html     # Main page (menu + two games)
│  └─ static/
│     ├─ style.css      # Cyberpunk UI styles
│     ├─ menu.js        # Switch between games
│     ├─ gomoku.js      # Gomoku canvas + UI logic
│     ├─ breakout.js    # Breakout game
│     └─ attractor.mp4  # Manim-rendered background video
└─ manim_scenes/
   └─ cyber_attractor.py # Manim script to render attractor.mp4
Notes (Manim Video Background)
The background video file is served at: /static/attractor.mp4

If it’s missing, the UI still works; only the animated background disappears.

Troubleshooting
1) Browser can’t open the page
Make sure Flask is running:

bash
复制代码
curl -I http://127.0.0.1:5000
If port is occupied, stop the old process or change port.

2) Background video covers UI
The fix is in style.css:

.bg-video { pointer-events: none; z-index: 0; }

body::before overlay uses z-index: 1

.app uses z-index: 2

Learning Goals (Why this project exists)
Practice building a small web app with:

HTML/CSS layout

Canvas rendering

Frontend ↔ Backend communication with fetch

Basic game loops and state management

Simple AI heuristics
