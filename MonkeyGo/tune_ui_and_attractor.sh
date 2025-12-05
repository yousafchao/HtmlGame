#!/usr/bin/env bash
set -euo pipefail
cd /Users/gaochao/PycharmProjects/MonkeyGo

# ===== A) 五子棋棋盘：保证一屏显示（同时兼容 boardCanvas / gomokuCanvas 两种 id）=====
# 思路：用 vmin + 最大像素限制，让棋盘永远不会撑出屏幕；并减少容器的过大 padding
cat >> frontend/static/style.css <<'CSS'

/* ===== 一屏棋盘：让五子棋盘不需要滚动 ===== */
.board-zone, .gomoku-zone, #gomokuRoot {              /* 兼容不同页面结构 */
  max-height: calc(100vh - 140px) !important;         /* 预留顶部标题/按钮空间 */
  overflow: hidden !important;                         /* 避免出现滚动条 */
}

/* 棋盘 canvas：优先按屏幕短边缩放，并限制最大尺寸 */
#boardCanvas, #gomokuCanvas {
  width: min(76vmin, 640px) !important;               /* ✅ 关键：一屏可见（76vmin）且不超过 640px */
  height: auto !important;                             /* 高度随宽度缩放 */
  aspect-ratio: 1 / 1 !important;                      /* 保持正方形 */
  display: block !important;
  margin: 0 auto !important;
}

/* 让棋盘卡片别太“肥” */
.board-zone {
  padding: 10px !important;
}

/* 右侧面板略窄一点（如果你是左右布局），避免把棋盘挤出屏幕 */
.main {
  grid-template-columns: 1fr 320px !important;
}
CSS

# ===== B) 吸引子：居中 + 放大 5 倍，然后重新渲染并复制到 static =====
# 放大：原来 *0.08 -> *0.40（5倍）
# 居中：减去轨迹点的均值（让蝴蝶中心回到 0,0,0）
SCENE="manim_scenes/cyber_attractor.py"
if [ ! -f "$SCENE" ]; then
  echo "❌ 找不到 $SCENE（请确认你之前已经生成过 Manim 场景文件）"
  exit 1
fi

python - <<'PY'
import re, pathlib
p = pathlib.Path("manim_scenes/cyber_attractor.py")
s = p.read_text(encoding="utf-8")

# 1) 把缩放那行替换为“居中 + 5倍缩放”
# 兼容你旧代码里常见的：pts = np.array(pts) * 0.08
s2, n = re.subn(
    r"pts\s*=\s*np\.array\(pts\)\s*\*\s*0\.08",
    "pts = (np.array(pts) - np.mean(pts, axis=0)) * 0.40  # 居中并放大5倍（0.08*5=0.40）",
    s
)

# 2) 万一你之前不是 0.08，也尽量兜底：找到 “pts = np.array(pts) * X” 就替换
if n == 0:
    s2, n = re.subn(
        r"pts\s*=\s*np\.array\(pts\)\s*\*\s*([0-9]*\.?[0-9]+)",
        "pts = (np.array(pts) - np.mean(pts, axis=0)) * (\\1*5)  # 居中并放大5倍",
        s
    )

# 3) 让相机框住更大的吸引子：把 zoom 稍微调低一点（画面更“装得下”）
s3 = re.sub(
    r"zoom\s*=\s*1\.2",
    "zoom=0.95  # 放大后避免裁切，略拉远镜头",
    s2
)

p.write_text(s3, encoding="utf-8")
print("patched:", p)
PY

# 重新渲染
python -m manim -qh manim_scenes/cyber_attractor.py CyberAttractor -o attractor.mp4

# 复制到静态目录
VIDEO_PATH="$(find media -type f -name 'attractor.mp4' | head -n 1)"
mkdir -p frontend/static
cp "$VIDEO_PATH" frontend/static/attractor.mp4

echo "✅ 完成：棋盘一屏化 + 吸引子居中放大5倍"
ls -lh frontend/static/attractor.mp4
