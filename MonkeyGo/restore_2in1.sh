set -euo pipefail

cd /Users/gaochao/PycharmProjects/MonkeyGo
mkdir -p frontend/templates frontend/static

# -------------------- 1) 2合1 首页：菜单 + 两个游戏面板 --------------------
cat > frontend/templates/index.html <<'HTML'
<!doctype html>
<html lang="zh">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>CyberMonkey Arcade｜2合1</title>
  <link rel="stylesheet" href="/static/style.css">
</head>
<body>
  <!-- 背景：优先显示 Manim 渲染出来的 attractor.mp4（如果文件不存在会自动空白） -->
  <div class="bg"><!-- 背景容器 -->
    <video class="bg-video" autoplay muted loop playsinline><!-- 必须 muted 才能自动播放 -->
      <source src="/static/attractor.mp4" type="video/mp4"><!-- Manim 渲染成果 -->
    </video>
    <div class="bg-overlay"></div><!-- 深色霓虹遮罩，让前景文字清晰 -->
  </div>

  <div class="app"><!-- 主容器 -->
    <!-- 开始界面 -->
    <div id="menu" class="menu"><!-- 菜单面板 -->
      <div class="card"><!-- 菜单卡片 -->
        <div class="logo">CYBER<span class="accent">MONKEY</span> ARCADE</div><!-- 标题 -->
        <div class="sub">2 合 1：五子棋（人类 vs 赛博猴子AI） + 打砖块（马斯克猴子风占位版）</div><!-- 副标题 -->

        <div class="row"><!-- 选择模式 -->
          <span>模式</span>
          <select id="modeSelect"><!-- 模式下拉 -->
            <option value="gomoku" selected>五子棋</option>
            <option value="breakout">打砖块</option>
          </select>
        </div>

        <div class="row"><!-- 五子棋难度 -->
          <span>难度（五子棋）</span>
          <select id="difficultySelect"><!-- 菜单里的难度选择 -->
            <option value="easy">简单</option>
            <option value="normal" selected>普通</option>
            <option value="hard">困难</option>
          </select>
        </div>

        <div class="row"><!-- 按钮区 -->
          <button id="startBtn">开始</button><!-- 进入所选模式 -->
          <button id="soundBtn" class="ghost">音效：开</button><!-- 全局音效开关 -->
        </div>

        <div id="menuTip" class="tip">提示：背景“吸引子”来自 Manim 预渲染视频（不是实时计算）。</div><!-- 说明 -->
      </div>
    </div>

    <!-- 游戏壳：进入游戏后显示 -->
    <div id="shell" class="shell hidden"><!-- 游戏区域 -->
      <div class="top"><!-- 顶部条 -->
        <div class="title">CyberMonkey Arcade</div><!-- 标题 -->
        <button id="backBtn" class="ghost">返回菜单</button><!-- 返回按钮 -->
      </div>

      <div class="main"><!-- 主区域：左画布 + 右信息 -->
        <!-- 五子棋面板 -->
        <section id="gomokuPanel" class="panel hidden"><!-- 五子棋区域（默认隐藏） -->
          <div class="left"><!-- 左侧：棋盘 -->
            <canvas id="boardCanvas" width="720" height="720"></canvas><!-- 五子棋画布 -->
            <div class="hint">点击棋盘交叉点落子（你先手）。</div><!-- 提示 -->
          </div>
          <div class="right"><!-- 右侧：控制与状态 -->
            <div class="card">
              <div class="row"><!-- 游戏内难度（与菜单同步） -->
                <span>难度</span>
                <select id="difficulty"><!-- 五子棋真正使用的难度控件 -->
                  <option value="easy">简单</option>
                  <option value="normal" selected>普通</option>
                  <option value="hard">困难</option>
                </select>
              </div>
              <div class="row">
                <button id="newGameBtn">新开一局</button><!-- 新局按钮 -->
              </div>
              <div class="row">
                <div class="pill">回合：<span id="turnText">-</span></div><!-- 回合显示 -->
                <div class="pill">计时：<span id="timerText">-</span>s</div><!-- 计时显示 -->
              </div>
              <div class="status" id="statusText">准备就绪：点“新开一局”。</div><!-- 状态文本 -->
            </div>
          </div>
        </section>

        <!-- 打砖块面板 -->
        <section id="breakoutPanel" class="panel hidden"><!-- 打砖块区域（默认隐藏） -->
          <div class="left">
            <canvas id="breakoutCanvas" width="860" height="520"></canvas><!-- 打砖块画布 -->
            <div class="hint">← → 移动挡板；空格开始/暂停。</div><!-- 提示 -->
          </div>
          <div class="right">
            <div class="card">
              <div class="status" id="breakoutStatus">准备就绪：按空格开始。</div><!-- 打砖块状态 -->
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>

  <!-- JS：菜单控制 + 两个游戏 -->
  <script src="/static/menu.js"></script>
  <script src="/static/gomoku.js"></script>
  <script src="/static/breakout.js"></script>
