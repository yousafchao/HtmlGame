set -euo pipefail

cd /Users/gaochao/PycharmProjects/MonkeyGo

mkdir -p backend frontend/templates frontend/static manim_scenes
touch backend/__init__.py

cat > backend/app.py <<'PY'
# -*- coding: utf-8 -*-
from __future__ import annotations
from flask import Flask, jsonify, request, render_template
from backend.game import GameState, HUMAN, MONKEY
from backend.ai_monkey import monkey_choose_move

app = Flask(__name__, template_folder="../frontend/templates", static_folder="../frontend/static")
state = GameState()

@app.get("/")
def index():
    return render_template("index.html")

@app.post("/api/new")
def api_new():
    data = request.get_json(silent=True) or {}
    difficulty = str(data.get("difficulty", "normal"))
    if difficulty not in ("easy", "normal", "hard"):
        difficulty = "normal"
    state.reset(difficulty=difficulty)
    return jsonify(state.to_dict())

@app.post("/api/move")
def api_move():
    data = request.get_json(silent=True) or {}
    r = int(data.get("row", -1))
    c = int(data.get("col", -1))

    if state.winner != 0:
        return jsonify(state.to_dict())

    if state.current != HUMAN:
        return jsonify(state.to_dict())

    ok = state.place(r, c, HUMAN)
    if not ok:
        return jsonify({**state.to_dict(), "error": "落子无效：请点空格子。"})

    if state.winner != 0:
        return jsonify(state.to_dict())

    if state.current == MONKEY:
        mr, mc = monkey_choose_move(state)
        state.place(mr, mc, MONKEY)

    return jsonify(state.to_dict())

@app.get("/api/state")
def api_state():
    return jsonify(state.to_dict())

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
PY

cat > frontend/templates/index.html <<'HTML'
<!doctype html>
<html lang="zh">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>CyberMonkey Arcade</title>
  <link rel="stylesheet" href="/static/style.css">
</head>
<body>
  <div class="bg">
    <video class="bg-video" autoplay muted loop playsinline>
      <source src="/static/attractor.mp4" type="video/mp4">
    </video>
    <div class="bg-overlay"></div>
  </div>

  <div class="app">
    <div id="menu" class="menu">
      <div class="card">
        <div class="logo">CYBER<span class="accent">MONKEY</span> GO</div>
        <div class="sub">五子棋（人类 vs 赛博猴子AI）｜背景由 Manim 预渲染吸引子视频</div>
        <div class="row">
          <span>难度</span>
          <select id="difficulty">
            <option value="easy">简单</option>
            <option value="normal" selected>普通</option>
            <option value="hard">困难</option>
          </select>
        </div>
        <div class="row">
          <button id="startBtn">进入五子棋</button>
          <button id="soundBtn" class="ghost">音效：开</button>
        </div>
        <div id="menuTip" class="tip">进入后会自动“新开一局”。</div>
      </div>
    </div>

    <div id="shell" class="shell hidden">
      <div class="top">
        <div class="title">CyberMonkeyGo</div>
        <button id="backBtn" class="ghost">返回菜单</button>
      </div>

      <div class="main">
        <div class="left">
          <canvas id="boardCanvas" width="720" height="720"></canvas>
          <div class="hint">点击棋盘交叉点落子（你先手）。</div>
        </div>
        <div class="right">
          <div class="card">
            <div class="row">
              <button id="newGameBtn">新开一局</button>
            </div>
            <div class="row">
              <div class="pill">回合：<span id="turnText">-</span></div>
              <div class="pill">计时：<span id="timerText">-</span>s</div>
            </div>
            <div class="status" id="statusText">准备就绪。</div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <script src="/static/menu.js"></script>
  <script src="/static/gomoku.js"></script>
</body>
</html>
HTML

