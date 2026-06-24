# Project Guidelines

- [x] Verify that the copilot-instructions.md file in the .github directory is created. - done
- [x] Clarify Project Requirements - done
- [x] Scaffold the Project - done
- [x] Customize the Project - done
- [x] Install Required Extensions - none needed
- [x] Compile the Project - done
- [x] Create and Run Task - done
- [x] Launch the Project - done
- [x] Ensure Documentation & Fixes are Complete - done

## Project Overview
This project is a Godot 4.6 combat prototype with a Spine 2.1.27 runtime integration.

## Key Subsystems
- **BattleController.gd**: Orchestrates combat turns, hero/enemy skill executions, action selections, and instantiates animated Spine visual effects.
- **SpinePlayer.gd**: Core custom Spine parser and renderer for skeletal animations using Godot's Sprite2D and Polygon2D nodes.
- **ActionResolver.gd**: Calculates damage, heal, and status effect application.

## Debugging and Running
- Launch the project through Godot 4.6 or VS Code tasks. High-fidelity skill VFX are fully loaded dynamically from corresponding `.skel` and `.atlas` files.