</body>
</html>
HTML

# -------------------- 2) CSS：支持背景视频 + 2合1布局 --------------------
cat > frontend/static/style.css <<'CSS'
body{margin:0;color:#d7e7ff;font-family:system-ui,-apple-system,"PingFang SC","Microsoft YaHei",Arial;background:#000}
.bg{position:fixed;inset:0;z-index:-3;overflow:hidden}
.bg-video{position:absolute;inset:-10%;width:120%;height:120%;object-fit:cover;filter:saturate(1.25) contrast(1.1) brightness(0.55)}
.bg-overlay{position:absolute;inset:0;background:radial-gradient(circle at 20% 10%,rgba(26,8,74,.55) 0%,rgba(5,1,15,.75) 45%,rgba(0,0,0,.92) 100%)}
.app{max-width:1200px;margin:0 auto;padding:18px}
.hidden{display:none !important}
.menu{display:flex;align-items:center;justify-content:center;min-height:calc(100vh - 36px)}
.shell{display:block}
.card{border-radius:16px;border:1px solid rgba(120,200,255,.25);background:rgba(6,8,20,.68);padding:16px;box-shadow:0 0 26px rgba(0,255,255,.08);width:min(720px,100%)}
.logo{font-weight:900;letter-spacing:2px;font-size:22px;text-shadow:0 0 14px rgba(0,255,255,.35)}
.accent{color:#ff4fd8;text-shadow:0 0 14px rgba(255,79,216,.5)}
.sub{opacity:.9;margin-top:8px;line-height:1.5}
.row{display:flex;align-items:center;justify-content:space-between;gap:10px;margin-top:12px}
select{background:rgba(0,0,0,.45);color:#d7e7ff;border:1px solid rgba(120,200,255,.25);border-radius:10px;padding:8px 10px;outline:none}
button{background:linear-gradient(90deg,rgba(0,255,255,.22),rgba(255,79,216,.18));color:#d7e7ff;border:1px solid rgba(120,200,255,.25);border-radius:12px;padding:10px 12px;cursor:pointer;font-weight:800}
button.ghost{background:rgba(0,0,0,.25)}
.top{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px}
.title{font-weight:900;letter-spacing:1px}
.main{display:grid;grid-template-columns:1fr;gap:16px}
.panel{display:grid;grid-template-columns:1fr 340px;gap:16px}
.left{border-radius:16px;border:1px solid rgba(120,200,255,.22);background:rgba(6,8,20,.55);padding:14px}
.right{display:flex;flex-direction:column;gap:14px}
#boardCanvas,#breakoutCanvas{width:100%;height:auto;border-radius:14px;background:radial-gradient(circle at 50% 35%,rgba(0,255,255,.08),rgba(255,79,216,.05),rgba(0,0,0,.35));display:block}
.hint{margin-top:10px;font-size:13px;opacity:.85}
.pill{padding:8px 10px;border-radius:999px;border:1px dashed rgba(120,200,255,.25);background:rgba(0,0,0,.25);font-size:13px}
.status{margin-top:12px;padding:10px;border-radius:12px;background:rgba(0,0,0,.28);border:1px solid rgba(255,255,255,.06);min-height:52px;line-height:1.4}
.tip{margin-top:10px;font-size:12px;opacity:.8}
@media (max-width:980px){.panel{grid-template-columns:1fr}}
CSS

# -------------------- 3) menu.js：切换模式 + 全局音效开关 --------------------
cat > frontend/static/menu.js <<'JS'
const menu=document.getElementById("menu"); // 菜单层
const shell=document.getElementById("shell"); // 游戏层
const startBtn=document.getElementById("startBtn"); // 开始按钮
const backBtn=document.getElementById("backBtn"); // 返回按钮
const modeSelect=document.getElementById("modeSelect"); // 模式选择
const difficultySelect=document.getElementById("difficultySelect"); // 菜单难度选择
const soundBtn=document.getElementById("soundBtn"); // 音效按钮
const gomokuPanel=document.getElementById("gomokuPanel"); // 五子棋面板
const breakoutPanel=document.getElementById("breakoutPanel"); // 打砖块面板

if(window.__CYBER_SOUND_ON__===undefined) window.__CYBER_SOUND_ON__=true; // 全局音效标志（只存一份）
soundBtn.textContent=window.__CYBER_SOUND_ON__?"音效：开":"音效：关"; // UI同步

soundBtn.addEventListener("click",()=>{ // 切换音效
  window.__CYBER_SOUND_ON__=!window.__CYBER_SOUND_ON__; // 取反
  soundBtn.textContent=window.__CYBER_SOUND_ON__?"音效：开":"音效：关"; // 更新文字
});

function showPanel(which){ // 显示某个游戏面板
  gomokuPanel.classList.add("hidden"); // 先都隐藏
  breakoutPanel.classList.add("hidden"); // 先都隐藏
  if(which==="gomoku"){ // 如果是五子棋
    gomokuPanel.classList.remove("hidden"); // 显示五子棋
    const innerDiff=document.getElementById("difficulty"); // 游戏内难度控件
    if(innerDiff) innerDiff.value=difficultySelect.value; // 把菜单的难度同步过去
    if(window.gomokuInit) window.gomokuInit(); // 进入就自动开局（避免“进去啥都没发生”）
  }else{ // 否则是打砖块
    breakoutPanel.classList.remove("hidden"); // 显示打砖块
    if(window.breakoutInit) window.breakoutInit(); // 初始化打砖块
  }
}

startBtn.addEventListener("click",()=>{ // 开始按钮
  menu.classList.add("hidden"); // 隐藏菜单
  shell.classList.remove("hidden"); // 显示游戏壳
  showPanel(modeSelect.value); // 按所选模式显示
});

backBtn.addEventListener("click",()=>{ // 返回菜单
  if(window.gomokuStop) window.gomokuStop(); // 停掉五子棋计时器
  if(window.breakoutPause) window.breakoutPause(); // 暂停打砖块循环
  shell.classList.add("hidden"); // 隐藏游戏壳
  menu.classList.remove("hidden"); // 显示菜单
});
JS

# -------------------- 4) breakout.js：可玩的打砖块（简化版） --------------------
cat > frontend/static/breakout.js <<'JS'
const bc=document.getElementById("breakoutCanvas"); // 打砖块画布
const bctx=bc?bc.getContext("2d"):null; // 2D 画笔
const bStatus=document.getElementById("breakoutStatus"); // 状态文本

let running=false; // 是否在运行
let rafId=null; // requestAnimationFrame 句柄

let paddle={x:0,y:0,w:120,h:14,v:0}; // 挡板数据
let ball={x:0,y:0,r:8,vx:4,vy:-4}; // 小球数据
let bricks=[]; // 砖块数组
let keys={left:false,right:false}; // 按键状态

let audioCtx=null; // WebAudio 上下文
function beep(freq,dur){ // 简单音效
  if(window.__CYBER_SOUND_ON__===false) return; // 全局关闭则不响
  if(!audioCtx) audioCtx=new(window.AudioContext||window.webkitAudioContext)(); // 懒加载
  const o=audioCtx.createOscillator(); // 震荡器
  const g=audioCtx.createGain(); // 音量
  o.type="sine"; // 正弦波
  o.frequency.value=freq; // 频率
  g.gain.value=0.05; // 音量
  o.connect(g); // 连接
  g.connect(audioCtx.destination); // 输出
  o.start(); // 开始
  setTimeout(()=>o.stop(),dur); // 结束
}

function setB(msg){ if(bStatus) bStatus.textContent=msg; } // 更新状态文本

function resetGame(){ // 重置整局
  if(!bc||!bctx) return; // 没画布就退出
  paddle.w=120; paddle.h=14; paddle.y=bc.height-40; paddle.x=(bc.width-paddle.w)/2; paddle.v=8; // 挡板初始化
  ball.x=bc.width/2; ball.y=bc.height-60; ball.r=8; ball.vx=4; ball.vy=-4; // 小球初始化
  bricks=[]; // 清空砖块
  const rows=5, cols=10; // 砖块行列
  const margin=40, gap=8; // 边距与间距
  const bw=(bc.width-margin*2-(cols-1)*gap)/cols; // 砖块宽
  const bh=18; // 砖块高
  for(let r=0;r<rows;r++){ // 行循环
    for(let c=0;c<cols;c++){ // 列循环
      bricks.push({ // 新砖块
        x:margin+c*(bw+gap), // x
        y:70+r*(bh+gap), // y
        w:bw, h:bh, alive:true // 宽高与是否存在
      });
    }
  }
  setB("准备就绪：空格开始/暂停，← → 移动挡板。"); // 提示
  draw(); // 画一帧
}

function draw(){ // 绘制一帧
  if(!bctx) return; // 没画笔退出
  bctx.clearRect(0,0,bc.width,bc.height); // 清屏
  bctx.fillStyle="rgba(0,0,0,0.25)"; // 背景层
  bctx.fillRect(0,0,bc.width,bc.height); // 填充背景

  // 画砖块
  bricks.forEach(br=>{ // 遍历砖块
    if(!br.alive) return; // 死砖不画
    bctx.fillStyle="rgba(0,246,255,0.55)"; // 霓虹蓝
    bctx.fillRect(br.x,br.y,br.w,br.h); // 实心
    bctx.strokeStyle="rgba(255,79,216,0.35)"; // 粉描边
    bctx.strokeRect(br.x,br.y,br.w,br.h); // 描边
  });

  // 画挡板
  bctx.fillStyle="rgba(255,79,216,0.75)"; // 粉色挡板
  bctx.fillRect(paddle.x,paddle.y,paddle.w,paddle.h); // 绘制

  // 画球
  bctx.beginPath(); // 开始路径
  bctx.fillStyle="rgba(255,255,255,0.9)"; // 白球
  bctx.arc(ball.x,ball.y,ball.r,0,Math.PI*2); // 圆
  bctx.fill(); // 填充
}

function step(){ // 每帧更新
  if(!running) return; // 不运行就不动
  // 挡板移动
  if(keys.left) paddle.x-=paddle.v; // 左移
  if(keys.right) paddle.x+=paddle.v; // 右移
  paddle.x=Math.max(0,Math.min(bc.width-paddle.w,paddle.x)); // 限制边界

  // 球移动
  ball.x+=ball.vx; // x
  ball.y+=ball.vy; // y

  // 撞墙反弹
  if(ball.x<ball.r||ball.x>bc.width-ball.r){ ball.vx*=-1; beep(420,40); } // 左右墙
  if(ball.y<ball.r){ ball.vy*=-1; beep(520,40); } // 上墙

  // 掉到底部：失败
  if(ball.y>bc.height+40){ running=false; setB("失败：按空格重新开始。"); beep(180,200); return; } // 失败处理

  // 撞挡板
  if(ball.y+ball.r>=paddle.y && ball.y+ball.r<=paddle.y+paddle.h && ball.x>=paddle.x && ball.x<=paddle.x+paddle.w){
    ball.vy=-Math.abs(ball.vy); // 向上
    const hit=(ball.x-(paddle.x+paddle.w/2))/(paddle.w/2); // 命中位置 [-1,1]
    ball.vx=4*hit; // 根据命中点改变水平速度
    beep(660,50); // 反馈音
  }

  // 撞砖块
  for(const br of bricks){ // 遍历砖块
    if(!br.alive) continue; // 跳过死砖
    if(ball.x>br.x && ball.x<br.x+br.w && ball.y>br.y && ball.y<br.y+br.h){
      br.alive=false; // 打碎
      ball.vy*=-1; // 反弹
      beep(880,50); // 音效
      break; // 一帧只处理一个砖块碰撞
    }
  }

  // 胜利判定
  if(bricks.every(b=>!b.alive)){ running=false; setB("胜利！按空格再来一局。"); beep(980,120); } // 全碎则赢

  draw(); // 画面刷新
  rafId=requestAnimationFrame(step); // 下一帧
}

document.addEventListener("keydown",(e)=>{ // 按键按下
  if(e.key==="ArrowLeft") keys.left=true; // 左键
  if(e.key==="ArrowRight") keys.right=true; // 右键
  if(e.code==="Space"){ // 空格：开始/暂停
    if(!running){ // 如果当前不运行
      // 如果上一局结束（失败/胜利），先重置一下球的位置会更友好
      if(bricks.length===0 || bricks.every(b=>!b.alive) || ball.y>bc.height){ resetGame(); } // 该重置就重置
      running=true; setB("运行中：← → 移动挡板；空格暂停。"); // 状态
      cancelAnimationFrame(rafId); // 防止多重循环
      rafId=requestAnimationFrame(step); // 启动循环
    }else{
      running=false; setB("已暂停：空格继续。"); // 暂停
    }
  }
});

document.addEventListener("keyup",(e)=>{ // 按键抬起
  if(e.key==="ArrowLeft") keys.left=false; // 松开
  if(e.key==="ArrowRight") keys.right=false; // 松开
});

window.breakoutInit=function(){ resetGame(); }; // 给菜单调用的初始化入口
window.breakoutPause=function(){ running=false; cancelAnimationFrame(rafId); }; // 返回菜单时暂停
