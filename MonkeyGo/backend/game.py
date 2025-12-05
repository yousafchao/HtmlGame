# -*- coding: utf-8 -*-  # 指定源文件编码，避免中文注释乱码
from __future__ import annotations  # 允许在类型标注里提前引用类名（更清晰但不影响初学者理解）
from dataclasses import dataclass, field  # 用 dataclass 让“数据结构”更直观
from typing import List, Optional, Tuple  # 用于标注类型，帮助你读懂变量里装的是什么


BOARD_SIZE: int = 15  # 五子棋常见棋盘大小：15x15
EMPTY: int = 0  # 空格用 0 表示
HUMAN: int = 1  # 人类棋子用 1 表示
MONKEY: int = 2  # 赛博猴子棋子用 2 表示
WIN_COUNT: int = 5  # 连成 5 个就胜利


@dataclass  # 声明这是一个“数据类”，专门用来存游戏状态
class GameState:  # 游戏状态类：把棋盘、轮到谁、赢家等信息放在一起
    board: List[List[int]] = field(default_factory=lambda: [[EMPTY for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)])  # 初始化棋盘为全空
    current: int = HUMAN  # 当前轮到谁走，默认人类先手
    winner: int = EMPTY  # 胜者：0 表示还没有赢家
    last_move: Optional[Tuple[int, int]] = None  # 最近一步落子坐标（行,列），用于前端高亮
    difficulty: str = "normal"  # 难度：easy/normal/hard

    def reset(self, difficulty: str) -> None:  # 重开一局，重置所有状态
        self.board = [[EMPTY for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]  # 重新生成全空棋盘
        self.current = HUMAN  # 重开默认人类先手
        self.winner = EMPTY  # 清空赢家
        self.last_move = None  # 清空最后一步
        self.difficulty = difficulty  # 记录难度供 AI 使用

    def in_bounds(self, r: int, c: int) -> bool:  # 判断坐标是否在棋盘范围内
        return 0 <= r < BOARD_SIZE and 0 <= c < BOARD_SIZE  # 只要行列都在 0~14 就合法

    def is_empty(self, r: int, c: int) -> bool:  # 判断某个格子是否为空
        return self.board[r][c] == EMPTY  # 等于 EMPTY 就是空

    def place(self, r: int, c: int, who: int) -> bool:  # 尝试落子：成功返回 True，失败返回 False
        if self.winner != EMPTY:  # 如果已经有人赢了
            return False  # 就不允许再落子
        if not self.in_bounds(r, c):  # 如果坐标越界
            return False  # 也不允许落
        if not self.is_empty(r, c):  # 如果该格不是空的
            return False  # 也不允许覆盖别人
        self.board[r][c] = who  # 把棋子写进棋盘
        self.last_move = (r, c)  # 记录最后一步
        if self.check_win(r, c, who):  # 检查这一步是否形成胜利
            self.winner = who  # 如果赢了，就记录赢家
        else:  # 如果没赢
            self.current = HUMAN if who == MONKEY else MONKEY  # 切换回合：人类和猴子互换
        return True  # 落子成功

    def check_win(self, r: int, c: int, who: int) -> bool:  # 判断某一步是否导致胜利
        directions = [(1, 0), (0, 1), (1, 1), (1, -1)]  # 四个方向：竖、横、两条斜线
        for dr, dc in directions:  # 逐个方向检查
            count = 1  # 先把当前这个子算 1 个
            count += self._count_one_direction(r, c, who, dr, dc)  # 正方向延伸数子
            count += self._count_one_direction(r, c, who, -dr, -dc)  # 反方向延伸数子
            if count >= WIN_COUNT:  # 如果连起来 >= 5
                return True  # 就赢了
        return False  # 四个方向都没达到 5，就没赢

    def _count_one_direction(self, r: int, c: int, who: int, dr: int, dc: int) -> int:  # 从(r,c)往一个方向数连续同色棋子
        total = 0  # 这个方向连续的数量
        rr = r + dr  # 先走到下一个格子
        cc = c + dc  # 先走到下一个格子
        while self.in_bounds(rr, cc) and self.board[rr][cc] == who:  # 只要不越界且同色
            total += 1  # 连续数量+1
            rr += dr  # 再往前走
            cc += dc  # 再往前走
        return total  # 返回这个方向的连续数量

    def to_dict(self) -> dict:  # 把状态变成“前端能看懂的字典”，方便返回 JSON
        return {  # 用一个字典打包所有信息
            "boardSize": BOARD_SIZE,  # 棋盘大小
            "board": self.board,  # 棋盘二维数组
            "current": self.current,  # 当前轮到谁
            "winner": self.winner,  # 赢家
            "lastMove": list(self.last_move) if self.last_move else None,  # 最后一步（转成 list 更适合 JSON）
            "difficulty": self.difficulty,  # 当前难度
        }  # 字典结束
