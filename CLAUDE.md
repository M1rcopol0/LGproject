# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Loup Garou 3.0** (package name: `fluffer`) — A Flutter-based cross-platform implementation of the Werewolf/Loup-Garou party game. The app manages role distribution, night actions, village voting, governance modes, and an achievement/trophy system. The UI and all in-code comments are in **French**.

## Build & Development Commands

```bash
# Run on connected device / emulator
flutter run

# Build APK (Android)
flutter build apk

# Build iOS
flutter build ios

# Analyze code (lint)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Get dependencies
flutter pub get
```

## Architecture

### Global State (`globals.dart`)
The game uses **global mutable variables** for all shared state: player list (`globalPlayers`), turn tracking (`globalTurnNumber`, `isDayTime`), audio settings, governance mode, and achievement flags. There is no state management framework — widgets read/write globals directly.

### Game Flow
1. **LoadingScreen** → **WelcomeScreen** → **LobbyScreen** (player setup, pick & ban roles)
2. **RouletteScreen** (governance mode selection: Maire/Roi/Dictateur)
3. **VillageScreen** (main game loop — day phase with voting)
4. **NightActionsScreen** (night phase — role-by-role actions)
5. **Fin** (game end screen, winner announcement)

Turn transitions are managed by `GameLogic.nextTurn()` in `logic.dart`. The day/night cycle alternates through `VillageScreen` ↔ `NightActionsScreen`.

### Role System
- Roles are categorized into three factions: **village**, **loups** (wolves), **solo**
- `role_distribution_logic.dart` handles random assignment from the pick & ban pool
- `GameLogic.getTeamForRole()` in `logic.dart` maps role names (lowercase strings) to factions
- Night action order is defined in `globals.dart` as `nightActionsOrder`

### Night Action Interfaces (`night_interfaces/`)
Each role has a dedicated interface file (e.g., `voyante_interface.dart`, `chaman_interface.dart`). `role_action_dispatcher.dart` routes the current night action to the correct role handler. Adding a new role requires:
1. Creating a new `*_interface.dart` file
2. Adding it to the dispatcher
3. Adding the role to `globalPickBan` in `globals.dart`
4. Adding a `NightAction` entry to `nightActionsOrder`

### Services (flat in `lib/`)
- `game_save_service.dart` — Save/load game state via SharedPreferences
- `trophy_service.dart` — Achievement unlock checks and persistence (`saved_trophies_v2` key)
- `player_storage.dart` — Player directory (persistent player list across games)
- `backup_service.dart` — Export/import game data as files
- `cloud_service.dart` — Cloud sync
- `storage_service.dart` — Low-level storage utilities

### Achievement System
- `achievement_logic.dart` — Static methods checking 20+ achievement conditions at game events (deaths, votes, phase transitions)
- `models/achievement.dart` — Achievement data model definitions
- `trophy_service.dart` — Persistence and unlock API (`checkAndUnlockImmediate`)
- Achievements are tracked via global flags (e.g., `wolfVotedWolf`, `pantinClutchSave`) reset each game in `resetAllGameData()`

### Player Model (`models/player.dart`)
The `Player` class has 50+ properties tracking role, alive status, votes, special ability states, fan allegiance, travel status, curse timers, and game statistics. Properties are reset per-game in `GameLogic._initializePlayerState()`.

## Key Conventions

- **Role comparison** is always done via `role?.toLowerCase()` against lowercase string literals
- **French-language codebase**: all comments, log messages, UI text, and variable names use French
- **Logging** uses `Talker` framework (`globalTalker`), with `debugPrint` redirected to both Talker and console
- **Audio**: SFX via `playSfx()`, background music via `playMusic()`/`stopMusic()` — both in `globals.dart`
- **Persistence**: All local storage uses `SharedPreferences` with string keys
- **Theme**: Dark mode with orange accent (`Color(0xFF0A0E21)` background, `Color(0xFF1D1E33)` surface)
