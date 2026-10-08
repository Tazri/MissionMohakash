# Mission Mohakash – Main Menu (Godot 4.3+)

Open `project.godot` in **Godot 4.3 or newer** and press **F5**. The first open
imports the assets (a few seconds). The main scene is already set.

## Project structure
```
assets/
  textures/   bg.png, logo.png
  icons/      SVG icons (rocket, help, exit, back, chevron)
  audio/
    music/    menu_theme.wav   (looping ambient track)
    sfx/      hover.wav, click.wav
  fonts/      (optional) put title.ttf / body.ttf here - auto-detected
autoload/     audio_manager.tscn   (AudioStreamPlayer nodes: music, hover, click)
scenes/
  main_menu/  main_menu.tscn       <- main scene
  ui/         menu_button.tscn     <- reusable animated button
  how_to_play/how_to_play.tscn     <- overlay screen
  levels/     level_01.tscn        <- PLACEHOLDER first mission
scripts/
  autoload/   audio_manager.gd, scene_transition.gd
  ui/         menu_button.gd (GameMenuButton), ui_style.gd
  main_menu.gd, how_to_play.gd, level_01.gd
tools/        generate_audio.py    (re-creates the placeholder audio)
docs/         reference_ui.jpeg
```

## How things work
* **Scaling:** base resolution 1920x1080, stretch mode `canvas_items`, aspect `expand`.
  The layout is anchored top-left, the background uses "keep aspect covered", so
  it fills any window shape without stretching.
* **GameMenuButton** (`scenes/ui/menu_button.tscn`): set *Title, Subtitle, Icon Texture,
  Button Style* (Primary / Secondary / Danger) in the Inspector. Hover = slide + scale +
  glow + colour fade; press = squash + flash. Hover sound plays once per hover
  (state-change guard); click sound plays on press.
* **Audio:** `AudioManager` autoload creates `Music` and `SFX` buses at runtime.
  Change levels with `MUSIC_VOLUME_DB` / `SFX_VOLUME_DB` in `audio_manager.gd`.
  Swap sounds by replacing the files or the streams in `autoload/audio_manager.tscn`.
* **START GAME** opens `start_scene` (export on the MainMenu node) -> `level_01.tscn`.
  **HOW TO PLAY** shows an overlay (edit `CONTROLS` / `TIPS` in `how_to_play.gd`).
  **QUIT** fades out and calls `get_tree().quit()` (hidden on web builds).
* Keyboard/gamepad: press Up/Down to focus the buttons, Enter/Space to activate, Esc closes
  How To Play / leaves the level.

## Notes
* Audio is synthesized placeholder material (no licensing concerns) - replace with
  your own music/SFX whenever you like.
* The reference uses a tracked sci-fi font. None was available offline, so system fonts are
  used as a fallback. For an exact match, add **Orbitron** or **Rajdhani Bold** as
  `assets/fonts/title.ttf` (and any text font as `body.ttf`).
