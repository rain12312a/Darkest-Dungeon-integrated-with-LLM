# darkdungeon

A Godot 4.6 turn-based RPG battle system with custom Spine 2.1.27 animation runtime, inspired by Darkest Dungeon.

## Features

- ✨ **Turn-based Combat**: Speed-based action queue system
- 🦴 **Spine Animation Runtime**: Custom parser for Spine 2.1.27 skeletal animation (Region, Mesh, SkinnedMesh attachments)
- 🎮 **Dynamic UI**: Runtime-generated skill buttons, HP bars, target selection
- 🎨 **Asymmetric Layout**: Heroes on left, monsters on right with complete symmetry
- ⚙️ **Data-Driven Design**: Configuration via GDScript static classes
- 🎯 **Multiple Skill Types**: Single-target, AoE, heal, buff/debuff

## Quick Start

1. **Open Project**: Launch in Godot 4.6 (Vulkan renderer recommended)
2. **Play**: Press F5 or the Play button to run `scenes/main/Main.tscn`
3. **Explore**: 
   - Start Screen → Team Selection → Battle
   - Select heroes → Click Battle → Watch the fight

## Documentation

- **[PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)** — Detailed system architecture and API reference
- **[TECH_GUIDE.md](TECH_GUIDE.md)** ⭐ — **Complete guide to adding heroes, monsters, UI, and animations**

## Project Structure

```
darkdungeon/
├── characters/              # Hero sprites and animations (Spine format)
│   ├── crusader/           # Hero 1: Crusader
│   ├── highwayman/         # Hero 2: Highwayman
│   └── [new_hero]/         # Add new heroes here
│
├── monsters/               # Monster sprites and animations
│   ├── brigand_cutthroat/  # Monster 1: Cutthroat
│   └── [new_monster]/      # Add new monsters here
│
├── scenes/                 # Godot scene files (.tscn)
│   ├── battle/Battle.tscn  # Main battle scene
│   ├── main/Main.tscn      # Scene manager
│   └── ...
│
├── scripts/                # GDScript code
│   ├── battle/             # Battle system (BattleController, Spine renderer)
│   ├── data/               # Config (HeroConfig, SkillConfig, MonsterConfig)
│   └── core/               # Core (GameState, Database)
│
├── data/                   # JSON data (optional, currently using GDScript configs)
│
└── [documentation files]
    ├── PROJECT_DOCUMENTATION.md
    └── TECH_GUIDE.md
```

## How to Add Content

### Add a New Hero

See [TECH_GUIDE.md → Section 2](TECH_GUIDE.md#2-添加新英雄) for detailed steps:

1. Create `characters/new_hero/anim/` with Spine animation files
2. Add hero template to `HeroConfig.HEROES`
3. Add skills to `SkillConfig.SKILLS`
4. Add animation mapping in `BattleController.gd`

### Add a New Monster

See [TECH_GUIDE.md → Section 3](TECH_GUIDE.md#3-添加新怪物) for detailed steps:

1. Create `monsters/new_monster/anim/` with Spine animation files
2. Add monster template to `MonsterConfig.MONSTERS`
3. Add to encounter list in `MonsterConfig.CURRENT_ENCOUNTER`
4. Add animation mapping in `BattleController.gd`

### Add a New Skill

See [TECH_GUIDE.md → Section 6](TECH_GUIDE.md#6-技能系统与按钮绑定) for detailed steps:

1. Define skill in `SkillConfig.SKILLS`
2. Assign to hero's skills array in `HeroConfig.HEROES`
3. Prepare skill icon: `characters/{hero_id}/{hero_id}.ability.{number}.png`

## Technology

| Component | Details |
|-----------|---------|
| **Engine** | Godot 4.6 |
| **Language** | GDScript |
| **Rendering** | Vulkan Forward+ |
| **Animation** | Custom Spine 2.1.27 runtime |
| **UI System** | Dynamic GDScript-generated nodes |

## Key Systems

### Battle Flow

```
Round Start → Build Turn Queue (by speed) → 
  Hero Turn → Select Skill → Select Target → Execute Damage/Heal →
  Monster Turn → Auto Attack →
Back to Round Start (or Victory/Defeat)
```

### Data Configuration

- **HeroConfig.gd** — Hero stats, skills, capabilities
- **MonsterConfig.gd** — Monster templates, encounter setup
- **SkillConfig.gd** — Skill definitions and effects

### Spine Animation System

- **SpineAtlas.gd** — Parse `.atlas` texture regions
- **SpineSkel.gd** — Parse `.skel` binary bones, slots, attachments, animations
- **SpinePlayer.gd** — Render as Sprite2D/Polygon2D hierarchy

## Notes

- Uses placeholder Darkest Dungeon assets for demonstration
- Custom Spine runtime does **not** require the official Spine Godot plugin
- All UI is dynamically generated at runtime (no manual scene construction needed)
- Performance optimized: caching, minimal state updates

## Getting Help

Refer to [TECH_GUIDE.md](TECH_GUIDE.md) for:
- Troubleshooting (Section 7)
- Common errors and fixes
- Quick reference checklists
- File location guide
