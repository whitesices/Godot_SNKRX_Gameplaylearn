## 商店脚本：波次间弹出，展示4个随机单位。
## 根据 GameState.get_unit_tier_weights() 分配星级概率。
class_name Shop
extends Control

const GeneratedTextureLoader := preload("res://scripts/util/GeneratedTexture.gd")
const UNIT_DATA_PATHS: PackedStringArray = [
	"res://resources/unit_data/warrior_paladin.tres",
	"res://resources/unit_data/warrior_berserker.tres",
	"res://resources/unit_data/mage_frost.tres",
	"res://resources/unit_data/mage_pyro.tres",
	"res://resources/unit_data/ranger_shadow.tres",
	"res://resources/unit_data/ranger_sniper.tres",
	"res://resources/unit_data/drifter_dice.tres",
	"res://resources/unit_data/drifter_clover.tres",
	"res://resources/unit_data/engineer_drone.tres",
	"res://resources/unit_data/engineer_demoman.tres",
]

signal unit_bought(unit_data: UnitData)
signal shop_closed

## 所有可用单位数据（在编辑器中赋值）
@export var available_units: Array[UnitData] = []
var snake_manager: SnakeManager = null

@onready var unit_slots: HBoxContainer = $Panel/VBox/UnitSlots
@onready var gold_label: Label = $Panel/VBox/TopBar/GoldLabel
@onready var refresh_btn: Button = $Panel/VBox/BottomBar/RefreshButton
@onready var start_btn: Button = $Panel/VBox/BottomBar/StartButton
@onready var message_label: Label = $Panel/VBox/MessageLabel

var _slot_datas: Array[UnitData] = []

func _ready() -> void:
	# P1修复：自动从资源目录加载所有单位数据，无需在编辑器手动拖拽
	_load_available_units()
	refresh_btn.text = "刷新 (%d金)" % GameState.SHOP_REFRESH_COST
	refresh_btn.pressed.connect(_on_refresh_pressed)
	start_btn.text = "出发！"
	start_btn.pressed.connect(_on_start_pressed)
	EventBus.gold_changed.connect(_update_gold_label)
	_update_gold_label(GameState.gold)
	_roll_shop()

## 从资源目录自动加载所有 UnitData 资源
func _load_available_units() -> void:
	if not available_units.is_empty():
		return  # 已在编辑器赋值则跳过
	for path: String in UNIT_DATA_PATHS:
		_try_add_unit_data(path)
	if not available_units.is_empty():
		return

	const UNIT_DATA_DIR: String = "res://resources/unit_data/"
	var dir: DirAccess = DirAccess.open(UNIT_DATA_DIR)
	if dir == null:
		push_error("Shop: 无法打开 unit_data 目录 %s" % UNIT_DATA_DIR)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			_try_add_unit_data(UNIT_DATA_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	if available_units.is_empty():
		push_warning("Shop: 未找到任何 UnitData 资源，商店将为空")
		_flash_message("商店单位加载失败。")

func _try_add_unit_data(path: String) -> void:
	var res: Resource = ResourceLoader.load(path)
	if res is UnitData and not available_units.has(res as UnitData):
		available_units.append(res as UnitData)

func _roll_shop() -> void:
	_slot_datas.clear()
	# 清空现有槽位
	for child: Node in unit_slots.get_children():
		child.queue_free()

	var weights: Array[float] = GameState.get_unit_tier_weights()
	# 生成4个单位
	for _i: int in range(4):
		var rolled_tier: int = _weighted_random(weights) + 1  # 1-5
		var candidates: Array[UnitData] = available_units.filter(
			func(d: UnitData) -> bool: return d.star_tier == rolled_tier
		)
		if candidates.is_empty() and not available_units.is_empty():
			candidates = available_units  # 后备：任意单位
		if candidates.is_empty():
			continue

		var chosen: UnitData = candidates.pick_random()
		_slot_datas.append(chosen)
		_create_slot_button(chosen)
	if _slot_datas.is_empty():
		_flash_message("没有可展示的职业单位。")

func _create_slot_button(data: UnitData) -> void:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(150, 188)
	btn.text = "%s\n%s\n稀有度 %d\n%d 金" % [
		data.display_name,
		_class_name(data.unit_class),
		data.star_tier,
		data.purchase_cost
	]
	btn.tooltip_text = data.description
	if not data.sprite_path.is_empty():
		var icon_resource: Texture2D = GeneratedTextureLoader.load_texture(data.sprite_path)
		if icon_resource != null:
			btn.icon = icon_resource
			btn.expand_icon = true
	btn.self_modulate = Color(1, 1, 1, 1)
	btn.modulate = data.color.lerp(Color.WHITE, 0.45)
	btn.pressed.connect(func() -> void: _on_unit_slot_pressed(data, btn))
	unit_slots.add_child(btn)

func _on_unit_slot_pressed(data: UnitData, btn: Button) -> void:
	if snake_manager != null and not snake_manager.can_accept_or_upgrade(data):
		_flash_message("蛇队已满；购买已有单位可以升级。")
		return
	if GameState.try_purchase_unit(data.purchase_cost):
		var added: bool = true
		if snake_manager != null:
			added = snake_manager.add_or_upgrade_unit(data)
		if added:
			btn.disabled = true
			btn.text += "\n已招募"
			unit_bought.emit(data)
			EventBus.unit_purchased.emit(data)
			_flash_message("%s 加入/升级成功。" % data.display_name)
		else:
			GameState.gold += data.purchase_cost
			_flash_message("蛇队已满。")
	else:
		_flash_message("金币不足。")

func _on_refresh_pressed() -> void:
	if GameState.try_purchase_refresh():
		_roll_shop()

func _on_start_pressed() -> void:
	shop_closed.emit()
	hide()
	GameState.start_new_wave()

func _update_gold_label(new_gold: int) -> void:
	gold_label.text = "金币 %d" % new_gold

func _weighted_random(weights: Array[float]) -> int:
	var total: float = 0.0
	for w: float in weights:
		total += w
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i: int in range(weights.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return i
	return weights.size() - 1

func _class_name(cls: int) -> String:
	match cls:
		0: return "战士"
		1: return "法师"
		2: return "游侠"
		3: return "流浪者"
		4: return "工程师"
		_: return "???"

func _flash_message(text: String) -> void:
	if message_label == null:
		return
	message_label.text = text
	message_label.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(1.3)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.35)
