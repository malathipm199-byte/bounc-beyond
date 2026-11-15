# BOUNCE BEYOND (Godot 4 Project)
**Theme:** Bounce Back — *Fall. Learn. Jump. Rise. Win.*

## How to Open & Run
1. Extract this ZIP archive.
2. Open **Godot 4.x** (4.3 or newer recommended).
3. Click **Import** and select `project.godot`.
4. Press **F5** (or click Play) to launch the game!

## Controls
- **Move Left / Right:** `A` / `D` or `Left` / `Right` Arrow keys
- **Jump:** `Space`, `W`, or `Up` Arrow
- **Pause:** `P` or `Esc`

## Project Structure
- `Scenes/main.tscn` — Complete level, platforms, hazards, finish portal, and UI screens (Main Menu, Confirmation, HUD, Pause, Game Over, Victory)
- `Scenes/player.tscn` — `CharacterBody2D` player with smooth camera tracking
- `Scenes/coin.tscn` — Animated collectible coin (`Area2D` + `Polygon2D`)
- `Scripts/main.gd` — Game state machine, scoring rules, session best score, and procedural audio synthesizer
- `Scripts/player.gd` — Movement, gravity, jumping, and bounce-pad impulse
- `Scripts/coin.gd` — Floating bob animation and collection detection
- `Scripts/obstacle.gd` — Moving platforms and patrolling hazard blocks
