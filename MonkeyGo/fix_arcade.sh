#!/usr/bin/env bash
set -euo pipefail

cd /Users/gaochao/PycharmProjects/MonkeyGo

# 0) 激活你的 venv（确保后续 pip 安装进 .venv）
source .venv/bin/activate

# 1) 检查系统依赖（Manim 渲染 mp4 必须 ffmpeg）
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "❌ 找不到 ffmpeg：请先 brew install ffmpeg"
  exit 1
fi

# 2) 安装 manim（用 python -m manim 避免 PATH/入口命令问题）
python -m pip install -U pip setuptools wheel
python -m pip install -U manim numpy

# 3) 验证 manim 模块可用（不要用 manim 命令，用 python -m manim）
python -m manim --version

# 4) 准备 Manim 场景文件（不存在就创建）
mkdir -p manim_scenes
if [ ! -f manim_scenes/cyber_attractor.py ]; then
  cat > manim_scenes/cyber_attractor.py <<'PY'
from manim import *
import numpy as np

class CyberAttractor(ThreeDScene):
    def construct(self):
        self.set_camera_orientation(phi=70*DEGREES, theta=-45*DEGREES, zoom=1.2)
        axes = ThreeDAxes()
        axes.set_stroke(width=1, opacity=0.20)
        self.add(axes)

        sigma, rho, beta = 10.0, 28.0, 8/3
        dt, steps = 0.01, 6500
        p = np.array([0.1, 0.0, 0.0], dtype=float)
        pts = []
        for _ in range(steps):
            x, y, z = p
            dx = sigma*(y-x)
            dy = x*(rho-z)-y
            dz = x*y - beta*z
            p = p + dt*np.array([dx, dy, dz])
            pts.append(p.copy())

        pts = np.array(pts) * 0.08
        curve = VMobject()
        curve.set_points_smoothly([axes.c2p(x,y,z) for x,y,z in pts])
        curve.set_stroke(color=TEAL_A, width=2, opacity=0.85)

        self.play(Create(curve), run_time=2)
        self.begin_ambient_camera_rotation(rate=0.12)
        self.wait(8)
PY
fi

# 5) 渲染 mp4（用 python -m manim）
python -m manim -qh manim_scenes/cyber_attractor.py CyberAttractor -o attractor.mp4

# 6) 把 mp4 放到 Flask 静态目录（网页访问 /static/attractor.mp4）
VIDEO_PATH="$(find media -type f -name 'attractor.mp4' | head -n 1)"
mkdir -p frontend/static
cp "$VIDEO_PATH" frontend/static/attractor.mp4
echo "✅ 已生成：frontend/static/attractor.mp4"
ls -lh frontend/static/attractor.mp4

# 7) 确保菜单脚本存在（缺了就补一个最小版）
if [ ! -f frontend/static/menu.js ]; then
  cat > frontend/static/menu.js <<'JS'
const menu = document.querySelector(".menu");
const gomokuRoot = document.getElementById("gomokuRoot");
const breakoutRoot = document.getElementById("breakoutRoot");
const btnGo = document.getElementById("btnGo");
const btnBreak = document.getElementById("btnBreak");
const backMenuFromGo = document.getElementById("backMenuFromGo");
const backMenuFromBreak = document.getElementById("backMenuFromBreak");

function showMenu() {
  menu.classList.remove("hidden");
  gomokuRoot.classList.add("hidden");
  breakoutRoot.classList.add("hidden");
}
function showGomoku() {
  menu.classList.add("hidden");
  gomokuRoot.classList.remove("hidden");
  breakoutRoot.classList.add("hidden");
}
function showBreakout() {
  menu.classList.add("hidden");
  gomokuRoot.classList.add("hidden");
  breakoutRoot.classList.remove("hidden");
  if (window.BREAKOUT && typeof window.BREAKOUT.start === "function") window.BREAKOUT.start();
}

btnGo?.addEventListener("click", showGomoku);
btnBreak?.addEventListener("click", showBreakout);
backMenuFromGo?.addEventListener("click", showMenu);
backMenuFromBreak?.addEventListener("click", showMenu);

showMenu();
JS
fi

# 8) 确保打砖块存在（缺了就补一个最小可玩版）
if [ ! -f frontend/static/breakout.js ]; then
  cat > frontend/static/breakout.js <<'JS'
