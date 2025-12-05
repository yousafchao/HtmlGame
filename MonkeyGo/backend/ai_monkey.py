# -*- coding: utf-8 -*-  # 指定编码
from __future__ import annotations  # 允许在类型标注中提前引用
from typing import List, Tuple, Optional  # 类型标注：让代码更易读
import random  # 简单难度会用到随机选择
from backend.game import BOARD_SIZE, EMPTY, HUMAN, MONKEY, WIN_COUNT, GameState  # 导入游戏常量与状态类


def monkey_choose_move(state: GameState) -> Tuple[int, int]:  # 猴子AI选择一步（返回 行,列）
    difficulty = state.difficulty  # 读取当前难度
    candidates = _generate_candidates(state.board)  # 生成“值得考虑”的候选点（避免全棋盘暴力扫描）
    if not candidates:  # 如果棋盘完全为空（或极端情况）
        center = BOARD_SIZE // 2  # 中心点通常是好开局
        return (center, center)  # 直接下中心

    win_now = _find_immediate_win(state.board, MONKEY, candidates)  # 先看自己有没有“一步必胜”
    if win_now is not None:  # 如果存在必胜点
        return win_now  # 直接下它

    block_human = _find_immediate_win(state.board, HUMAN, candidates)  # 再看人类有没有“一步必胜”
    if block_human is not None:  # 如果人类下一步能赢
        return block_human  # 赶紧堵住

    if difficulty == "easy":  # 简单难度：更“犯错”，随机性更高
        top_moves = _pick_top_k_by_score(state.board, candidates, k=6, who=MONKEY)  # 先挑几个看起来不错的点
        return random.choice(top_moves)  # 从这些点里随机选一个（显得不那么聪明）

    if difficulty == "normal":  # 普通难度：只看“这一步”好不好
        return _best_by_heuristic(state.board, candidates, who=MONKEY)  # 直接用评分选最优

    # 困难难度：做一个很浅的“向前想两步”（我走一步 + 你走一步），但仍然保持可读性
    return _best_by_two_step_lookahead(state.board, candidates)  # 返回两步预测下的最好点


def _generate_candidates(board: List[List[int]]) -> List[Tuple[int, int]]:  # 生成候选点：只考虑已有棋子附近
    occupied = []  # 记录所有已落子的坐标
    for r in range(BOARD_SIZE):  # 扫描每一行
        for c in range(BOARD_SIZE):  # 扫描每一列
            if board[r][c] != EMPTY:  # 如果这里有子
                occupied.append((r, c))  # 加入已占用列表

    if not occupied:  # 如果棋盘还没有任何棋子
        return []  # 交给外层在中心开局

    cand_set = set()  # 用集合去重，避免同一个候选点重复加入
    for (r, c) in occupied:  # 对每个已占用点
        for dr in range(-2, 3):  # 在它周围“半径2格”范围找点
            for dc in range(-2, 3):  # 在它周围“半径2格”范围找点
                rr = r + dr  # 候选行
                cc = c + dc  # 候选列
                if 0 <= rr < BOARD_SIZE and 0 <= cc < BOARD_SIZE:  # 如果不越界
                    if board[rr][cc] == EMPTY:  # 并且这个格子是空的
                        cand_set.add((rr, cc))  # 加入候选集合

    return list(cand_set)  # 转成列表返回


def _find_immediate_win(board: List[List[int]], who: int, candidates: List[Tuple[int, int]]) -> Optional[Tuple[int, int]]:  # 找“一步就能赢”的点
    for (r, c) in candidates:  # 遍历候选点
        board[r][c] = who  # 假装这里落子
        if _check_win_board(board, r, c, who):  # 看是否赢了
            board[r][c] = EMPTY  # 还原棋盘
            return (r, c)  # 返回这个必胜点
        board[r][c] = EMPTY  # 如果没赢，也要还原
    return None  # 没找到必胜点