cat > frontend/static/style.css <<'CSS'
body{margin:0;color:#d7e7ff;font-family:system-ui,-apple-system,"PingFang SC","Microsoft YaHei",Arial;background:#000}
.bg{position:fixed;inset:0;z-index:-3;overflow:hidden}
.bg-video{position:absolute;inset:-10%;width:120%;height:120%;object-fit:cover;filter:saturate(1.25) contrast(1.1) brightness(0.55)}
.bg-overlay{position:absolute;inset:0;background:radial-gradient(circle at 20% 10%,rgba(26,8,74,.55) 0%,rgba(5,1,15,.75) 45%,rgba(0,0,0,.92) 100%)}
.app{max-width:1200px;margin:0 auto;padding:18px}
.menu{display:flex;align-items:center;justify-content:center;min-height:calc(100vh - 36px)}
.shell{display:block}
.hidden{display:none !important}
.card{border-radius:16px;border:1px solid rgba(120,200,255,.25);background:rgba(6,8,20,.68);padding:16px;box-shadow:0 0 26px rgba(0,255,255,.08);width:min(640px,100%)}
.logo{font-weight:900;letter-spacing:2px;font-size:22px;text-shadow:0 0 14px rgba(0,255,255,.35)}
.accent{color:#ff4fd8;text-shadow:0 0 14px rgba(255,79,216,.5)}
.sub{opacity:.9;margin-top:8px;line-height:1.5}
.row{display:flex;align-items:center;justify-content:space-between;gap:10px;margin-top:12px}
select{background:rgba(0,0,0,.45);color:#d7e7ff;border:1px solid rgba(120,200,255,.25);border-radius:10px;padding:8px 10px;outline:none}
button{background:linear-gradient(90deg,rgba(0,255,255,.22),rgba(255,79,216,.18));color:#d7e7ff;border:1px solid rgba(120,200,255,.25);border-radius:12px;padding:10px 12px;cursor:pointer;font-weight:800}
button.ghost{background:rgba(0,0,0,.25)}
.top{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px}
.title{font-weight:900;letter-spacing:1px}
.main{display:grid;grid-template-columns:1fr 340px;gap:16px}
.left{border-radius:16px;border:1px solid rgba(120,200,255,.22);background:rgba(6,8,20,.55);padding:14px}
.right{display:flex;flex-direction:column;gap:14px}
#boardCanvas{width:100%;height:auto;border-radius:14px;background:radial-gradient(circle at 50% 35%,rgba(0,255,255,.08),rgba(255,79,216,.05),rgba(0,0,0,.35));display:block}
.hint{margin-top:10px;font-size:13px;opacity:.85}
.pill{padding:8px 10px;border-radius:999px;border:1px dashed rgba(120,200,255,.25);background:rgba(0,0,0,.25);font-size:13px}
.status{margin-top:12px;padding:10px;border-radius:12px;background:rgba(0,0,0,.28);border:1px solid rgba(255,255,255,.06);min-height:52px;line-height:1.4}
.tip{margin-top:10px;font-size:12px;opacity:.8}
@media (max-width:980px){.main{grid-template-columns:1fr}}
CSS

cat > frontend/static/menu.js <<'JS'
const menu=document.getElementById("menu");
const shell=document.getElementById("shell");
const startBtn=document.getElementById("startBtn");
const backBtn=document.getElementById("backBtn");
const soundBtn=document.getElementById("soundBtn");

if(window.__CYBER_SOUND_ON__===undefined) window.__CYBER_SOUND_ON__=true;
soundBtn.textContent = window.__CYBER_SOUND_ON__ ? "音效：开" : "音效：关";

soundBtn.addEventListener("click",()=>{
  window.__CYBER_SOUND_ON__=!window.__CYBER_SOUND_ON__;
  soundBtn.textContent = window.__CYBER_SOUND_ON__ ? "音效：开" : "音效：关";
});

startBtn.addEventListener("click",()=>{
  menu.classList.add("hidden");
  shell.classList.remove("hidden");
  if(window.gomokuInit) window.gomokuInit();
});

backBtn.addEventListener("click",()=>{
  if(window.gomokuStop) window.gomokuStop();
  shell.classList.add("hidden");
  menu.classList.remove("hidden");
});
JS

cat > frontend/static/gomoku.js <<'JS'
const canvas=document.getElementById("boardCanvas");
const ctx=canvas.getContext("2d");
const newGameBtn=document.getElementById("newGameBtn");
const difficulty=document.getElementById("difficulty");
const statusText=document.getElementById("statusText");
const turnText=document.getElementById("turnText");
const timerText=document.getElementById("timerText");

let gameState=null;
let timerId=null;
let turnSeconds=15;
let timeLeft=turnSeconds;

let audioCtx=null;
function beep(freq,durMs){
  if(window.__CYBER_SOUND_ON__===false) return;
  if(!audioCtx) audioCtx=new(window.AudioContext||window.webkitAudioContext)();
  const o=audioCtx.createOscillator();
  const g=audioCtx.createGain();
  o.type="sine";
  o.frequency.value=freq;
  g.gain.value=0.05;
  o.connect(g);
  g.connect(audioCtx.destination);
  o.start();
  setTimeout(()=>o.stop(),durMs);
}

function setStatus(msg){statusText.textContent=msg;}

function stopTimer(){if(timerId) clearInterval(timerId); timerId=null;}
function resetTimer(){
  stopTimer();
  timeLeft=turnSeconds;
  timerText.textContent=String(timeLeft);
  timerId=setInterval(()=>{
    timeLeft-=1;
    timerText.textContent=String(Math.max(0,timeLeft));
    if(timeLeft<=0){stopTimer(); setStatus("⌛ 你超时了：继续落子或点“新开一局”。");}
  },1000);
}

function updateTurnText(){
  if(!gameState){turnText.textContent="-"; return;}
  turnText.textContent = (gameState.current===1) ? "你（人类）" : "赛博猴子";
}

async function apiNewGame(){
  try{
    const res=await fetch("/api/new",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({difficulty:difficulty.value})});
    gameState=await res.json();
    setStatus("新对局开始：你先手。");
    updateTurnText();
    resetTimer();
    drawAll();
  }catch(e){
    setStatus("无法连接后端：请确认终端里正在运行 python -m backend.app");
  }
}

async function apiMove(row,col){
  try{
    const res=await fetch("/api/move",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({row,col})});
    const data=await res.json();
    if(data.error){beep(220,90); setStatus(data.error); return;}
    gameState=data;
    drawAll();
    updateTurnText();
    if(gameState.winner!==0){stopTimer();}else{resetTimer();}
  }catch(e){
    setStatus("落子失败：无法连接后端。");
  }
}

function drawAll(){
  const size=gameState?gameState.boardSize:15;
  const w=canvas.width,h=canvas.height;
  ctx.clearRect(0,0,w,h);

  const pad=28;
  const grid=(w-pad*2)/(size-1);

  ctx.fillStyle="rgba(0,0,0,0.25)";
  ctx.fillRect(0,0,w,h);

  ctx.strokeStyle="rgba(0,246,255,0.35)";
  ctx.lineWidth=1;
  ctx.shadowColor="rgba(0,246,255,0.35)";
  ctx.shadowBlur=10;

  for(let i=0;i<size;i++){
    const x=pad+i*grid;
    const y=pad+i*grid;
    ctx.beginPath(); ctx.moveTo(pad,y); ctx.lineTo(w-pad,y); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(x,pad); ctx.lineTo(x,h-pad); ctx.stroke();
  }

  ctx.shadowBlur=0;

  if(!gameState) return;

  const b=gameState.board;
  for(let r=0;r<size;r++){
    for(let c=0;c<size;c++){
      const v=b[r][c];
      if(v===0) continue;
      const x=pad+c*grid;
      const y=pad+r*grid;
      const radius=15;

      ctx.save();
      ctx.fillStyle=(v===1)?"rgba(0,246,255,.92)":"rgba(255,79,216,.92)";
      ctx.shadowColor=(v===1)?"rgba(0,246,255,.75)":"rgba(255,79,216,.75)";
      ctx.shadowBlur=18;
      ctx.beginPath(); ctx.arc(x,y,radius,0,Math.PI*2); ctx.fill();
      ctx.shadowBlur=0;
      ctx.strokeStyle="rgba(255,255,255,.18)";
      ctx.lineWidth=2;
      ctx.beginPath(); ctx.arc(x,y,radius,0,Math.PI*2); ctx.stroke();
      ctx.restore();
    }
  }
}

function canvasXYToRC(x,y){
  const size=gameState.boardSize;
  const pad=28;
  const grid=(canvas.width-pad*2)/(size-1);
  const col=Math.round((x-pad)/grid);
  const row=Math.round((y-pad)/grid);
  if(row<0||row>=size||col<0||col>=size) return null;
  return [row,col];
}

canvas.addEventListener("click",(ev)=>{
  if(!gameState){setStatus("请先点“新开一局”。"); return;}
  if(gameState.winner!==0){setStatus("本局已结束：请新开一局。"); return;}
  if(gameState.current!==1){setStatus("轮到赛博猴子思考中…"); return;}

  const rect=canvas.getBoundingClientRect();
  const x=(ev.clientX-rect.left)*(canvas.width/rect.width);
  const y=(ev.clientY-rect.top)*(canvas.height/rect.height);
  const rc=canvasXYToRC(x,y);
  if(!rc){beep(220,90); setStatus("请点在网格交叉点附近。"); return;}
  beep(520,70);
  apiMove(rc[0],rc[1]);
});

newGameBtn.addEventListener("click",apiNewGame);

drawAll();
updateTurnText();

window.gomokuInit=apiNewGame;
window.gomokuStop=stopTimer;
JS

cat > manim_scenes/cyber_attractor.py <<'PY'
from manim import *
import numpy as np

class CyberAttractor(ThreeDScene):
    def construct(self):
        self.set_camera_orientation(phi=70*DEGREES, theta=-45*DEGREES, zoom=1.15)
        axes = ThreeDAxes(x_range=[-30,30,10], y_range=[-30,30,10], z_range=[0,60,10], x_length=7, y_length=7, z_length=6)
        axes.set_stroke(width=1, opacity=0.22)
        title = Text("CYBER ATTRACTOR", font_size=42, weight=BOLD).set_color(TEAL_A).to_corner(UL)
        glow = SurroundingRectangle(title, buff=0.3, corner_radius=0.2).set_stroke(color=PURPLE_A, width=2, opacity=0.6)
        self.add_fixed_in_frame_mobjects(title, glow)
        self.add(axes)

        sigma, rho, beta = 10.0, 28.0, 8/3
        dt, steps = 0.01, 6500
        p = np.array([0.1, 0.0, 0.0], dtype=float)
        pts = []
        for _ in range(steps):
          x,y,z = p
          dx = sigma*(y-x)
          dy = x*(rho-z)-y
          dz = x*y - beta*z
          p = p + dt*np.array([dx,dy,dz])
          pts.append(p.copy())
        pts = np.array(pts) * 0.12
        curve = VMobject()
        curve.set_points_smoothly([axes.c2p(x,y,z) for x,y,z in pts])
        curve.set_stroke(color=TEAL_A, width=2, opacity=0.75)
        dot = Dot3D(point=curve.get_start(), radius=0.06).set_color(WHITE)
        trail = TracedPath(lambda: dot.get_center(), stroke_color=PURPLE_A, stroke_width=3, dissipating_time=1.8, stroke_opacity=[0.0,0.9])
        self.add(trail, dot)
        self.play(Create(curve), run_time=1.0)
        self.begin_ambient_camera_rotation(rate=0.12)
        self.play(MoveAlongPath(dot, curve), run_time=10, rate_func=linear)
        self.wait(0.2)
PY

if [ -d ".venv" ]; then
  source .venv/bin/activate
else
  python3 -m venv .venv
  source .venv/bin/activate
fi

python -m pip install -U pip >/dev/null
python -m pip install flask >/dev/null

if command -v brew >/dev/null 2>&1; then
  if ! command -v ffmpeg >/dev/null 2>&1; then
    brew install ffmpeg >/dev/null
  fi
fi

python -m pip install manim >/dev/null || true

manim -qh manim_scenes/cyber_attractor.py CyberAttractor -o attractor.mp4 >/dev/null || true
VIDEO_PATH="$(find media -type f -name 'attractor.mp4' | head -n 1 || true)"
if [ -n "${VIDEO_PATH}" ]; then
  cp "${VIDEO_PATH}" frontend/static/attractor.mp4
fi

echo "OK"
