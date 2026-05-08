## 羁绊效果处理器：监听 BondSystem 信号，对单位施加实际效果。
## 每种职业的每个等级效果均在此集中管理。
class_name BondEffectHandler
extends Node

## 当前激活的周期性效果计时器
var _periodic_timers: Dictionary = {}

func _ready() -> void:
	EventBus.bond_activated.connect(_on_bond_activated)
	EventBus.bond_deactivated.connect(_on_bond_deactivated)

func _on_bond_activated(unit_class: int, tier: int) -> void:
	match unit_class:
		BondSystem.UnitClass.WARRIOR:
			_apply_warrior_bond(tier)
		BondSystem.UnitClass.MAGE:
			_apply_mage_bond(tier)
		BondSystem.UnitClass.RANGER:
			_apply_ranger_bond(tier)
		BondSystem.UnitClass.DRIFTER:
			_apply_drifter_bond(tier)
		BondSystem.UnitClass.ENGINEER:
			_apply_engineer_bond(tier)

func _on_bond_deactivated(unit_class: int) -> void:
	# 取消该职业的所有周期性效果
	var key: String = "class_%d" % unit_class
	if _periodic_timers.has(key):
		var timer: Timer = _periodic_timers[key] as Timer
		if is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
		_periodic_timers.erase(key)
	# 重置所有该职业单位的增益
	_reset_class_modifiers(unit_class)

## ── 战士羁绊 ──────────────────────────────────────────────────
func _apply_warrior_bond(tier: int) -> void:
	var warriors: Array[Node2D] = _get_units_of_class(BondSystem.UnitClass.WARRIOR)
	match tier:
		BondSystem.BondTier.SILVER:
			# 20% 概率伤害反弹（在 CombatComponent 中通过标志实现）
			for w: Node2D in warriors:
				_set_unit_flag(w, "damage_reflect_chance", 0.20)
		BondSystem.BondTier.GOLD:
			# 吸血 5%
			for w: Node2D in warriors:
				var combat: CombatComponent = w.get_node_or_null("CombatComponent")
				if combat:
					combat.lifesteal_active = true
					# P2修复：通过公开方法获取数据，避免直接访问私有 _data
					var unit_dat: UnitData = w.get_data() if w.has_method("get_data") else null
					if unit_dat != null:
						unit_dat.lifesteal_ratio = 0.05
		BondSystem.BondTier.PLATINUM:
			# 每 15s 随机一个战士触发无敌帧 1.5s
			_start_periodic("class_0", 15.0, func() -> void:
				var alive_warriors: Array[Node2D] = _get_units_of_class(BondSystem.UnitClass.WARRIOR)
				if alive_warriors.is_empty():
					return
				var chosen: Node2D = alive_warriors.pick_random()
				var hp: HealthComponent = chosen.get_node_or_null("HealthComponent")
				if hp:
					hp.invincibility_duration = 1.5
					hp.grant_invincibility(1.5)
			)

## ── 法师羁绊 ──────────────────────────────────────────────────
func _apply_mage_bond(tier: int) -> void:
	var mages: Array[Node2D] = _get_units_of_class(BondSystem.UnitClass.MAGE)
	match tier:
		BondSystem.BondTier.SILVER:
			for m: Node2D in mages:
				_set_unit_flag(m, "element_mark_active", true)
		BondSystem.BondTier.GOLD:
			for m: Node2D in mages:
				_set_unit_flag(m, "bullet_bounce", 2)
		BondSystem.BondTier.PLATINUM:
			# 每 20s 全体法师全屏AOE（P0修复：白金伤害上限）
			_start_periodic("class_1", 20.0, func() -> void:
				var alive_mages: Array[Node2D] = _get_units_of_class(BondSystem.UnitClass.MAGE)
				var total_damage: float = 0.0
				for m: Node2D in alive_mages:
					# P2修复：通过公开方法获取数据，避免直接访问私有 _data
					var mdat: UnitData = m.get_data() if m.has_method("get_data") else null
					if mdat != null:
						total_damage += mdat.damage * 5.0  # 500% 各法师攻击力
				# 对屏幕内所有敌人造成伤害（带上限）
				var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
				for e: Node in enemies:
					var hp: HealthComponent = e.get_node_or_null("HealthComponent")
					if hp:
						var capped: float = BondSystem.apply_damage_cap(total_damage, hp.max_hp, true)
						hp.apply_damage(capped)
			)

## ── 游侠羁绊 ──────────────────────────────────────────────────
func _apply_ranger_bond(tier: int) -> void:
	var rangers: Array[Node2D] = _get_units_of_class(BondSystem.UnitClass.RANGER)
	match tier:
		BondSystem.BondTier.SILVER:
			for r: Node2D in rangers:
				var combat: CombatComponent = r.get_node_or_null("CombatComponent")
				if combat:
					combat.damage_multiplier = 1.5  # 暴击+50%（近似处理）
		BondSystem.BondTier.GOLD:
			for r: Node2D in rangers:
				_set_unit_flag(r, "mark_on_first_hit", true)
		BondSystem.BondTier.PLATINUM:
			_start_periodic("class_2", 12.0, func() -> void:
				_fire_arrow_rain()
			)

## ── 流浪者羁绊 ────────────────────────────────────────────────
func _apply_drifter_bond(tier: int) -> void:
	var drifters: Array[Node2D] = _get_units_of_class(BondSystem.UnitClass.DRIFTER)
	match tier:
		BondSystem.BondTier.SILVER:
			for d: Node2D in drifters:
				_set_unit_flag(d, "chaos_proc_active", true)
		BondSystem.BondTier.GOLD:
			_start_periodic("class_3", 10.0, func() -> void:
				_apply_fortune_wheel()
			)
		BondSystem.BondTier.PLATINUM:
			for d: Node2D in drifters:
				_set_unit_flag(d, "gambler_talent_active", true)

