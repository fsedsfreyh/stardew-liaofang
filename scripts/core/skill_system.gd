# SkillSystem — 技能等级系统
# 耕种(Farming)、采集(Foraging)、战斗(Combat)、钓鱼(Fishing)
extends Node

signal skill_level_up(skill_name: String, level: int)

enum Skill { FARMING, FORAGING, COMBAT, FISHING }

const SKILL_NAMES = ["耕种", "采集", "战斗", "钓鱼"]
const MAX_LEVEL = 10
const EXP_PER_LEVEL = [0, 15, 35, 60, 90, 125, 165, 210, 260, 315, 380]

var levels: Dictionary = {}  # Skill -> level
var exp: Dictionary = {}  # Skill -> current_exp

func _ready():
    for s in Skill.values():
        levels[s] = 1
        exp[s] = 0

func add_exp(skill: int, amount: int):
    if not exp.has(skill):
        exp[skill] = 0
        levels[skill] = 1
    exp[skill] += amount
    var lv = levels[skill]
    if lv >= MAX_LEVEL:
        exp[skill] = min(exp[skill], EXP_PER_LEVEL[MAX_LEVEL])
        return
    var need = EXP_PER_LEVEL[lv + 1] - EXP_PER_LEVEL[lv]
    while exp[skill] >= EXP_PER_LEVEL[lv + 1] and lv < MAX_LEVEL:
        lv += 1
        levels[skill] = lv
        skill_level_up.emit(SKILL_NAMES[skill], lv)
        if lv >= MAX_LEVEL:
            break

func get_level(skill: int) -> int:
    return levels.get(skill, 1)

func get_exp(skill: int) -> int:
    return exp.get(skill, 0)

func get_exp_to_next(skill: int) -> int:
    var lv = get_level(skill)
    if lv >= MAX_LEVEL:
        return 0
    return EXP_PER_LEVEL[lv + 1] - get_exp(skill)

func get_progress(skill: int) -> float:
    var lv = get_level(skill)
    if lv >= MAX_LEVEL:
        return 1.0
    var cur = get_exp(skill)
    var prev = EXP_PER_LEVEL[lv]
    var next_lv = EXP_PER_LEVEL[lv + 1]
    return float(cur - prev) / float(next_lv - prev)

func get_save_data() -> Dictionary:
    var data = {}
    for s in Skill.values():
        data[str(s)] = {"level": levels.get(s, 1), "exp": exp.get(s, 0)}
    return data

func load_data(data: Dictionary):
    for key in data:
        var sid = int(key)
        levels[sid] = data[key].get("level", 1)
        exp[sid] = data[key].get("exp", 0)
