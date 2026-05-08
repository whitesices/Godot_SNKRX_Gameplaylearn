## 单位静态数据资源（ScriptableObject 等价物）
## 在编辑器中右键 > New Resource > UnitData 来创建实例。
class_name UnitData
extends Resource

## 职业枚举（与 BondSystem 保持一致）
enum UnitClass {
	WARRIOR  = 0,
	MAGE     = 1,
	RANGER   = 2,
	DRIFTER  = 3,
	ENGINEER = 4
}

## 攻击类型枚举
enum BulletType {
	MELEE_SWING,      # 近战扇形斩击
	MELEE_AOE,        # 近战范围
	PROJECTILE,       # 直线投射物
	PROJECTILE_AOE,   # 爆炸投射物
	BOMB,             # 定时炸弹
	DRONE,            # 召唤无人机
	RANDOM            # 随机（流浪者）
}

@export_group("基础信息")
@export var key: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var unit_class: UnitClass = UnitClass.WARRIOR
@export var star_tier: int = 1  # 1-5星
@export var color: Color = Color.WHITE
@export_file("*.png") var sprite_path: String = ""

@export_group("战斗属性")
@export var max_hp: float = 100.0
@export var damage: float = 20.0
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 1.0  # 秒
@export var bullet_type: BulletType = BulletType.PROJECTILE
@export var bullet_speed: float = 300.0
@export var bullet_pierce: int = 1  # 穿透目标数

@export_group("特殊属性")
@export var special_chance: float = 0.15  # 特殊效果触发概率
@export var special_duration: float = 2.0
@export var lifesteal_ratio: float = 0.0  # 吸血比例（战士金羁绊用）

@export_group("商店")
@export var purchase_cost: int = 3
@export var upgrade_damage_scale: float = 1.35
@export var upgrade_hp_scale: float = 1.25
@export var upgrade_cooldown_scale: float = 0.90

func get_bond_class() -> int:
	return unit_class

func get_key() -> String:
	if not key.is_empty():
		return key
	return display_name