## ── 工程师羁绊 ────────────────────────────────────────────────
func _apply_engineer_bond(tier: int) -> void:
	match tier:
		BondSystem.BondTier.SILVER:
			_start_periodic("class_4_turret", 8.0, func() -> void:
				_spawn_turret()
			)
		BondSystem.BondTier.GOLD:
			_start_periodic("class_4_repair", 15.0, func() -> void:
				_spawn_repair_bot()
			)
		BondSystem.BondTier.PLATINUM:
			_start_periodic("class_4_laser", 30.0, func() -> void:
				_fire_laser()
			)

## ── 工具方法 ──────────────────────────────────────────────────
func _get_units_of_class(unit_class: int) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var all_units: Array[Node] = get_tree().get_nodes_in_group("units")
	for u: Node in all_units:
		if u is Node2D and u.has_method("get_unit_class"):
			if u.get_unit_class() == unit_class:
				result.append(u as Node2D)
	return result

func _set_unit_flag(unit: Node2D, flag_name: String, value: Variant) -> void:
	if unit.has_method("set_bond_flag"):
		unit.set_bond_flag(flag_name, value)
	else:
		# 直接设置元数据作为后备
		unit.set_meta(flag_name, value)

func _reset_class_modifiers(unit_class: int) -> void:
	var units: Array[Node2D] = _get_units_of_class(unit_class)
	for u: Node2D in units:
		var combat: CombatComponent = u.get_node_or_null("CombatComponent")
		if combat:
			combat.damage_multiplier = 1.0
			combat.lifesteal_active = false

func _start_periodic(key: String, interval: float, callback: Callable) -> void:
	if _periodic_timers.has(key):
		var old_timer: Timer = _periodic_timers[key] as Timer
		if is_instance_valid(old_timer):
			old_timer.stop()
			old_timer.queue_free()
	var timer: Timer = Timer.new()
	timer.wait_time = interval
	timer.autostart = true
	timer.timeout.connect(callback)
	add_child(timer)
	_periodic_timers[key] = timer
	# 立即触发一次
	callback.call()

## ── 技能实现（简化版） ──────────────────────────────────────
func _fire_arrow_rain() -> void:
	# 向最密集敌人区域发射12支箭（简化：从所有游侠位置各发射）
	var rangers: Array[Node2D] = _get_units_of_class(BondSystem.UnitClass.RANGER)
	for r: Node2D in rangers:
		var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
		for _i: int in range(2):
			if enemies.is_empty():
				break
			var target: Node = enemies.pick_random()
			var bullet: Node = BulletPool.get_bullet()
			if bullet and bullet.has_method("setup"):
				var data: UnitData = r.get_node_or_null("CombatComponent").unit_data if r.has_node("CombatComponent") else null
				if data:
					bullet.setup(r.global_position, target, data.damage, UnitData.BulletType.PROJECTILE, 500.0, 1)

func _apply_fortune_wheel() -> void:
	var units: Array[Node] = get_tree().get_nodes_in_group("units")
	if units.is_empty():
		return
	var chosen: Node = units.pick_random()
	var roll: int = randi_range(0, 2)
	var hp: HealthComponent = chosen.get_node_or_null("HealthComponent")
	match roll:
		0:  # 无敌1s
			if hp:
				hp._is_invincible = true
				hp._invincibility_timer = 1.0
		1:  # 攻速+100% 3s
			var combat: CombatComponent = chosen.get_node_or_null("CombatComponent")
			if combat:
				combat.attack_speed_multiplier = 2.0
				await get_tree().create_timer(3.0).timeout
				combat.attack_speed_multiplier = 1.0
		2:  # 伤害+200% 2s
			var combat: CombatComponent = chosen.get_node_or_null("CombatComponent")
			if combat:
				combat.damage_multiplier = 3.0
				await get_tree().create_timer(2.0).timeout
				combat.damage_multiplier = 1.0

func _spawn_turret() -> void:
	# 工程师银羁绊：在首领前方放置炮台
	# TODO: 待 scenes/effects/Turret.tscn 实现后替换以下占位逻辑
	var head_group: Array[Node] = get_tree().get_nodes_in_group("units")
	if head_group.is_empty():
		return
	# 炮台场景预留位置：在首领位置生成（后续迭代添加）
	@warning_ignore("unused_variable")
	var _head: Node2D = head_group[0] as Node2D

func _spawn_repair_bot() -> void:
	var units: Array[Node] = get_tree().get_nodes_in_group("units")
	if units.is_empty():
		return
	# 找HP最低的单位
	var lowest: Node = null
	var lowest_ratio: float = INF
	for u: Node in units:
		var hp: HealthComponent = u.get_node_or_null("HealthComponent")
		if hp and hp.get_hp_ratio() < lowest_ratio:
			lowest_ratio = hp.get_hp_ratio()
			lowest = u
	if lowest:
		var hp: HealthComponent = lowest.get_node_or_null("HealthComponent")
		if hp:
			hp.heal(hp.max_hp * 0.25)

func _fire_laser() -> void:
	# 激光持续3s伤害所有敌人
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var laser_duration: float = 3.0
	var tick_interval: float = 0.1
	var ticks: int = int(laser_duration / tick_interval)
	for _i: int in range(ticks):
		await get_tree().create_timer(tick_interval).timeout
		for e: Node in get_tree().get_nodes_in_group("enemies"):
			var hp: HealthComponent = e.get_node_or_null("HealthComponent")
			if hp:
				hp.apply_damage(5.0)  # 每tick 5点伤害（[PLACEHOLDER]）
