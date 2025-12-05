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
