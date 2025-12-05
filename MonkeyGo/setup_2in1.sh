set -euo pipefail

ROOT="$HOME/PycharmProjects/MonkeyGo"
cd "$ROOT"

mkdir -p manim_scenes
mkdir -p frontend/templates
mkdir -p frontend/static

if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi

source .venv/bin/activate
python -m pip install --upgrade pip >/dev/null
python -m pip install flask >/dev/null

if command -v brew >/dev/null 2>&1; then
  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "检测到未安装 ffmpeg，正在用 brew 安装（Manim 渲染视频需要）..."
    brew install ffmpeg >/dev/null
  fi
fi

python -m pip install manim >/dev/null || true

cat <<'PY' > manim_scenes/cyber_attractor.py
from manim import *
import numpy as np

class CyberAttractor(ThreeDScene):
    def construct(self):
        self.set_camera_orientation(phi=70*DEGREES, theta=-45*DEGREES, zoom=1.2)

        axes = ThreeDAxes(
            x_range=[-30, 30, 10],
            y_range=[-30, 30, 10],
            z_range=[0, 60, 10],
            x_length=7,
            y_length=7,
            z_length=6,
        )
        axes.set_stroke(width=1, opacity=0.25)

        title = Text("CYBER ATTRACTOR", font_size=42, weight=BOLD)
        title.set_color(TEAL_A)
        title.to_corner(UL)

        glow = SurroundingRectangle(title, buff=0.3, corner_radius=0.2)
        glow.set_stroke(color=PURPLE_A, width=2, opacity=0.6)

        self.add_fixed_in_frame_mobjects(title, glow)
        self.add(axes)

        sigma = 10.0
        rho = 28.0
        beta = 8/3

        dt = 0.01
        steps = 7000

        p = np.array([0.1, 0.0, 0.0], dtype=float)

        pts = []
        for _ in range(steps):
            x, y, z = p
            dx = sigma*(y-x)
            dy = x*(rho-z)-y
            dz = x*y - beta*z
            p = p + dt*np.array([dx, dy, dz])
            pts.append(p.copy())

        pts = np.array(pts)

        scale = 0.12
        pts_scaled = pts * scale

        curve = VMobject()
        curve.set_points_smoothly([axes.c2p(x, y, z) for x, y, z in pts_scaled])
        curve.set_stroke(color=TEAL_A, width=2, opacity=0.75)

        trail = TracedPath(
            lambda: dot.get_center(),
            stroke_color=PURPLE_A,
            stroke_width=3,
            dissipating_time=1.8,
            stroke_opacity=[0.0, 0.9],
        )

        dot = Dot3D(point=curve.get_start(), radius=0.06)
        dot.set_color(WHITE)

        self.add(trail)
        self.add(dot)

        self.play(Create(curve), run_time=1.2)

        self.begin_ambient_camera_rotation(rate=0.12)

        self.play(
            MoveAlongPath(dot, curve),
            run_time=10,
            rate_func=linear,
        )

        self.wait(0.3)
PY

echo "开始渲染 Manim 吸引子视频（若首次安装 manim/依赖，可能较慢）..."
manim -qh manim_scenes/cyber_attractor.py CyberAttractor -o attractor.mp4 >/dev/null || true

VIDEO_PATH="$(find media -type f -name 'attractor.mp4' | head -n 1 || true)"
if [ -n "${VIDEO_PATH}" ]; then
  cp "${VIDEO_PATH}" frontend/static/attractor.mp4
  echo "已生成 frontend/static/attractor.mp4"
else
  echo "没有找到 manim 输出的视频。若你看到 manim 安装报错，请把报错贴我。"
fi

if [ -f "frontend/static/app.js" ] && [ ! -f "frontend/static/gomoku.js" ]; then
  mv frontend/static/app.js frontend/static/gomoku.js
fi

