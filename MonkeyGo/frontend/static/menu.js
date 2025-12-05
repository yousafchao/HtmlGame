const menu = document.querySelector(".menu"); // 主菜单卡片
const gomokuRoot = document.getElementById("gomokuRoot"); // 五子棋容器
const breakoutRoot = document.getElementById("breakoutRoot"); // 打砖块容器
const btnGo = document.getElementById("btnGo"); // 进入五子棋按钮
const btnBreak = document.getElementById("btnBreak"); // 进入打砖块按钮
const backMenuFromGo = document.getElementById("backMenuFromGo"); // 五子棋返回菜单
const backMenuFromBreak = document.getElementById("backMenuFromBreak"); // 打砖块返回菜单

function showMenu() { // 显示菜单
  menu.classList.remove("hidden"); // 菜单显示
  gomokuRoot.classList.add("hidden"); // 隐藏五子棋
  breakoutRoot.classList.add("hidden"); // 隐藏打砖块
}

function showGomoku() { // 显示五子棋
  menu.classList.add("hidden"); // 隐藏菜单
  gomokuRoot.classList.remove("hidden"); // 显示五子棋
  breakoutRoot.classList.add("hidden"); // 隐藏打砖块
}

function showBreakout() { // 显示打砖块
  menu.classList.add("hidden"); // 隐藏菜单
  gomokuRoot.classList.add("hidden"); // 隐藏五子棋
  breakoutRoot.classList.remove("hidden"); // 显示打砖块
  if (window.BREAKOUT && typeof window.BREAKOUT.start === "function") { // 如果打砖块模块已加载
    window.BREAKOUT.start(); // 自动进入可玩的状态
  }
}

btnGo.addEventListener("click", showGomoku); // 点击进入五子棋
btnBreak.addEventListener("click", showBreakout); // 点击进入打砖块
backMenuFromGo.addEventListener("click", showMenu); // 五子棋返回菜单
backMenuFromBreak.addEventListener("click", showMenu); // 打砖块返回菜单

showMenu(); // 页面首次进入默认显示菜单
