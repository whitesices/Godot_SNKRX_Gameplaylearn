## Global event bus for cross-scene, decoupled communication.
## Add signals here only for events that genuinely span multiple scenes.
## Lifetime: entire game session.
extends Node

# ─── 蛇形系统 ───────────────────────────────────────────────
## 蛇首死亡，传递下一任首领
signal head_died(next_head: Node2D)
## 蛇成员数量变化（购买/死亡）
signal snake_composition_changed

# ─── 战斗事件 ────────────────────────────────────────────────
## 敌人死亡
signal enemy_died(enemy: Node2D, position: Vector2)
## 单位死亡
signal unit_died(unit: Node2D)
## 击中事件（用于触发打击特效）
signal hit_landed(position: Vector2, is_crit: bool, damage: float)
## 开火事件（用于枪口闪光、弹道残影、近战斩击演出）
signal projectile_fired(origin: Vector2, target_position: Vector2, bullet_type: int)

# ─── 波次系统 ────────────────────────────────────────────────
## 波次开始
signal wave_started(wave_number: int)
## 波次结束，进入商店阶段
signal wave_completed(wave_number: int)
## 精英敌人即将出场（提前1s警告，P0漏洞修复）
signal elite_warning(spawn_position: Vector2, delay: float)

# ─── 经济系统 ────────────────────────────────────────────────
## 金币数量变化
signal gold_changed(new_amount: int)
## 玩家购买了一个单位
signal unit_purchased(unit_data: Resource)

# ─── 羁绊系统 ────────────────────────────────────────────────
## 羁绊等级变化（激活或失效）
signal bond_activated(unit_class: int, tier: int)
signal bond_deactivated(unit_class: int)