cat <<'HTML' > frontend/templates/index.html
<!doctype html>
<html lang="zh">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>CyberMonkeyGo｜2合1（五子棋 + 打砖块）</title>
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
    <header class="topbar">
      <div class="logo">CYBER<span class="logo-accent">MONKEY</span>ARCADE</div>
      <div class="subtitle">2合1｜五子棋 vs 机械猴打砖块</div>
    </header>

    <div id="startScreen" class="start">
      <div class="start-card">
        <div class="start-title">选择模式</div>
        <div class="start-desc">背景由 Manim 渲染的“吸引子”驱动；游戏在浏览器里运行。</div>
        <div class="start-buttons">
          <button id="btnGo" class="btn-main">进入：赛博五子棋</button>
          <button id="btnBreakout" class="btn-main">进入：机械猴打砖块</button>
        </div>
        <div class="start-tip">提示：若你在代理/VPN环境，建议浏览器关闭“强制 https”。请用 http://127.0.0.1:5000</div>
      </div>
    </div>

    <main class="main hidden" id="gameShell">
      <section class="game-left">
        <div id="gomokuView" class="view hidden">
          <canvas id="boardCanvas" width="720" height="720"></canvas>
          <div class="hint">五子棋：点击棋盘交叉点落子（你先手）。</div>
        </div>

        <div id="breakoutView" class="view hidden">
          <canvas id="breakoutCanvas" width="720" height="480"></canvas>
          <div class="hint">打砖块：← → 或 A/D 移动；空格发球；R 重开。</div>
        </div>
      </section>

      <aside class="panel">
        <div class="card">
          <h2>通用控制</h2>
          <div class="row">
            <button id="backBtn" class="ghost">返回开始界面</button>
            <button id="soundBtn" class="ghost">音效：开</button>
          </div>
        </div>

        <div class="card" id="gomokuPanel">
          <h2>五子棋控制</h2>
          <label class="row">
            <span>难度</span>
            <select id="difficulty">
              <option value="easy">简单</option>
              <option value="normal" selected>普通</option>
              <option value="hard">困难</option>
            </select>
          </label>
          <div class="row">
            <button id="newGameBtn">新开一局</button>
          </div>
          <div class="row">
            <div class="pill">回合：<span id="turnText">-</span></div>
            <div class="pill">计时：<span id="timerText">-</span>s</div>
          </div>
        </div>

        <div class="card hidden" id="breakoutPanel">
          <h2>打砖块控制</h2>
          <label class="row">
            <span>难度</span>
            <select id="breakoutDifficulty">
              <option value="easy">简单</option>
              <option value="normal" selected>普通</option>
              <option value="hard">困难</option>
            </select>
          </label>
          <div class="row">
            <button id="breakoutStartBtn">开始 / 继续</button>
            <button id="breakoutRestartBtn" class="ghost">重开</button>
          </div>
          <div class="row">
            <div class="pill">生命：<span id="livesText">3</span></div>
            <div class="pill">分数：<span id="scoreText">0</span></div>
          </div>
        </div>

        <div class="card">
          <h2>战况播报</h2>
          <div id="statusText" class="status">准备就绪：请选择一个模式开始。</div>
        </div>
      </aside>
    </main>

    <footer class="footer">
      <span>© CyberMonkeyGo｜霓虹 + 吸引子 + 香蕉</span>
    </footer>
  </div>

  <script src="/static/menu.js"></script>
  <script src="/static/gomoku.js"></script>
  <script src="/static/breakout.js"></script>
</body>
</html>
HTML

