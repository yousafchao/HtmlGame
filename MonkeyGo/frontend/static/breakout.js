(function () {
  const canvas = document.getElementById("breakoutCanvas"); // 打砖块画布
  if (!canvas) return; // 如果页面没这个 canvas，就直接退出
  const ctx = canvas.getContext("2d"); // 2D 画笔

  const state = { // 游戏状态
    running: false, // 是否在运行
    left: false, // 左键按下
    right: false, // 右键按下
    score: 0, // 分数
    lives: 3, // 生命
  };

  const paddle = { // 挡板
    w: 140, // 宽
    h: 14, // 高
    x: 0, // x
    y: canvas.height - 26, // y（底部）
    v: 8, // 速度
  };

  const ball = { // 球
    r: 8, // 半径
    x: canvas.width / 2, // x
    y: canvas.height - 60, // y
    vx: 5, // 水平速度
    vy: -6, // 垂直速度
  };

  const bricks = []; // 砖块数组
  const BR = { rows: 6, cols: 12, w: 64, h: 20, gap: 10, top: 60, left: 30 }; // 砖块布局

  function resetBricks() { // 重新生成砖块
    bricks.length = 0; // 清空
    for (let r = 0; r < BR.rows; r++) { // 行
      for (let c = 0; c < BR.cols; c++) { // 列
        bricks.push({ // 推入一个砖块对象
          x: BR.left + c * (BR.w + BR.gap), // x
          y: BR.top + r * (BR.h + BR.gap), // y
          alive: true, // 是否还存在
        });
      }
    }
  }

  function resetRound() { // 重置一条命的回合
    paddle.x = (canvas.width - paddle.w) / 2; // 挡板居中
    ball.x = canvas.width / 2; // 球居中
    ball.y = canvas.height - 60; // 球高度
    ball.vx = 5 * (Math.random() > 0.5 ? 1 : -1); // 随机左右
    ball.vy = -6; // 向上
  }

  function drawBg() { // 赛博背景
    ctx.clearRect(0, 0, canvas.width, canvas.height); // 清空
    ctx.fillStyle = "rgba(0,0,0,0.35)"; // 半透明黑
    ctx.fillRect(0, 0, canvas.width, canvas.height); // 铺底
  }

  function drawPaddle() { // 画挡板（香蕉能源条风格）
    ctx.save(); // 保存
    ctx.fillStyle = "rgba(0,246,255,0.85)"; // 霓虹蓝
    ctx.shadowColor = "rgba(0,246,255,0.6)"; // 发光
    ctx.shadowBlur = 16; // 发光强度
    ctx.fillRect(paddle.x, paddle.y, paddle.w, paddle.h); // 矩形挡板
    ctx.restore(); // 恢复
  }

  function drawBall() { // 画球（粉色能量球）
    ctx.save(); // 保存
    ctx.fillStyle = "rgba(255,79,216,0.9)"; // 霓虹粉
    ctx.shadowColor = "rgba(255,79,216,0.7)"; // 发光
    ctx.shadowBlur = 18; // 发光
    ctx.beginPath(); ctx.arc(ball.x, ball.y, ball.r, 0, Math.PI * 2); ctx.fill(); // 圆球
    ctx.restore(); // 恢复
  }

  function drawBricks() { // 画砖块（蓝粉交替）
    for (let i = 0; i < bricks.length; i++) { // 遍历
      const b = bricks[i]; // 当前砖
      if (!b.alive) continue; // 死了不画
      ctx.save(); // 保存
      const isPink = (i % 2 === 0); // 交替颜色
      ctx.fillStyle = isPink ? "rgba(255,79,216,0.55)" : "rgba(0,246,255,0.45)"; // 填充
      ctx.strokeStyle = "rgba(255,255,255,0.12)"; // 轻描边
      ctx.shadowColor = isPink ? "rgba(255,79,216,0.35)" : "rgba(0,246,255,0.30)"; // 发光
      ctx.shadowBlur = 10; // 发光
      ctx.fillRect(b.x, b.y, BR.w, BR.h); // 填充砖
      ctx.strokeRect(b.x, b.y, BR.w, BR.h); // 描边砖
      ctx.restore(); // 恢复
    }
  }

  function drawHUD() { // 画分数/生命
    ctx.save(); // 保存
    ctx.fillStyle = "rgba(255,255,255,0.85)"; // 白字
    ctx.font = "16px system-ui"; // 字体
    ctx.fillText(`Score: ${state.score}   Lives: ${state.lives}   Space: Start/Pause`, 18, 26); // 文案
    ctx.restore(); // 恢复
  }

  function collideBallWithRect(rx, ry, rw, rh) { // 球-矩形碰撞检测
    const cx = Math.max(rx, Math.min(ball.x, rx + rw)); // 最近点x
    const cy = Math.max(ry, Math.min(ball.y, ry + rh)); // 最近点y
    const dx = ball.x - cx; // 距离x
    const dy = ball.y - cy; // 距离y
    return (dx * dx + dy * dy) <= (ball.r * ball.r); // 是否碰到
  }

  function update() { // 更新物理
    if (state.left) paddle.x -= paddle.v; // 左移
    if (state.right) paddle.x += paddle.v; // 右移
    paddle.x = Math.max(0, Math.min(canvas.width - paddle.w, paddle.x)); // 限制范围

    if (!state.running) return; // 暂停时不动球

    ball.x += ball.vx; // 更新球x
    ball.y += ball.vy; // 更新球y

    if (ball.x - ball.r <= 0 || ball.x + ball.r >= canvas.width) ball.vx *= -1; // 撞左右反弹
    if (ball.y - ball.r <= 0) ball.vy *= -1; // 撞顶反弹

    if (collideBallWithRect(paddle.x, paddle.y, paddle.w, paddle.h) && ball.vy > 0) { // 撞挡板
      const hit = (ball.x - (paddle.x + paddle.w / 2)) / (paddle.w / 2); // -1~1
      ball.vx = 7 * hit; // 改变反弹角度
      ball.vy *= -1; // 反弹向上
      ball.y = paddle.y - ball.r - 1; // 防止卡住
    }

    for (const b of bricks) { // 撞砖块
      if (!b.alive) continue; // 跳过
      if (collideBallWithRect(b.x, b.y, BR.w, BR.h)) { // 碰到了
        b.alive = false; // 砖块消失
        state.score += 10; // 加分
        ball.vy *= -1; // 简化反弹（够玩）
        break; // 一帧只处理一个砖
      }
    }

    if (ball.y - ball.r > canvas.height) { // 球掉下去
      state.lives -= 1; // 掉一命
      state.running = false; // 暂停
      if (state.lives <= 0) { // 没命了
        state.lives = 3; // 重置生命
        state.score = 0; // 重置分数
        resetBricks(); // 重置砖块
      }
      resetRound(); // 重置球与挡板
    }

    if (bricks.every(b => !b.alive)) { // 全清砖块
      resetBricks(); // 重来一盘更爽
      resetRound(); // 重置回合
      state.running = false; // 先暂停等待空格
    }
  }

  function draw() { // 绘制一帧
    drawBg(); // 背景
    drawBricks(); // 砖块
    drawPaddle(); // 挡板
    drawBall(); // 球
    drawHUD(); // HUD
  }

  function loop() { // 主循环
    update(); // 更新
    draw(); // 画
    requestAnimationFrame(loop); // 下一帧
  }

  window.addEventListener("keydown", (e) => { // 键盘按下
    if (e.key === "ArrowLeft" || e.key === "a" || e.key === "A") state.left = true; // 左
    if (e.key === "ArrowRight" || e.key === "d" || e.key === "D") state.right = true; // 右
    if (e.code === "Space") state.running = !state.running; // 空格开始/暂停
  });

  window.addEventListener("keyup", (e) => { // 键盘抬起
    if (e.key === "ArrowLeft" || e.key === "a" || e.key === "A") state.left = false; // 左松开
    if (e.key === "ArrowRight" || e.key === "d" || e.key === "D") state.right = false; // 右松开
  });

  resetBricks(); // 初始化砖块
  resetRound(); // 初始化回合
  loop(); // 启动渲染循环

  window.BREAKOUT = { // 暴露一个小接口给菜单调用
    start() { state.running = false; }, // 进入页面时先暂停（按空格开始）
  };
})();
