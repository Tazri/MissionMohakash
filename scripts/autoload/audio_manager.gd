extends Node
## Autoload "AudioManager" (scene: autoload/audio_manager.tscn).
## Owns the music + UI sound players so audio keeps playing across scenes.
##
## Usage:
##   AudioManager.play_music()      AudioManager.fade_out_music(1.0)
##   AudioManager.play_hover()      AudioManager.play_click()
##
## Volumes are set in dB on the players inside audio_manager.tscn, or per bus
## via the constants below. (0 dB = full volume, -6 dB = about half.)

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const MUSIC_VOLUME_DB := -10.0   # background music level
const SFX_VOLUME_DB := -5.0      # hover / click level
const PITCH_JITTER := 0.04       # tiny random pitch so repeated sounds feel alive

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var hover_player: AudioStreamPlayer = $HoverPlayer
@onready var click_player: AudioStreamPlayer = $ClickPlayer

var _music_tween: Tween


func _ready() -> void:
	_ensure_bus(MUSIC_BUS, MUSIC_VOLUME_DB)
	_ensure_bus(SFX_BUS, SFX_VOLUME_DB)
	music_player.bus = MUSIC_BUS
	hover_player.bus = SFX_BUS
	click_player.bus = SFX_BUS
	_make_music_loop()


func _ensure_bus(bus_name: String, volume_db: float) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_volume_db(idx, volume_db)
	AudioServer.set_bus_send(idx, "Master")


## Makes sure a .wav music stream loops (ogg/mp3 use their own "loop" import flag).
func _make_music_loop() -> void:
	var s := music_player.stream
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
	elif s is AudioStreamOggVorbis or s is AudioStreamMP3:
		s.loop = true


func play_music(fade_time := 2.0) -> void:
	if _music_tween:
		_music_tween.kill()
	if music_player.playing:
		# Already playing (e.g. coming back from a level): just fade back up.
		_music_tween = create_tween()
		_music_tween.tween_property(music_player, "volume_db", 0.0, fade_time * 0.5)
		return
	music_player.volume_db = -40.0
	music_player.play()
	_music_tween = create_tween()
	_music_tween.tween_property(music_player, "volume_db", 0.0, fade_time)


func fade_out_music(fade_time := 1.0) -> void:
	if not music_player.playing:
		return
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(music_player, "volume_db", -40.0, fade_time)
	_music_tween.tween_callback(music_player.stop)


func play_hover() -> void:
	_play_sfx(hover_player)


func play_click() -> void:
	_play_sfx(click_player)


func _play_sfx(player: AudioStreamPlayer) -> void:
	player.pitch_scale = 1.0 + randf_range(-PITCH_JITTER, PITCH_JITTER)
	player.play()
