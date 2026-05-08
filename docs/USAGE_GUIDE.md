# 使用指南

## 快速开始

项目路径：

```text
C:/ML/TestGame
```

Godot 版本：

```text
Godot 4.6.1
```

推荐启动命令：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --path 'C:/ML/TestGame'
```

也可以打开 Godot 编辑器，导入：

```text
C:/ML/TestGame/project.godot
```

主场景：

```text
res://scenes/main/Main.tscn
```

## 玩家操作

- `WASD` 或方向键：控制蛇首转向
- 商店卡牌：购买英雄
- 已有英雄再次购买：升级该英雄
- `刷新`：花费金币刷新商店
- `出发！`：开始下一波战斗

## 游戏目标

尽量在每波战斗中存活并清掉敌人，用金币在商店扩充队伍。合理购买同职业英雄可以触发羁绊，重复购买同一英雄可以提升等级。

## 基础规则

### 蛇队移动

蛇队不会停止前进。玩家只负责改变蛇首方向，队员会沿蛇首的历史轨迹跟随。

### 自动攻击

每个英雄会自动寻找攻击范围内的敌人，不需要手动瞄准或开火。

### 商店

商店每次展示 4 个英雄。购买不同英雄会加入蛇尾；购买已有英雄会升级该英雄，不占用额外蛇长。

### 羁绊

相同职业英雄达到指定人数后触发羁绊：

- 2 人：银
- 4 人：金
- 6 人：白金

当前职业包括：

- 战士
- 法师
- 游侠
- 流浪者
- 工程师

## 测试项目

运行冒烟测试：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --log-file 'godot_smoke.log' --disable-crash-handler --path 'C:/ML/TestGame' --script 'res://tools/smoke_test.gd'
```

成功时应看到：

```text
Smoke test passed
```

运行主场景无界面检查：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --log-file 'godot_run.log' --disable-crash-handler --path 'C:/ML/TestGame' --quit-after 30
```

检查日志中不应出现：

```text
ERROR
SCRIPT ERROR
WARNING
```

## 重新生成美术资源

本项目的英雄、敌人和背景图由 Godot 脚本生成。重新生成：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --script 'res://tools/generate_assets.gd'
```

随后执行导入：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --import
```

生成位置：

```text
res://assets/generated/
```

## 导出

当前可以导出 PCK：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --export-pack 'Windows Desktop' 'C:/ML/TestGame/Packages/SNKRX-like.pck'
```

如果要导出 Windows `.exe`，需要先在 Godot 中安装 4.6.1 export templates。当前机器缺少模板，因此不能直接刷新可执行文件。

导出模板安装后可运行：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --export-release 'Windows Desktop' 'C:/ML/TestGame/Packages/SNKRX-like.exe'
```

## 常见问题

### Godot 路径不能直接运行

当前机器上：

```text
D:/Godot/Godot_v4.6.1-stable_win64.exe
```

是一个文件夹。真正的 console 可执行文件是：

```text
D:/Godot/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64_console.exe
```

### 旧 EXE 运行失败

`Packages/SNKRX-like.exe` 是旧版本引擎导出的文件。当前 PCK 是 Godot 4.6.1 打包的，旧 EXE 无法加载它。安装 4.6.1 export templates 后重新导出即可。

### 美术显示失败

先执行：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --script 'res://tools/generate_assets.gd'
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --import
```

如果仍有问题，检查 `assets/generated/` 下是否存在 PNG 和 `.import` 文件。