def _best_by_heuristic(board: List[List[int]], candidates: List[Tuple[int, int]], who: int) -> Tuple[int, int]:  # 用评分函数挑最优
    best_move = candidates[0]  # 先随便把第一个当作最好
    best_score = -10**18  # 先给一个非常小的分数
    for (r, c) in candidates:  # 遍历候选点
        board[r][c] = who  # 假装落子
        score = _evaluate_board_simple(board, who)  # 计算这步之后的“局面好坏”
        board[r][c] = EMPTY  # 还原棋盘
        if score > best_score:  # 如果更好
            best_score = score  # 更新最好分数
            best_move = (r, c)  # 更新最好走法
    return best_move  # 返回最优走法


def _best_by_two_step_lookahead(board: List[List[int]], candidates: List[Tuple[int, int]]) -> Tuple[int, int]:  # 困难：往前想两步
    best_move = candidates[0]  # 默认候选第一个
    best_score = -10**18  # 初始化最好分数
    for (r, c) in candidates:  # 遍历我方（猴子）的每个候选走法
        board[r][c] = MONKEY  # 假装猴子走这一步
        if _check_win_board(board, r, c, MONKEY):  # 如果这一步直接赢
            board[r][c] = EMPTY  # 还原棋盘
            return (r, c)  # 直接返回必赢走法

        reply_candidates = _generate_candidates(board)  # 生成对手（人类）可能的回应点
        worst_for_monkey = 10**18  # 假设对手会选一个“最让猴子难受”的回应（分数最低）
        if reply_candidates:  # 如果对手有回应点
            for (rr, cc) in reply_candidates:  # 遍历对手回应
                board[rr][cc] = HUMAN  # 假装人类回应一步
                if _check_win_board(board, rr, cc, HUMAN):  # 如果人类这一步能赢
                    score_after = -10**15  # 那对猴子来说极差，给一个很低分
                else:  # 如果人类没有立刻赢
                    score_after = _evaluate_board_simple(board, MONKEY)  # 用简单评分衡量猴子局面
                board[rr][cc] = EMPTY  # 还原对手落子
                if score_after < worst_for_monkey:  # 对手会选让猴子分数更低的那步
                    worst_for_monkey = score_after  # 更新“最坏情况”
        else:  # 如果没有回应点（几乎不会发生）
            worst_for_monkey = _evaluate_board_simple(board, MONKEY)  # 就直接评分

        board[r][c] = EMPTY  # 还原猴子落子

        if worst_for_monkey > best_score:  # 我们选择“在最坏情况下仍然最好”的走法
            best_score = worst_for_monkey  # 更新最好分数
            best_move = (r, c)  # 更新最好走法

    return best_move  # 返回最终走法


def _pick_top_k_by_score(board: List[List[int]], candidates: List[Tuple[int, int]], k: int, who: int) -> List[Tuple[int, int]]:  # 取评分最高的 K 个走法
    scored = []  # 存 (分数, 走法)
    for (r, c) in candidates:  # 遍历候选点
        board[r][c] = who  # 假装落子
        score = _evaluate_board_simple(board, who)  # 评分
        board[r][c] = EMPTY  # 还原
        scored.append((score, (r, c)))  # 加入列表
    scored.sort(key=lambda x: x[0], reverse=True)  # 按分数从高到低排序
    top = [m for (_, m) in scored[:max(1, min(k, len(scored)))]]  # 取前 K 个（至少取 1 个，避免空）
    return top  # 返回这些走法


def _evaluate_board_simple(board: List[List[int]], who: int) -> int:  # 简化评分：看我方“成线潜力”减去对手“成线潜力”
    my_score = _sum_line_patterns(board, who)  # 我方的线型得分
    opp = HUMAN if who == MONKEY else MONKEY  # 对手是谁
    opp_score = _sum_line_patterns(board, opp)  # 对手的线型得分
    return my_score - int(1.15 * opp_score)  # 略微更看重防守：对手分数乘 1.15 再扣掉


