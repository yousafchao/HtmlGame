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
