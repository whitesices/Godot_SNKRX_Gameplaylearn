# 核心架构设计 — 类 SNKRX 游戏

> **角色**：游戏架构师
> **版本**：v1.0 | 日期：2026-03-11

---

## 1. 移动机制：蛇形跟随系统

### 核心思路：历史位置队列（Position History Queue）

蛇形跟随最稳定的实现方式是为**首领（Head）**记录一条世界坐标历史轨迹，后续成员从轨迹上按固定弧长间距取点。

```
head_positions: RingBuffer<Vec2>  // 容量 = 成员数 × 间距采样点数

每帧更新逻辑：
1. 首领根据玩家输入移动，新位置 push 入 head_positions
2. 第 N 个跟随者从 head_positions[N * SPACING_SAMPLES] 取目标位置
3. 跟随者当前位置 lerp → 目标位置（系数 ≈ 0.85/帧，可调）
```

### 关键参数

| 参数 | 建议值 | 说明 |
|---|---|---|
| `UNIT_SPACING` | 48–64 px | 单位之间的弧长间距 |
| `SPACING_SAMPLES` | 每px 1个采样点 | 控制轨迹精度 |
| `LERP_FACTOR` | 0.8 | 过小=延迟感，过大=僵硬 |
| `HEAD_SPEED` | 200 px/s | 首领移速 |

### 平滑处理

- **急转弯**：首领转向时轨迹会出现锐角，对历史轨迹做 Catmull-Rom 样条插值，消除折角
- **成员朝向**：每个成员面向其在轨迹上的**切线方向**，而非目标点方向

---

## 2. 解耦设计：移动与战斗完全分离

### 单位基类架构（组件化）

```
Unit (基类)
├── MovementComponent       // 只负责位置同步
│   ├── target_position: Vec2
│   ├── current_position: Vec2
│   └── update(delta) → 插值移动，不触碰战斗状态
│
├── CombatComponent         // 只负责战斗逻辑
│   ├── attack_range: float
│   ├── attack_cooldown: float
│   ├── bullet_type: BulletType (enum)
│   ├── damage: float
│   └── update(delta, enemies[]) → 寻敌、射击，不触碰位置
│
└── StatsComponent          // 共享只读数据
    ├── hp, max_hp
    ├── class: UnitClass (enum)
    └── bonds: List<Bond>
```

### 解耦通信：事件总线

```
// 战斗组件不直接调用移动组件，通过事件通信
CombatComponent.emit("on_kill", { target: enemy })
MovementComponent.listen("on_knockback") → 修改 target_position

// 首领死亡时，第二成员晋升为新首领
EventBus.emit("head_died") → SnakeManager.promote_next()
```

**设计原则**：
- `MovementComponent.update()` 只读取 `target_position`，**不知道**战斗存在
- `CombatComponent.update()` 只读取 `current_position`（只读），**不修改**位置
- 两者通过 `EventBus` 交换信息，可独立单元测试

---

## 3. 性能优化：10单位 × 50敌人场景

### 碰撞检测优化

**方案：空间哈希网格（Spatial Hash Grid）**

```
网格尺寸 = max(攻击范围) × 1.5  // 例如 128 px

每帧：
1. 所有敌人按位置插入哈希网格（O(N)）
2. 每个战斗单位只查询自身所在格子 + 8邻格（O(1)次查询）
3. 对候选敌人做精确圆形碰撞（通常只有 3-8 个候选）

结果：50敌人场景下，从 O(N×M)=500次 降至 ~50次精确检测
```

### AI 寻路优化

**蛇形单位不需要复杂寻路**，只需"最近敌人"：

```
方案A（推荐）：每帧为每个战斗单位取哈希网格最近候选 → O(k)
方案B（敌人AI）：敌人只追踪蛇首领位置，无需 A* 
              → 敌人 steering behavior（seek + separation）即可
```

### 子弹/投射物优化

```
对象池（Object Pool）：预分配 200 个子弹对象
- 避免每帧 new/delete 产生 GC 压力
- 子弹移动用简单 velocity × delta，不做碰撞网格（子弹对象数量不入格）
- 子弹与敌人碰撞：遍历活跃子弹 × 哈希格查询（O(bullets × k)）
```

### 帧预算参考（60 FPS = 16.7ms/帧）

| 系统 | 预算 | 优化后估算 |
|---|---|---|
| 蛇形移动 | 0.5ms | 0.1ms（简单插值） |
| 碰撞检测 | 2ms | 0.3ms（空间哈希） |
| 战斗AI | 1ms | 0.2ms（最近格查询） |
| 子弹更新 | 1ms | 0.5ms（对象池） |
| **合计** | **4.5ms** | **1.1ms** |

---

## 架构图

```
SnakeManager
    │
    ├── head: Unit[MovementComponent + CombatComponent]
    ├── body[1]: Unit[MovementComponent + CombatComponent]
    ├── ...
    └── body[N]: Unit[MovementComponent + CombatComponent]
    
EnemyManager
    └── enemies[]: Enemy[SteeringAI + HP]
    
SpatialHashGrid  ← 两者共享，每帧刷新
BulletPool       ← CombatComponent 取用/归还
EventBus         ← 全局事件通道
```