cat <<'CSS' > frontend/static/style.css
body{background:#000;margin:0;font-family:ui-sans-serif,system-ui,-apple-system,"PingFang SC","Microsoft YaHei",Arial;color:#d7e7ff}
.bg{position:fixed;inset:0;z-index:-3;overflow:hidden}
.bg-video{position:absolute;inset:-10%;width:120%;height:120%;object-fit:cover;filter:saturate(1.3) contrast(1.1) brightness(0.55)}
.bg-overlay{position:absolute;inset:0;background:radial-gradient(circle at 20% 10%,rgba(26,8,74,.55) 0%,rgba(5,1,15,.75) 45%,rgba(0,0,0,.92) 100%)}
.app{max-width:1200px;margin:0 auto;padding:18px}
.topbar{display:flex;align-items:baseline;justify-content:space-between;gap:12px;padding:12px 14px;border:1px solid rgba(120,200,255,.25);border-radius:14px;background:rgba(10,10,30,.45);box-shadow:0 0 24px rgba(0,255,255,.08)}
.logo{font-weight:800;letter-spacing:2px;font-size:22px;text-shadow:0 0 14px rgba(0,255,255,.35)}
.logo-accent{color:#ff4fd8;text-shadow:0 0 14px rgba(255,79,216,.5)}
.subtitle{opacity:.85;font-size:13px}
.main{display:grid;grid-template-columns:1fr 340px;gap:16px;margin-top:14px}
.game-left{display:flex;flex-direction:column;gap:12px}
.view{border-radius:16px;border:1px solid rgba(120,200,255,.22);background:rgba(6,8,20,.55);padding:14px;box-shadow:0 0 30px rgba(0,255,255,.06)}
.hint{margin-top:10px;font-size:13px;opacity:.85}
#boardCanvas,#breakoutCanvas{width:100%;height:auto;border-radius:14px;background:radial-gradient(circle at 50% 35%,rgba(0,255,255,.08),rgba(255,79,216,.05),rgba(0,0,0,.35));display:block}
.panel{display:flex;flex-direction:column;gap:14px}
.card{border-radius:16px;border:1px solid rgba(255,255,255,.08);background:rgba(6,8,20,.62);padding:14px;box-shadow:inset 0 0 0 1px rgba(0,255,255,.05)}
.card h2{margin:0 0 10px 0;font-size:15px;letter-spacing:1px}
.row{display:flex;align-items:center;justify-content:space-between;gap:10px;margin-top:10px}
select{background:rgba(0,0,0,.45);color:#d7e7ff;border:1px solid rgba(120,200,255,.25);border-radius:10px;padding:8px 10px;outline:none}
button{background:linear-gradient(90deg,rgba(0,255,255,.22),rgba(255,79,216,.18));color:#d7e7ff;border:1px solid rgba(120,200,255,.25);border-radius:12px;padding:10px 12px;cursor:pointer;font-weight:800}
button:hover{box-shadow:0 0 18px rgba(0,255,255,.12)}
button.ghost{background:rgba(0,0,0,.25)}
.pill{padding:8px 10px;border-radius:999px;border:1px dashed rgba(120,200,255,.25);background:rgba(0,0,0,.25);font-size:13px}
.status{padding:10px;border-radius:12px;background:rgba(0,0,0,.28);border:1px solid rgba(255,255,255,.06);min-height:52px;line-height:1.4}
.footer{margin-top:14px;opacity:.7;font-size:12px;text-align:center}

.start{display:flex;align-items:center;justify-content:center;margin-top:16px}
.start-card{width:min(880px,100%);border-radius:18px;border:1px solid rgba(120,200,255,.25);background:rgba(6,8,20,.68);padding:18px;box-shadow:0 0 30px rgba(0,255,255,.08)}
.start-title{font-size:20px;font-weight:900;letter-spacing:1px}
.start-desc{margin-top:8px;opacity:.9;line-height:1.5}
.start-buttons{display:flex;gap:12px;flex-wrap:wrap;margin-top:14px}
.btn-main{padding:12px 14px}
.start-tip{margin-top:12px;font-size:12px;opacity:.75}

.hidden{display:none !important}

@media (max-width: 980px){.main{grid-template-columns:1fr}}
CSS

cat <<'JS' > frontend/static/menu.js
const startScreen=document.getElementById("startScreen");
const gameShell=document.getElementById("gameShell");
const btnGo=document.getElementById("btnGo");
const btnBreakout=document.getElementById("btnBreakout");
const backBtn=document.getElementById("backBtn");
const gomokuView=document.getElementById("gomokuView");
const breakoutView=document.getElementById("breakoutView");
const gomokuPanel=document.getElementById("gomokuPanel");
const breakoutPanel=document.getElementById("breakoutPanel");
const statusText=document.getElementById("statusText");

function setStatus(msg){statusText.textContent=msg;}

function enterMode(mode){
  startScreen.classList.add("hidden");
  gameShell.classList.remove("hidden");
  if(mode==="gomoku"){
    gomokuView.classList.remove("hidden");
    breakoutView.classList.add("hidden");
    gomokuPanel.classList.remove("hidden");
    breakoutPanel.classList.add("hidden");
    setStatus("五子棋模式：点击“新开一局”开始。");
  }else{
    gomokuView.classList.add("hidden");
    breakoutView.classList.remove("hidden");
    gomokuPanel.classList.add("hidden");
    breakoutPanel.classList.remove("hidden");
    setStatus("打砖块模式：点击“开始/继续”发球。");
    if(window.breakoutInit){window.breakoutInit();}
  }
}

function backToMenu(){
  gameShell.classList.add("hidden");
  startScreen.classList.remove("hidden");
  gomokuView.classList.add("hidden");
  breakoutView.classList.add("hidden");
  gomokuPanel.classList.add("hidden");
  breakoutPanel.classList.add("hidden");
  setStatus("已返回开始界面：请选择一个模式。");
}

btnGo.addEventListener("click",()=>enterMode("gomoku"));
btnBreakout.addEventListener("click",()=>enterMode("breakout"));
backBtn.addEventListener("click",backToMenu);
JS

cat <<'JS' > frontend/static/breakout.js
(function(){
  const canvas=document.getElementById("breakoutCanvas");
  const ctx=canvas.getContext("2d");

  const diffSelect=document.getElementById("breakoutDifficulty");
  const startBtn=document.getElementById("breakoutStartBtn");
  const restartBtn=document.getElementById("breakoutRestartBtn");

  const livesText=document.getElementById("livesText");
  const scoreText=document.getElementById("scoreText");

  const soundBtn=document.getElementById("soundBtn");

  let audioCtx=null;
  let soundOn=true;

  function beep(freq,durMs){
    if(!soundOn)return;
    if(!audioCtx)audioCtx=new(window.AudioContext||window.webkitAudioContext)();
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

  soundBtn.addEventListener("click",()=>{
    soundOn=!soundOn;
    soundBtn.textContent=soundOn?"音效：开":"音效：关";
    if(soundOn)beep(660,80);
  });

  let running=false;
  let lives=3;
  let score=0;

  let paddle={x:canvas.width/2-60,y:canvas.height-22,w:120,h:12,v:0};

  let ball={x:canvas.width/2,y:canvas.height-60,r:7,vx:3,vy:-3,stuck:true};

  let bricks=[];
  const rows=6;
  const cols=10;

  function buildBricks(){
    bricks=[];
    const margin=18;
    const gap=8;
    const totalW=canvas.width-2*margin;
    const bw=(totalW-(cols-1)*gap)/cols;
    const bh=18;
    for(let r=0;r<rows;r++){
      for(let c=0;c<cols;c++){
        bricks.push({x:margin+c*(bw+gap),y:60+r*(bh+gap),w:bw,h:bh,alive:true});
      }
    }
  }

  function setDifficulty(){
    const d=diffSelect.value;
    if(d==="easy"){ball.vx=2.6;ball.vy=-2.6;paddle.w=140;}
    if(d==="normal"){ball.vx=3.2;ball.vy=-3.2;paddle.w=120;}
    if(d==="hard"){ball.vx=3.8;ball.vy=-3.8;paddle.w=105;}
  }

  function resetRound(){
    paddle.x=canvas.width/2-paddle.w/2;
    paddle.v=0;
    ball.x=canvas.width/2;
    ball.y=canvas.height-60;
    ball.stuck=true;
  }

  function hardReset(){
    lives=3;
    score=0;
    livesText.textContent=String(lives);
    scoreText.textContent=String(score);
    setDifficulty();
    buildBricks();
    resetRound();
    running=false;
    draw();
  }

  function clamp(v,a,b){return Math.max(a,Math.min(b,v));}

  let keyL=false,keyR=false;

  window.addEventListener("keydown",(e)=>{
    if(e.key==="ArrowLeft"||e.key==="a"||e.key==="A")keyL=true;
    if(e.key==="ArrowRight"||e.key==="d"||e.key==="D")keyR=true;
    if(e.key===" "){if(ball.stuck){ball.stuck=false;beep(520,70);running=true;}}
    if(e.key==="r"||e.key==="R"){hardReset();beep(440,80);}
  });

  window.addEventListener("keyup",(e)=>{
    if(e.key==="ArrowLeft"||e.key==="a"||e.key==="A")keyL=false;
    if(e.key==="ArrowRight"||e.key==="d"||e.key==="D")keyR=false;
  });

  function hitRectCircle(rect,cx,cy,cr){
    const nx=clamp(cx,rect.x,rect.x+rect.w);
    const ny=clamp(cy,rect.y,rect.y+rect.h);
    const dx=cx-nx;
    const dy=cy-ny;
    return dx*dx+dy*dy<=cr*cr;
  }

  function update(){
    if(!running){requestAnimationFrame(update);return;}

    paddle.v=0;
    if(keyL)paddle.v=-7;
    if(keyR)paddle.v=7;
    paddle.x=clamp(paddle.x+paddle.v,0,canvas.width-paddle.w);

    if(ball.stuck){
      ball.x=paddle.x+paddle.w/2;
      ball.y=paddle.y-12;
      draw();
      requestAnimationFrame(update);
      return;
    }

    ball.x+=ball.vx;
    ball.y+=ball.vy;

    if(ball.x-ball.r<=0){ball.x=ball.r;ball.vx*=-1;beep(380,35);}
    if(ball.x+ball.r>=canvas.width){ball.x=canvas.width-ball.r;ball.vx*=-1;beep(380,35);}
    if(ball.y-ball.r<=0){ball.y=ball.r;ball.vy*=-1;beep(420,35);}

    const padRect={x:paddle.x,y:paddle.y,w:paddle.w,h:paddle.h};
    if(hitRectCircle(padRect,ball.x,ball.y,ball.r) && ball.vy>0){
      ball.vy*=-1;
      const t=(ball.x-(paddle.x+paddle.w/2))/(paddle.w/2);
      ball.vx=ball.vx+ t*1.4;
      beep(560,45);
    }

    for(const b of bricks){
      if(!b.alive)continue;
      if(hitRectCircle(b,ball.x,ball.y,ball.r)){
        b.alive=false;
        score+=10;
        scoreText.textContent=String(score);
        ball.vy*=-1;
        beep(760,45);
        break;
      }
    }

    if(bricks.every(b=>!b.alive)){
      running=false;
      beep(880,140);
      beep(990,180);
      resetRound();
    }

    if(ball.y-ball.r>canvas.height){
      lives-=1;
      livesText.textContent=String(lives);
      beep(180,160);
      if(lives<=0){
        running=false;
        hardReset();
        return;
      }
      resetRound();
    }

    draw();
    requestAnimationFrame(update);
  }

  function draw(){
    ctx.clearRect(0,0,canvas.width,canvas.height);

    ctx.fillStyle="rgba(0,0,0,0.25)";
    ctx.fillRect(0,0,canvas.width,canvas.height);

    for(const b of bricks){
      if(!b.alive)continue;
      ctx.fillStyle="rgba(255,79,216,0.65)";
      ctx.fillRect(b.x,b.y,b.w,b.h);
      ctx.strokeStyle="rgba(255,255,255,0.18)";
      ctx.strokeRect(b.x,b.y,b.w,b.h);
    }

    ctx.fillStyle="rgba(0,246,255,0.9)";
    ctx.fillRect(paddle.x,paddle.y,paddle.w,paddle.h);

    ctx.beginPath();
    ctx.arc(ball.x,ball.y,ball.r,0,Math.PI*2);
    ctx.fillStyle="rgba(255,255,255,0.92)";
    ctx.fill();
  }

  startBtn.addEventListener("click",()=>{
    if(ball.stuck){ball.stuck=false;beep(520,70);}
    running=true;
  });

  restartBtn.addEventListener("click",()=>{
    hardReset();
    beep(440,80);
  });

  window.breakoutInit=function(){hardReset();};

  buildBricks();
  draw();
  requestAnimationFrame(update);
})();
JS

echo "完成：前端已变为 2 合 1（开始界面 + 两个游戏）。"
echo "接下来请用：python -m backend.app  启动，然后浏览器打开 http://127.0.0.1:5000"