def _sum_line_patterns(board: List[List[int]], who: int) -> int:  # 统计全盘“连续棋子 + 两端是否被堵”的模式得分
    total = 0  # 总评分
    directions = [(1, 0), (0, 1), (1, 1), (1, -1)]  # 四个方向
    for r in range(BOARD_SIZE):  # 扫描每个格子作为起点
        for c in range(BOARD_SIZE):  # 扫描每个格子作为起点
            if board[r][c] != who:  # 不是我方棋子就跳过
                continue  # 继续下一个格子
            for (dr, dc) in directions:  # 对每个方向
                prev_r = r - dr  # 前一个格子行
                prev_c = c - dc  # 前一个格子列
                if 0 <= prev_r < BOARD_SIZE and 0 <= prev_c < BOARD_SIZE and board[prev_r][prev_c] == who:  # 如果前面也是我方
                    continue  # 说明这条线已经从更前面统计过了，避免重复统计
                length, open_ends = _line_info(board, r, c, who, dr, dc)  # 获取这条线长度以及两端是否通畅
                total += _score_for_line(length, open_ends)  # 加上该线型的分数
    return total  # 返回总分


def _line_info(board: List[List[int]], r: int, c: int, who: int, dr: int, dc: int) -> Tuple[int, int]:  # 计算从(r,c)开始的连续长度和开放端数
    length = 0  # 连续棋子长度
    rr = r  # 当前行
    cc = c  # 当前列
    while 0 <= rr < BOARD_SIZE and 0 <= cc < BOARD_SIZE and board[rr][cc] == who:  # 只要不越界且同色
        length += 1  # 长度+1
        rr += dr  # 往前走
        cc += dc  # 往前走

    open_ends = 0  # 两端开放数量：0/1/2
    end1_r = r - dr  # 起点后面那一端
    end1_c = c - dc  # 起点后面那一端
    if 0 <= end1_r < BOARD_SIZE and 0 <= end1_c < BOARD_SIZE and board[end1_r][end1_c] == EMPTY:  # 如果那一端是空的
        open_ends += 1  # 说明一端开放

    end2_r = rr  # 终点前面 while 走过头后的坐标就是终点外侧
    end2_c = cc  # 终点外侧列
    if 0 <= end2_r < BOARD_SIZE and 0 <= end2_c < BOARD_SIZE and board[end2_r][end2_c] == EMPTY:  # 如果终点外侧是空
        open_ends += 1  # 说明另一端也开放

    return (length, open_ends)  # 返回长度和开放端数


def _score_for_line(length: int, open_ends: int) -> int:  # 根据线长度和开放端数给分（越接近赢越高）
    if length >= 5:  # 已经五连
        return 10**12  # 给超大分，代表必赢
    if length == 4 and open_ends == 2:  # 活四（两端都通）
        return 10**9  # 非常强
    if length == 4 and open_ends == 1:  # 冲四（一端被堵）
        return 10**7  # 很强
    if length == 3 and open_ends == 2:  # 活三
        return 10**5  # 中强
    if length == 3 and open_ends == 1:  # 眠三
        return 10**3  # 一般
    if length == 2 and open_ends == 2:  # 活二
        return 200  # 较弱
    if length == 2 and open_ends == 1:  # 眠二
        return 40  # 更弱
    if length == 1 and open_ends == 2:  # 活一
        return 8  # 很小
    return 1  # 其它情况给极小分


def _check_win_board(board: List[List[int]], r: int, c: int, who: int) -> bool:  # 用棋盘直接检查胜利（不依赖 GameState）
    directions = [(1, 0), (0, 1), (1, 1), (1, -1)]  # 四个方向
    for dr, dc in directions:  # 逐方向
        count = 1  # 当前子算 1
        count += _count_dir(board, r, c, who, dr, dc)  # 正方向
        count += _count_dir(board, r, c, who, -dr, -dc)  # 反方向
        if count >= WIN_COUNT:  # 连到 5
            return True  # 胜利
    return False  # 否则不胜


def _count_dir(board: List[List[int]], r: int, c: int, who: int, dr: int, dc: int) -> int:  # 数一个方向连续同色数量
    total = 0  # 计数器
    rr = r + dr  # 下一个格子
    cc = c + dc  # 下一个格子
    while 0 <= rr < BOARD_SIZE and 0 <= cc < BOARD_SIZE and board[rr][cc] == who:  # 只要同色
        total += 1  # +1
        rr += dr  # 继续向前
        cc += dc  # 继续向前
    return total  # 返回数量
