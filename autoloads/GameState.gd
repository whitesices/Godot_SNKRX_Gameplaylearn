## Global game state manager.
## Tracks gold, wave number, score, and phase.
## Lifetime: entire game session. Reset on new game.
extends Node

# ─── 游戏阶段枚举 ─────────────────────────────────────────────
enum Phase {
	WAVE,      # 战斗阶段
	SHOP,      # 商店阶段
	GAME_OVER  # 游戏结束
}

# ─── 状态变量 ─────────────────────────────────────────────────
var gold: int = 0 :
	set(value):
		gold = max(0, value)
		EventBus.gold_changed.emit(gold)

var wave_number: int = 0
var score: int = 0
var current_phase: Phase = Phase.SHOP
var snake_max_length: int = 7  ## 初始蛇长上限7格，玩家从单人出发逐步购买

# ─── 常量 ─────────────────────────────────────────────────────
const STARTING_GOLD: int = 10
const GOLD_PER_WAVE_BASE: int = 5
const GOLD_PER_WAVE_BONUS_MAX: int = 5  # 随机奖励0-5
const SHOP_REFRESH_COST: int = 2
const UNIT_BASE_COST: int = 3
## 每2关蛇长+1
const SNAKE_LENGTH_INCREASE_INTERVAL: int = 2

func _ready() -> void:
	reset()

func reset() -> void:
	gold = STARTING_GOLD
	wave_number = 0
	score = 0
	current_phase = Phase.SHOP
	snake_max_length = 7

func start_new_wave() -> void:
	wave_number += 1
	current_phase = Phase.WAVE
	# 每2关蛇长+1
	if wave_number % SNAKE_LENGTH_INCREASE_INTERVAL == 0:
		snake_max_length += 1
	EventBus.wave_started.emit(wave_number)

func complete_wave() -> void:
	current_phase = Phase.SHOP
	# 发放金币奖励（5-10金币）
	var reward: int = GOLD_PER_WAVE_BASE + randi_range(0, GOLD_PER_WAVE_BONUS_MAX)
	gold += reward
	score += wave_number * 100
	EventBus.wave_completed.emit(wave_number)

func try_purchase_refresh() -> bool:
	if gold < SHOP_REFRESH_COST:
		return false
	gold -= SHOP_REFRESH_COST
	return true

func try_purchase_unit(cost: int) -> bool:
	if gold < cost:
		return false
	gold -= cost
	return true

## 根据当前关卡数返回各星级单位概率（概率总和=1.0）
func get_unit_tier_weights() -> Array[float]:
	match wave_number:
		1, 2, 3:
			return [0.70, 0.25, 0.05, 0.00, 0.00]
		4, 5, 6:
			return [0.50, 0.35, 0.12, 0.03, 0.00]
		7, 8, 9:
			return [0.30, 0.35, 0.25, 0.08, 0.02]
		10, 11, 12:
			return [0.15, 0.25, 0.35, 0.20, 0.05]
		_:
			return [0.05, 0.15, 0.30, 0.35, 0.15]