(function () {
  const canvas = document.getElementById("breakoutCanvas");
  if (!canvas) return;
  const ctx = canvas.getContext("2d");

  const state = { running: false, left: false, right: false, score: 0, lives: 3 };
  const paddle = { w: 140, h: 14, x: 0, y: canvas.height - 26, v: 8 };
  const ball = { r: 8, x: canvas.width / 2, y: canvas.height - 60, vx: 5, vy: -6 };
  const bricks = [];
  const BR = { rows: 6, cols: 12, w: 64, h: 20, gap: 10, top: 60, left: 30 };

  function resetBricks() {
    bricks.length = 0;
    for (let r = 0; r < BR.rows; r++) for (let c = 0; c < BR.cols; c++)
      bricks.push({ x: BR.left + c * (BR.w + BR.gap), y: BR.top + r * (BR.h + BR.gap), alive: true });
  }
  function resetRound() {
    paddle.x = (canvas.width - paddle.w) / 2;
    ball.x = canvas.width / 2;
    ball.y = canvas.height - 60;
    ball.vx = 5 * (Math.random() > 0.5 ? 1 : -1);
    ball.vy = -6;
  }
  function drawBg() { ctx.clearRect(0,0,canvas.width,canvas.height); ctx.fillStyle="rgba(0,0,0,0.35)"; ctx.fillRect(0,0,canvas.width,canvas.height); }
  function drawPaddle() { ctx.save(); ctx.fillStyle="rgba(0,246,255,0.85)"; ctx.shadowColor="rgba(0,246,255,0.6)"; ctx.shadowBlur=16; ctx.fillRect(paddle.x,paddle.y,paddle.w,paddle.h); ctx.restore(); }
  function drawBall() { ctx.save(); ctx.fillStyle="rgba(255,79,216,0.9)"; ctx.shadowColor="rgba(255,79,216,0.7)"; ctx.shadowBlur=18; ctx.beginPath(); ctx.arc(ball.x,ball.y,ball.r,0,Math.PI*2); ctx.fill(); ctx.restore(); }
  function drawBricks() {
    for (let i=0;i<bricks.length;i++){
      const b=bricks[i]; if(!b.alive) continue;
      ctx.save();
      const pink=(i%2===0);
      ctx.fillStyle=pink?"rgba(255,79,216,0.55)":"rgba(0,246,255,0.45)";
      ctx.strokeStyle="rgba(255,255,255,0.12)";
      ctx.shadowColor=pink?"rgba(255,79,216,0.35)":"rgba(0,246,255,0.30)";
      ctx.shadowBlur=10;
      ctx.fillRect(b.x,b.y,BR.w,BR.h);
      ctx.strokeRect(b.x,b.y,BR.w,BR.h);
      ctx.restore();
    }
  }
  function drawHUD() { ctx.save(); ctx.fillStyle="rgba(255,255,255,0.85)"; ctx.font="16px system-ui"; ctx.fillText(`Score: ${state.score}   Lives: ${state.lives}   Space: Start/Pause`, 18, 26); ctx.restore(); }
  function collide(rx,ry,rw,rh){
    const cx=Math.max(rx,Math.min(ball.x,rx+rw));
    const cy=Math.max(ry,Math.min(ball.y,ry+rh));
    const dx=ball.x-cx, dy=ball.y-cy;
    return dx*dx+dy*dy<=ball.r*ball.r;
  }
  function update(){
    if(state.left) paddle.x-=paddle.v;
    if(state.right) paddle.x+=paddle.v;
    paddle.x=Math.max(0,Math.min(canvas.width-paddle.w,paddle.x));
    if(!state.running) return;

    ball.x+=ball.vx; ball.y+=ball.vy;
    if(ball.x-ball.r<=0||ball.x+ball.r>=canvas.width) ball.vx*=-1;
    if(ball.y-ball.r<=0) ball.vy*=-1;

    if(collide(paddle.x,paddle.y,paddle.w,paddle.h) && ball.vy>0){
      const hit=(ball.x-(paddle.x+paddle.w/2))/(paddle.w/2);
      ball.vx=7*hit; ball.vy*=-1; ball.y=paddle.y-ball.r-1;
    }

    for(const b of bricks){
      if(!b.alive) continue;
      if(collide(b.x,b.y,BR.w,BR.h)){ b.alive=false; state.score+=10; ball.vy*=-1; break; }
    }

    if(ball.y-ball.r>canvas.height){
      state.lives-=1; state.running=false;
      if(state.lives<=0){ state.lives=3; state.score=0; resetBricks(); }
      resetRound();
    }

    if(bricks.every(b=>!b.alive)){ resetBricks(); resetRound(); state.running=false; }
  }
  function draw(){ drawBg(); drawBricks(); drawPaddle(); drawBall(); drawHUD(); }
  function loop(){ update(); draw(); requestAnimationFrame(loop); }

  window.addEventListener("keydown",(e)=>{
    if(e.key==="ArrowLeft"||e.key==="a"||e.key==="A") state.left=true;
    if(e.key==="ArrowRight"||e.key==="d"||e.key==="D") state.right=true;
    if(e.code==="Space") state.running=!state.running;
  });
  window.addEventListener("keyup",(e)=>{
    if(e.key==="ArrowLeft"||e.key==="a"||e.key==="A") state.left=false;
    if(e.key==="ArrowRight"||e.key==="d"||e.key==="D") state.right=false;
  });

  resetBricks(); resetRound(); loop();
  window.BREAKOUT={ start(){ state.running=false; } };
})();
JS
fi

echo "✅ 前端文件检查完成：menu.js / breakout.js 已确保存在"
