## HUD脚本：显示金币、波次、HP、羁绊状态图标。
## 纯监听 EventBus，不主动查询状态。
class_name HUD
extends CanvasLayer

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var bond_container: HBoxContainer = $BottomBar/BondContainer
@onready var elite_warning_label: Label = $EliteWarning

## 职业颜色（与 UnitClass 枚举对应）
const CLASS_COLORS: Array[Color] = [
	Color.RED,       # WARRIOR
	Color.CYAN,      # MAGE
	Color.GREEN,     # RANGER
	Color.PURPLE,    # DRIFTER
	Color.ORANGE,    # ENGINEER
]
const CLASS_NAMES: Array[String] = ["战士", "法师", "游侠", "流浪者", "工程师"]

## 羁绊图标节点缓存
var _bond_icons: Dictionary = {}

func _ready() -> void:
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.bond_activated.connect(_on_bond_activated)
	EventBus.bond_deactivated.connect(_on_bond_deactivated)
	EventBus.elite_warning.connect(_on_elite_warning)

	# 初始化5个职业的羁绊图标
	for cls: int in range(5):
		var icon: Label = Label.new()
		icon.text = CLASS_NAMES[cls]
		icon.add_theme_color_override("font_color", CLASS_COLORS[cls])
		icon.modulate.a = 0.3  # 未激活时半透明
		icon.add_theme_font_size_override("font_size", 12)
		bond_container.add_child(icon)
		_bond_icons[cls] = icon

	elite_warning_label.visible = false
	_on_gold_changed(GameState.gold)

func _on_gold_changed(amount: int) -> void:
	gold_label.text = "金币 %d" % amount

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "第 %d 波" % wave_number

func _on_bond_activated(unit_class: int, tier: int) -> void:
	if not _bond_icons.has(unit_class):
		return
	var icon: Label = _bond_icons[unit_class] as Label
	var tier_suffix: String = ["", "·银", "·金", "·白金"][tier]
	icon.text = CLASS_NAMES[unit_class] + tier_suffix
	icon.modulate.a = 1.0
	# 激活动画
	var tween: Tween = create_tween()
	tween.tween_property(icon, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.15)

func _on_bond_deactivated(unit_class: int) -> void:
	if not _bond_icons.has(unit_class):
		return
	var icon: Label = _bond_icons[unit_class] as Label
	icon.text = CLASS_NAMES[unit_class]
	icon.modulate.a = 0.3

## P0修复：精英出场警告
func _on_elite_warning(_spawn_pos: Vector2, delay: float) -> void:
	elite_warning_label.text = "精英敌人即将出现！"
	elite_warning_label.visible = true
	elite_warning_label.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(delay * 0.7)
	tween.tween_property(elite_warning_label, "modulate:a", 0.0, delay * 0.3)
	tween.tween_callback(func() -> void: elite_warning_label.visible = false)
