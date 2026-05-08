## Autoload: 羁绊系统管理器
## 监听蛇形成员变化，计算各职业数量，触发羁绊效果。
## Lifetime: 整个游戏会话。
extends Node

# ─── 职业枚举（与 UnitData 保持一致）────────────────────────
enum UnitClass {
	WARRIOR  = 0,
	MAGE     = 1,
	RANGER   = 2,
	DRIFTER  = 3,
	ENGINEER = 4
}

# ─── 羁绊等级 ──────────────────────────────────────────────
enum BondTier {
	NONE     = 0,
	SILVER   = 1,  # 2人
	GOLD     = 2,  # 4人
	PLATINUM = 3   # 6人
}

## 各职业的羁绊阈值
const BOND_THRESHOLDS: Array[int] = [2, 4, 6]

## 当前各职业激活等级
var _active_tiers: Dictionary = {}
## 当前各职业人数快照
var _class_counts: Dictionary = {}

func _ready() -> void:
	EventBus.snake_composition_changed.connect(_on_snake_composition_changed)
	_reset_counts()

func _reset_counts() -> void:
	for cls: int in UnitClass.values():
		_class_counts[cls] = 0
		_active_tiers[cls] = BondTier.NONE

## 外部调用：更新蛇形成员列表，重新计算所有羁绊
func refresh(units: Array[Node]) -> void:
	_reset_counts()
	for unit: Node in units:
		if unit.has_method("get_unit_class"):
			var cls: int = unit.get_unit_class()
			_class_counts[cls] = _class_counts.get(cls, 0) + 1
	_evaluate_all_bonds()

func _on_snake_composition_changed() -> void:
	# SnakeManager 负责调用 refresh()
	pass

func _evaluate_all_bonds() -> void:
	for cls: int in UnitClass.values():
		var count: int = _class_counts.get(cls, 0)
		var new_tier: int = _calculate_tier(count)
		var old_tier: int = _active_tiers.get(cls, BondTier.NONE)

		if new_tier != old_tier:
			_active_tiers[cls] = new_tier
			if new_tier > BondTier.NONE:
				EventBus.bond_activated.emit(cls, new_tier)
			else:
				EventBus.bond_deactivated.emit(cls)

func _calculate_tier(count: int) -> int:
	if count >= BOND_THRESHOLDS[2]:
		return BondTier.PLATINUM
	elif count >= BOND_THRESHOLDS[1]:
		return BondTier.GOLD
	elif count >= BOND_THRESHOLDS[0]:
		return BondTier.SILVER
	return BondTier.NONE

## 查询指定职业当前激活等级
func get_tier(unit_class: int) -> int:
	return _active_tiers.get(unit_class, BondTier.NONE)

## 查询指定职业当前人数
func get_count(unit_class: int) -> int:
	return _class_counts.get(unit_class, 0)

## 白金级伤害上限（P0漏洞修复：单次不超过目标最大HP的70%）
const PLATINUM_DAMAGE_CAP_RATIO: float = 0.70
func apply_damage_cap(damage: float, target_max_hp: float, is_platinum_skill: bool) -> float:
	if is_platinum_skill:
		return minf(damage, target_max_hp * PLATINUM_DAMAGE_CAP_RATIO)
	return damage
