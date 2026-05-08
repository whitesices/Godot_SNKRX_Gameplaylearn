## 蛇形管理器：核心蛇形逻辑。
## 基于历史位置队列（Ring Buffer）实现平滑跟随。
## 由 Main 场景实例化并驱动。
class_name SnakeManager
extends Node2D

## 蛇成员间距（弧长，像素）
@export var unit_spacing: float = 44.0
## 轨迹历史保留的额外长度，保证新加入成员有足够路径可追
@export var history_padding: float = 220.0
## 首领移速（像素/秒）
@export var head_speed: float = 200.0
@export var turn_rate: float = 5.5
## 单位场景
@export var unit_scene: PackedScene

## 当前蛇成员列表（index 0 = 首领）
var _units: Array[Node2D] = []
## 首领历史位置队列（Ring Buffer）
var _position_history: PackedVector2Array = PackedVector2Array()
## SpatialHashGrid 引用
var _spatial_grid: SpatialHashGrid

## 移动方向（由玩家输入更新）
var _move_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_ensure_input_actions()
	_spatial_grid = SpatialHashGrid.new()
	add_child(_spatial_grid)
	EventBus.unit_died.connect(_on_unit_died)

func _physics_process(delta: float) -> void:
	if _units.is_empty():
		return
	_process_head_movement(delta)
	_distribute_positions()
	_rebuild_spatial_grid()

## ── 移动逻辑 ─────────────────────────────────────────────────

func _process_head_movement(delta: float) -> void:
	var head: Node2D = _units[0]
	if not is_instance_valid(head):
		return

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length_squared() > 0.01:
		var desired: Vector2 = input_dir.normalized()
		var angle_delta: float = clampf(_move_direction.angle_to(desired), -turn_rate * delta, turn_rate * delta)
		_move_direction = _move_direction.rotated(angle_delta).normalized()

	head.global_position += _move_direction * head_speed * delta
	_record_head_position(head.global_position)

	# 更新首领 MovementComponent 朝向（首领直接设置位置，朝向用 rotation）
	head.rotation = _move_direction.angle()

## 将历史位置分配给跟随单位
func _distribute_positions() -> void:
	for i: int in range(1, _units.size()):
		var follower: Node2D = _units[i]
		if not is_instance_valid(follower):
			continue
		var follow_distance: float = float(i) * unit_spacing
		var target_pos: Vector2 = _get_point_at_path_distance(follow_distance)
		var facing_pos: Vector2 = _get_point_at_path_distance(maxf(follow_distance - 14.0, 0.0))
		var movement: MovementComponent = follower.get_node_or_null("MovementComponent")
		if movement:
			var tangent: Vector2 = target_pos.direction_to(facing_pos)
			movement.target_position = target_pos
			movement.target_rotation = tangent.angle() if tangent.length_squared() > 0.001 else follower.rotation

## 每帧重建空间哈希网格（供 CombatComponent 查询敌人）
func _rebuild_spatial_grid() -> void:
	# 收集当前场景中所有活跃敌人（由 WaveManager 维护列表）
	var enemies: Array[Node2D] = _get_active_enemies()
	_spatial_grid.rebuild(enemies)
	# 将 spatial_grid 注入所有战斗组件
	for unit: Node2D in _units:
		var combat: CombatComponent = unit.get_node_or_null("CombatComponent")
		if combat:
			combat.spatial_grid = _spatial_grid

func _get_active_enemies() -> Array[Node2D]:
	# 查找 WaveManager 管理的敌人节点组
	var result: Array[Node2D] = []
	var enemies_group: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for e: Node in enemies_group:
		if e is Node2D:
			result.append(e as Node2D)
	return result

## ── 蛇形管理 ─────────────────────────────────────────────────

## 添加新单位到蛇尾
func can_accept_or_upgrade(data: UnitData) -> bool:
	return _find_unit_by_key(data.get_key()) != null or _units.size() < GameState.snake_max_length

func add_or_upgrade_unit(data: UnitData) -> bool:
	var existing: Node2D = _find_unit_by_key(data.get_key())
	if existing != null and existing.has_method("add_copy"):
		existing.add_copy()
		_notify_bond_system()
		EventBus.snake_composition_changed.emit()
		return true
	return add_unit(data)

func add_unit(data: UnitData) -> bool:
	if unit_scene == null:
		push_error("SnakeManager: unit_scene 未设置")
		return false
	if _units.size() >= GameState.snake_max_length:
		push_warning("蛇已达到最大长度 %d" % GameState.snake_max_length)
		return false

	var unit: Node2D = unit_scene.instantiate() as Node2D
	if unit == null:
		return false
	get_parent().add_child(unit)

	# 初始化单位数据
	if unit.has_method("initialize"):
		unit.initialize(data)

	# 新单位从蛇尾位置出发
	if _units.is_empty():
		unit.global_position = global_position
		_seed_history_from_head(unit.global_position)
	else:
		unit.global_position = _get_point_at_path_distance(float(_units.size()) * unit_spacing)

	_units.append(unit)
	# P0修复：第一个单位是首领，后续单位为跟随者
	var is_first: bool = _units.size() == 1
	if unit.has_method("set_as_head"):
		unit.set_as_head(is_first)
	_notify_bond_system()
	EventBus.snake_composition_changed.emit()
	return true

