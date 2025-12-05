set -euo pipefail
cd /Users/gaochao/PycharmProjects/MonkeyGo

source .venv/bin/activate

# 1) 确保 ffmpeg 可用（Manim 导出 mp4 依赖它）
if ! command -v ffmpeg >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install ffmpeg
  else
    echo "❌ 没有 ffmpeg 且没有 brew：请先安装 ffmpeg。"
    exit 1
  fi
fi

# 2) 安装 manim（如果已装会跳过）
python -m pip install -U pip
python -m pip install manim

# 3) 写一个最小的吸引子场景（洛伦兹）
mkdir -p manim_scenes
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
        curve.set_stroke(color=TEAL_A, width=2, opacity=0.8)
        self.play(Create(curve), run_time=2)
        self.begin_ambient_camera_rotation(rate=0.12)
        self.wait(8)
PY

# 4) 渲染 mp4（-qh：较快高清；想更清晰用 -qk）
manim -qh manim_scenes/cyber_attractor.py CyberAttractor -o attractor.mp4

# 5) 把输出的 mp4 拷贝到 static
VIDEO_PATH="$(find media -type f -name 'attractor.mp4' | head -n 1)"
cp "$VIDEO_PATH" frontend/static/attractor.mp4

ls -lh frontend/static/attractor.mp4
echo "✅ 已生成并放置 frontend/static/attractor.mp4"
