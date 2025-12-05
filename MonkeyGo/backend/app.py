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
    app.run(host="0.0.0.0", port=5051, debug=True)