## 移除指定单位
func remove_unit(unit: Node2D) -> void:
	_units.erase(unit)
	if is_instance_valid(unit):
		unit.queue_free()
	_notify_bond_system()
	EventBus.snake_composition_changed.emit()

func _on_unit_died(unit: Node2D) -> void:
	var index: int = _units.find(unit)
	if index == -1:
		return
	var was_head: bool = index == 0
	_units.remove_at(index)
	if _units.is_empty():
		GameState.current_phase = GameState.Phase.GAME_OVER
		return
	if was_head:
		var new_head: Node2D = _units[0]
		if is_instance_valid(new_head) and new_head.has_method("set_as_head"):
			new_head.set_as_head(true)
		EventBus.head_died.emit(new_head)
	_notify_bond_system()
	EventBus.snake_composition_changed.emit()

func _notify_bond_system() -> void:
	var units_typed: Array[Node] = []
	for u: Node2D in _units:
		units_typed.append(u)
	BondSystem.refresh(units_typed)

func get_units() -> Array[Node2D]:
	return _units

func get_head() -> Node2D:
	return _units[0] if not _units.is_empty() else null

func keep_head_inside_rect(bounds: Rect2, margin: float) -> void:
	var head: Node2D = get_head()
	if head == null:
		return
	var min_pos: Vector2 = bounds.position + Vector2(margin, margin)
	var max_pos: Vector2 = bounds.position + bounds.size - Vector2(margin, margin)
	var clamped: Vector2 = Vector2(
		clampf(head.global_position.x, min_pos.x, max_pos.x),
		clampf(head.global_position.y, min_pos.y, max_pos.y)
	)
	if not clamped.is_equal_approx(head.global_position):
		if head.global_position.x != clamped.x:
			_move_direction.x *= -1.0
		if head.global_position.y != clamped.y:
			_move_direction.y *= -1.0
		_move_direction = _move_direction.normalized()
		head.global_position = clamped
		if _position_history.size() > 0:
			_position_history[0] = clamped

func _record_head_position(position: Vector2) -> void:
	if _position_history.is_empty():
		_seed_history_from_head(position)
		return
	if _position_history[0].distance_squared_to(position) < 0.25:
		return
	_position_history.insert(0, position)
	_trim_history()

func _seed_history_from_head(position: Vector2) -> void:
	_position_history.clear()
	var needed_distance: float = GameState.snake_max_length * unit_spacing + history_padding
	var step: float = 8.0
	var steps: int = ceili(needed_distance / step)
	for i: int in range(steps + 1):
		_position_history.append(position - _move_direction * step * float(i))

func _trim_history() -> void:
	var max_distance: float = maxf(float(_units.size() + 2) * unit_spacing + history_padding, unit_spacing * 4.0)
	var walked: float = 0.0
	var keep_count: int = _position_history.size()
	for i: int in range(_position_history.size() - 1):
		walked += _position_history[i].distance_to(_position_history[i + 1])
		if walked > max_distance:
			keep_count = i + 2
			break
	if keep_count < _position_history.size():
		_position_history.resize(keep_count)

func _get_point_at_path_distance(distance: float) -> Vector2:
	if _position_history.is_empty():
		return global_position
	if distance <= 0.0:
		return _position_history[0]
	var walked: float = 0.0
	for i: int in range(_position_history.size() - 1):
		var a: Vector2 = _position_history[i]
		var b: Vector2 = _position_history[i + 1]
		var segment_length: float = a.distance_to(b)
		if segment_length <= 0.001:
			continue
		if walked + segment_length >= distance:
			var local_t: float = (distance - walked) / segment_length
			return a.lerp(b, local_t)
		walked += segment_length
	return _position_history[_position_history.size() - 1]

func _find_unit_by_key(key: String) -> Node2D:
	for unit: Node2D in _units:
		if is_instance_valid(unit) and unit.has_method("get_unit_key") and unit.get_unit_key() == key:
			return unit
	return null

func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])

func _add_key_action(action: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode: int in keycodes:
		var exists: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey and (event as InputEventKey).keycode == keycode:
				exists = true
				break
		if exists:
			continue
		var key_event: InputEventKey = InputEventKey.new()
		key_event.keycode = keycode
		InputMap.action_add_event(action, key_event)
