extends Node
## Som procedural — gera PCM 16-bit mono em tempo de execução, sem arquivos externos.

const SR     := 22050   # sample rate SFX
const SR_MUS := 11025   # sample rate música (mais leve de gerar)

var volume_sfx    : float = 1.0    # linear 0.0–1.0
var volume_musica : float = 0.55   # linear 0.0–1.0

const MUSICA_MENU_PATHS := [
	"res://assets/musica/cyron_menu_01.mp3",
	"res://assets/musica/cyron_menu_02.mp3",
	"res://assets/musica/cyron_menu_03.mp3",
	"res://assets/musica/cyron_menu_04.mp3",
]
const MUSICA_PARTIDA_PATHS := [
	"res://assets/musica/cyron_game_01_stars_alive.mp3",
	"res://assets/musica/cyron_game_02_lives.mp3",
	"res://assets/musica/cyron_game_03_lives_alt.mp3",
	"res://assets/musica/cyron_game_04_through_skies.mp3",
	"res://assets/musica/cyron_game_05_through_skies_alt.mp3",
	"res://assets/musica/cyron_game_06_rising.mp3",
	"res://assets/musica/cyron_game_07_drop_c.mp3",
	"res://assets/musica/cyron_game_08_drop_c_alt.mp3",
	"res://assets/musica/cyron_game_09_concrete_thunder.mp3",
	"res://assets/musica/cyron_game_10_gravity_racket.mp3",
	"res://assets/musica/cyron_game_11_constellations.mp3",
	"res://assets/musica/cyron_game_12_constellations_alt.mp3",
	"res://assets/musica/cyron_game_13_completa.mp3",
	"res://assets/musica/cyron_game_14_defense_completa.mp3",
]
const MUSICA_PARTIDA_FALLBACK_PATH := "res://assets/musica/cyron_drop_c_partida.mp3"
const MUSICA_MENU_FALLBACK_PATH := "res://assets/musica/menu_defense.mp3"

var _pool  : Array[AudioStreamPlayer] = []
var _musica_player  : AudioStreamPlayer = null
var _musica_atual   : String = ""    # "menu" | "jogo" | ""
var _menu_playlist : Array[AudioStream] = []
var _menu_playlist_index : int = 0
var _jogo_playlist : Array[AudioStream] = []
var _jogo_playlist_index : int = 0
var _musica_fade_tween : Tween = null
var _musica_fadein_tween : Tween = null
var _musica_op_id : int = 0

# Streams pré-gerados (gerados lazy na primeira chamada)
var _stream_menu    : AudioStream = null
var _stream_jogo    : AudioStream = null
var _stream_boss    : AudioStream = null
var _stream_batalha : AudioStream = null
var _stream_abismo  : AudioStream = null
var _bau_inicio_cache : Dictionary = {}
var _bau_final_cache : Dictionary = {}
var _bau_carta_cache : Dictionary = {}
var _bau_celestial_cache : AudioStreamWAV = null
var _sfx_tiro_cache : AudioStreamWAV = null
var _sfx_impacto_cache : AudioStreamWAV = null
var _sfx_critico_cache : AudioStreamWAV = null
var _sfx_veneno_cache : AudioStreamWAV = null
var _sfx_morte_cache : AudioStreamWAV = null
var _sfx_last_ms : Dictionary = {}


func _ready() -> void:
	for i in range(12):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	# Player dedicado à música (loop)
	_musica_player            = AudioStreamPlayer.new()
	_musica_player.bus        = "Master"
	add_child(_musica_player)
	if not _musica_player.finished.is_connected(_on_musica_finished):
		_musica_player.finished.connect(_on_musica_finished)
	# Sincroniza volume inicial com a config salva
	volume_sfx    = Salvar.volume_sfx
	volume_musica = Salvar.volume_musica
	# Gera as trilhas em deferred para não travar o primeiro frame
	call_deferred("_gerar_trilhas")


func _gerar_trilhas() -> void:
	# Menu/loja/inventário/talentos: MP3 feito pelo time
	_carregar_playlist_menu()
	if _musica_atual == "menu" and _musica_player and not _musica_player.playing:
		_tocar_musica_stream(_stream_menu)
	# Jogo: gerado agora (mais usado, vale pré-aquecer)
	_carregar_playlist_jogo()
	if _stream_jogo == null:
		_stream_jogo = _gerar_musica_jogo()
	# Boss, Batalha, Abismo: lazy (gerado na primeira chamada)


# ── Controle de música ────────────────────────────────────────────────────────

func _carregar_mp3_menu(path: String, loop: bool = true) -> AudioStream:
	var res := load(path)
	if res is AudioStreamMP3:
		(res as AudioStreamMP3).loop = loop
	if res is AudioStream:
		return res as AudioStream
	return null


func _carregar_playlist_menu() -> void:
	_menu_playlist.clear()
	for path in MUSICA_MENU_PATHS:
		var faixa_menu := _carregar_mp3_menu(str(path), false)
		if faixa_menu != null:
			_menu_playlist.append(faixa_menu)
	if _menu_playlist.is_empty():
		var fallback := _carregar_mp3_menu(MUSICA_MENU_FALLBACK_PATH, false)
		if fallback != null:
			_menu_playlist.append(fallback)
	_menu_playlist_index = clampi(_menu_playlist_index, 0, maxi(0, _menu_playlist.size() - 1))
	_stream_menu = _menu_playlist[_menu_playlist_index] if not _menu_playlist.is_empty() else null


func _carregar_playlist_jogo() -> void:
	_jogo_playlist.clear()
	for path in MUSICA_PARTIDA_PATHS:
		var faixa_jogo := _carregar_mp3_menu(str(path), false)
		if faixa_jogo != null:
			_jogo_playlist.append(faixa_jogo)
	if _jogo_playlist.is_empty():
		var fallback := _carregar_mp3_menu(MUSICA_PARTIDA_FALLBACK_PATH, false)
		if fallback != null:
			_jogo_playlist.append(fallback)
	_jogo_playlist_index = clampi(_jogo_playlist_index, 0, maxi(0, _jogo_playlist.size() - 1))
	_stream_jogo = _jogo_playlist[_jogo_playlist_index] if not _jogo_playlist.is_empty() else null


func tocar_musica_menu(force: bool = false) -> void:
	if not force and _musica_atual == "menu" and _musica_player and _musica_player.playing and _stream_esta_na_playlist(_musica_player.stream, _menu_playlist):
		return
	_musica_atual = "menu"
	_menu_playlist_index = 0
	if _stream_menu == null or _menu_playlist.is_empty():
		_carregar_playlist_menu()
	var faixa := _stream_menu
	if not _menu_playlist.is_empty():
		faixa = _menu_playlist[_menu_playlist_index]
	_tocar_musica_stream(faixa)


func garantir_musica_menu() -> void:
	if _musica_player == null:
		return
	_musica_atual = "menu"
	if _stream_menu == null or _menu_playlist.is_empty():
		_carregar_playlist_menu()
	if _stream_menu == null:
		return
	if _musica_player.playing and _stream_esta_na_playlist(_musica_player.stream, _menu_playlist):
		return
	_tocar_musica_stream(_stream_menu)


func _on_musica_finished() -> void:
	if _musica_atual == "menu" and not _menu_playlist.is_empty():
		_menu_playlist_index = (_menu_playlist_index + 1) % _menu_playlist.size()
		_stream_menu = _menu_playlist[_menu_playlist_index]
		_tocar_musica_stream(_stream_menu)
	elif _musica_atual == "jogo" and not _jogo_playlist.is_empty():
		_jogo_playlist_index = (_jogo_playlist_index + 1) % _jogo_playlist.size()
		_stream_jogo = _jogo_playlist[_jogo_playlist_index]
		_tocar_musica_stream(_stream_jogo)


func tocar_musica_jogo() -> void:
	if _musica_atual == "jogo": return
	_musica_atual = "jogo"
	if _stream_jogo == null or _jogo_playlist.is_empty():
		_carregar_playlist_jogo()
		if _stream_jogo == null:
			_stream_jogo = _gerar_musica_jogo()
	_tocar_musica_stream(_stream_jogo)


func tocar_musica_boss() -> void:
	if _musica_atual == "boss": return
	_musica_atual = "boss"
	if _stream_boss == null: _stream_boss = _gerar_musica_boss()
	_tocar_musica_stream(_stream_boss)


func tocar_musica_batalha() -> void:
	if _musica_atual == "batalha": return
	_musica_atual = "batalha"
	if _stream_batalha == null: _stream_batalha = _gerar_musica_batalha()
	_tocar_musica_stream(_stream_batalha)


func tocar_musica_abismo() -> void:
	if _musica_atual == "abismo": return
	_musica_atual = "abismo"
	if _stream_abismo == null: _stream_abismo = _gerar_musica_abismo()
	_tocar_musica_stream(_stream_abismo)


func parar_musica() -> void:
	_musica_op_id += 1
	var op_id : int = _musica_op_id
	_musica_atual = ""
	if _musica_player:
		_cancelar_tweens_musica()
		_musica_fade_tween = create_tween()
		_musica_fade_tween.tween_property(_musica_player, "volume_db",
			linear_to_db(0.001), 1.2)
		_musica_fade_tween.tween_callback(func() -> void:
			if op_id == _musica_op_id and _musica_atual == "" and _musica_player:
				_musica_player.stop()
		)


func set_volume_musica(v: float) -> void:
	volume_musica = clampf(v, 0.0, 1.0)
	Salvar.volume_musica = volume_musica
	if _musica_player and _musica_player.playing:
		_musica_player.volume_db = _db_musica()


func _tocar_musica_stream(stream: AudioStream) -> void:
	if not _musica_player or stream == null: return
	_musica_op_id += 1
	var op_id : int = _musica_op_id
	_cancelar_tweens_musica()
	# Fade-out suave se estava tocando outra coisa
	if _musica_player.playing:
		_musica_fade_tween = create_tween()
		_musica_fade_tween.tween_property(_musica_player, "volume_db", linear_to_db(0.001), 0.8)
		_musica_fade_tween.tween_callback(func() -> void:
			if op_id != _musica_op_id or not _musica_player:
				return
			_musica_player.stream    = stream
			_musica_player.volume_db = linear_to_db(0.001)
			_musica_player.play()
			_musica_fadein_tween = create_tween()
			_musica_fadein_tween.tween_property(_musica_player, "volume_db", _db_musica(), 1.5))
	else:
		_musica_player.stream    = stream
		_musica_player.volume_db = linear_to_db(0.001)
		_musica_player.play()
		_musica_fadein_tween = create_tween()
		_musica_fadein_tween.tween_property(_musica_player, "volume_db", _db_musica(), 2.0)


func _db_musica() -> float:
	return linear_to_db(clampf(volume_musica, 0.001, 1.0)) - 6.0


func _cancelar_tweens_musica() -> void:
	if _musica_fade_tween != null and is_instance_valid(_musica_fade_tween):
		_musica_fade_tween.kill()
	if _musica_fadein_tween != null and is_instance_valid(_musica_fadein_tween):
		_musica_fadein_tween.kill()
	_musica_fade_tween = null
	_musica_fadein_tween = null


func _stream_esta_na_playlist(stream: AudioStream, playlist: Array[AudioStream]) -> bool:
	if stream == null:
		return false
	for faixa in playlist:
		if faixa == stream:
			return true
	return false


# ── Gerador de música dark ambient ────────────────────────────────────────────
# Loop simples: fundamental + quinta + oitava com swell suave.
func _gerar_dark_drone(dur_loop: float, fundamental: float, vol_master: float) -> AudioStreamWAV:
	var n   : int            = int(SR_MUS * dur_loop)
	var buf : PackedByteArray = PackedByteArray()
	buf.resize(n * 2)

	for i in range(n):
		var t  : float = float(i) / float(SR_MUS)
		# Swell: 1 ciclo exato dentro do loop → transição perfeita
		var sw : float = 0.55 + 0.45 * sin(t * TAU / dur_loop - TAU * 0.25)
		var s  : float = 0.0
		s += sin(t * TAU * fundamental)        * 0.42   # base
		s += sin(t * TAU * fundamental * 1.5)  * 0.22   # quinta (harmonia)
		s += sin(t * TAU * fundamental * 2.0)  * 0.14   # oitava (brilho leve)
		s += sin(t * TAU * fundamental * 0.5)  * 0.20   # sub-bass (peso)
		s  = clampf(s * sw * vol_master, -1.0, 1.0)
		var v : int = int(s * 29000.0)
		buf[i * 2]     = v & 0xFF
		buf[i * 2 + 1] = (v >> 8) & 0xFF

	var stream       := AudioStreamWAV.new()
	stream.format     = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo     = false
	stream.mix_rate   = SR_MUS
	stream.loop_mode  = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end   = n
	stream.data       = buf
	return stream


# ── Helpers de geração de música ─────────────────────────────────────────────

func _brass_s(t: float, f: float) -> float:
	return (sin(t * TAU * f)       * 0.50
		  + sin(t * TAU * f * 2.0) * 0.28
		  + sin(t * TAU * f * 3.0) * 0.14
		  + sin(t * TAU * f * 4.0) * 0.07
		  + sin(t * TAU * f * 5.0) * 0.03)


func _reverb_pass(raw: PackedFloat32Array, revs: Array) -> void:
	var n := raw.size()
	for rv in revs:
		var d : int   = rv[0]
		var g : float = rv[1]
		for i in range(d, n):
			raw[i] += raw[i - d] * g


func _raw_to_wav_loop(raw: PackedFloat32Array) -> AudioStreamWAV:
	var n   := raw.size()
	var buf := PackedByteArray(); buf.resize(n * 2)
	for i in range(n):
		var v := int(clampf(raw[i], -1.0, 1.0) * 29000.0)
		buf[i * 2]     = v & 0xFF
		buf[i * 2 + 1] = (v >> 8) & 0xFF
	var st           := AudioStreamWAV.new()
	st.format         = AudioStreamWAV.FORMAT_16_BITS
	st.stereo         = false
	st.mix_rate       = SR_MUS
	st.loop_mode      = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin     = 0
	st.loop_end       = n
	st.data           = buf
	return st


# ── Geradores de trilhas ──────────────────────────────────────────────────────

# JOGO — Substrato (Lo-fi dark synth, Dm, 80 BPM, 12s)
func _gerar_musica_jogo() -> AudioStreamWAV:
	var dur    := 12.0;  var beat := 0.75;  var half_b := 0.375
	var n      := int(SR_MUS * dur)
	var bass_n : Array[float] = [73.42, 87.31, 110.0, 130.81, 110.0, 87.31, 98.0, 87.31]
	var raw    := PackedFloat32Array(); raw.resize(n)
	for i in range(n):
		var t    := float(i) / float(SR_MUS)
		var s    := 0.0
		var kt   := fmod(t, beat * 2.0)
		var kenv := exp(-kt * 22.0) * (1.0 - exp(-kt * 90.0))
		s += sin(t * TAU * maxf(28.0, 72.0 - kt * 48.0)) * kenv * 0.40
		var bidx : int   = int(t / half_b) % 8
		var nt_b : float = fmod(t, half_b)
		var benv : float = minf(nt_b * 55.0, 1.0) * exp(-nt_b * 4.8)
		var bf   : float = bass_n[bidx]
		s += (sin(t * TAU * bf) * 0.72 + sin(t * TAU * bf * 2.0) * 0.20) * benv * 0.52
		s += sin(t * TAU * bf * 0.5) * benv * 0.12
		var plfo := 0.55 + 0.45 * sin(t * TAU / dur - TAU * 0.25)
		s += sin(t * TAU * 146.83) * 0.12 * plfo
		s += sin(t * TAU * 174.61) * 0.09 * plfo
		s += sin(t * TAU * 220.00) * 0.07 * plfo
		s += sin(t * TAU * 261.63) * 0.05 * plfo
		s  = lerpf(s, roundf(s * 40.0) / 40.0, 0.28)          # bit crush
		s += sin(t * TAU * 7350.0) * sin(t * TAU * 5670.0) * 0.011 * plfo
		raw[i] = s * 0.82 * minf(minf(float(i) / 220.0, 1.0), float(n - i) / 220.0)
	return _raw_to_wav_loop(raw)


# BOSS — Condenação (Brass + coral escuro, Dm, 100 BPM, 12s)
func _gerar_musica_boss() -> AudioStreamWAV:
	var dur  := 12.0;  var beat := 0.6
	var n    := int(SR_MUS * dur)
	var bass_n : Array[float] = [73.42, 87.31, 110.0, 87.31]
	var cv   : Array[float] = [73.33, 73.51, 87.18, 87.44, 109.78, 110.22]
	var wo   : Array[float] = [0.72, 0.28, 0.14, 0.08, 0.05]
	var raw  := PackedFloat32Array(); raw.resize(n)
	for i in range(n):
		var t    := float(i) / float(SR_MUS)
		var s    := 0.0
		var kt   := fmod(t, beat)
		var kenv := exp(-kt * 25.0) * (1.0 - exp(-kt * 80.0))
		s += sin(t * TAU * maxf(30.0, 80.0 - kt * 65.0)) * kenv * 0.50
		var mt   := fmod(t, beat * 2.0)
		var menv := exp(-mt * 18.0) * (1.0 - exp(-mt * 55.0))
		s += _brass_s(t, 73.42) * menv * 0.55
		s += _brass_s(t, 110.0) * menv * 0.30
		var bidx : int   = int(t / beat) % 4
		var nt_b : float = fmod(t, beat)
		var benv : float = minf(nt_b * 50.0, 1.0) * exp(-nt_b * 4.0)
		s += _brass_s(t, bass_n[bidx]) * benv * 0.50
		s += _brass_s(t, 146.83) * 0.10
		s += _brass_s(t, 174.61) * 0.08
		s += _brass_s(t, 220.0)  * 0.06
		for vi in range(6):
			var vf := cv[vi]; var v := 0.0
			for k in range(5): v += sin(t * TAU * vf * float(k + 1)) * wo[k]
			s += v * 0.022
		s += _brass_s(t, 110.0 * 1.414) * menv * 0.04
		raw[i] = s * 0.72 * minf(minf(float(i) / 220.0, 1.0), float(n - i) / 220.0)
	_reverb_pass(raw, [[int(0.30 * SR_MUS), 0.15], [int(0.60 * SR_MUS), 0.08]])
	return _raw_to_wav_loop(raw)


# BATALHA — Vanguarda (Brass + coral heróico, Am, 90 BPM, 12s)
func _gerar_musica_batalha() -> AudioStreamWAV:
	var dur  := 12.0;  var beat := 2.0 / 3.0
	var n    := int(SR_MUS * dur)
	var bass_n : Array[float] = [110.0, 130.81, 164.81, 196.0, 164.81, 130.81]
	var cv   : Array[float] = [109.56, 110.44, 130.42, 131.20, 164.48, 165.14]
	var wo   : Array[float] = [0.72, 0.22, 0.12, 0.06, 0.03]
	var raw  := PackedFloat32Array(); raw.resize(n)
	for i in range(n):
		var t    := float(i) / float(SR_MUS)
		var s    := 0.0
		var kt   := fmod(t, beat * 2.0)
		var kenv := exp(-kt * 22.0) * (1.0 - exp(-kt * 70.0))
		s += sin(t * TAU * maxf(28.0, 76.0 - kt * 50.0)) * kenv * 0.46
		var st2  := kt - beat
		if st2 >= 0.0:
			s += (_brass_s(t, 200.0) * 0.28 + sin(t * TAU * 7200.0) * 0.08) * exp(-st2 * 26.0) * 0.22
		var bidx : int   = int(t / beat) % 6
		var nt_b : float = fmod(t, beat)
		var benv : float = minf(nt_b * 48.0, 1.0) * exp(-nt_b * 3.8)
		s += _brass_s(t, bass_n[bidx]) * benv * 0.48
		s += _brass_s(t, 110.0)  * 0.12
		s += _brass_s(t, 130.81) * 0.09
		s += _brass_s(t, 164.81) * 0.07
		s += _brass_s(t, 220.0)  * 0.05
		var mt   := fmod(t, beat * 4.0)
		var menv := maxf(0.0, exp(-mt * 2.0) - exp(-mt * 10.0))
		s += _brass_s(t, 392.0) * menv * 0.22
		s += _brass_s(t, 330.0) * menv * 0.12
		var csw := 0.65 + 0.35 * sin(t * TAU / dur - TAU * 0.25)
		for vi in range(6):
			var vf := cv[vi]; var v := 0.0
			for k in range(5): v += sin(t * TAU * vf * float(k + 1)) * wo[k]
			s += v * 0.030 * csw
		raw[i] = s * 0.74 * minf(minf(float(i) / 330.0, 1.0), float(n - i) / 330.0)
	_reverb_pass(raw, [[int(0.40 * SR_MUS), 0.18], [int(0.80 * SR_MUS), 0.10], [int(1.35 * SR_MUS), 0.05]])
	return _raw_to_wav_loop(raw)


# ABISMO — Vazio (Drones inarmônicos, F#m, 20s)
func _gerar_musica_abismo() -> AudioStreamWAV:
	var dur  := 20.0
	var n    := int(SR_MUS * dur)
	var coral : Array = [
		[92.50,  0.0,  10.0], [82.41,  7.5, 16.5],
		[77.78, 14.0,  20.0], [92.50, 17.5, 20.0],
	]
	var cv   : Array[float] = [92.22, 92.78, 82.18, 82.64, 77.58, 77.98]
	var wo   : Array[float] = [0.85, 0.20, 0.10, 0.06, 0.04]
	var raw  := PackedFloat32Array(); raw.resize(n)
	for i in range(n):
		var t := float(i) / float(SR_MUS)
		var s := 0.0
		s += sin(t * TAU * 46.25)  * 0.30
		s += sin(t * TAU * 34.65)  * 0.18
		s += sin(t * TAU * 92.50)  * 0.14
		s += sin(t * TAU * 138.59) * 0.09
		s += sin(t * TAU * 92.50)  * 0.08
		s += sin(t * TAU * 97.99)  * 0.07
		s += sin(t * TAU * 185.00) * 0.05
		s += sin(t * TAU * 193.77) * 0.04
		s += sin(t * TAU * 110.00) * 0.06
		s += sin(t * TAU * 116.54) * 0.04
		for cn in coral:
			var cf  : float = float(cn[0])
			var ct0 : float = float(cn[1])
			var ct1 : float = float(cn[2])
			if t < ct0 or t > ct1: continue
			var nt  : float = (t - ct0) / (ct1 - ct0)
			var a   : float = clampf(nt / 0.12, 0.0, 1.0); a = a * a * (3.0 - 2.0 * a)
			var r   : float = clampf((1.0 - nt) / 0.12, 0.0, 1.0); r = r * r * (3.0 - 2.0 * r)
			for vi in range(6):
				var vf := cv[vi]; var v := 0.0
				for k in range(5): v += sin(t * TAU * vf * float(k + 1)) * wo[k]
				s += v * 0.038 * a * r
		s += sin(t * TAU * 740.0) * 0.007
		s += sin(t * TAU * 622.0) * 0.005
		raw[i] = s * 0.70 * minf(minf(float(i) / 441.0, 1.0), float(n - i) / 441.0)
	_reverb_pass(raw, [[int(0.75 * SR_MUS), 0.28], [int(1.40 * SR_MUS), 0.18],
					   [int(2.20 * SR_MUS), 0.10], [int(3.10 * SR_MUS), 0.05]])
	return _raw_to_wav_loop(raw)


# ── API pública ───────────────────────────────────────────────────────────────

func tiro() -> void:
	if not _sfx_interval_ok("tiro", 42):
		return
	if _sfx_tiro_cache == null:
		_sfx_tiro_cache = _wav(func(t: float, dur: float) -> float:
			var n : float = t / maxf(dur, 0.001)
			var env : float = exp(-t * 34.0) * clampf((1.0 - n) * 1.6, 0.0, 1.0)
			var freq : float = lerpf(520.0, 250.0, n)
			var corpo : float = sin(t * TAU * freq) * 0.34 + sin(t * TAU * (freq * 1.74)) * 0.10
			var ar : float = randf_range(-1.0, 1.0) * exp(-t * 70.0) * 0.16
			return (corpo + ar) * env
		, 0.075)
	_tocar(_sfx_tiro_cache, -13.0)


func impacto() -> void:
	if not _sfx_interval_ok("impacto", 24):
		return
	if _sfx_impacto_cache == null:
		_sfx_impacto_cache = _wav(func(t: float, _d: float) -> float:
			var env : float = exp(-t * 45.0)
			return (sin(t * TAU * 240.0) * 0.5 + randf_range(-0.25, 0.25)) * env
		, 0.07)
	_tocar(_sfx_impacto_cache, -11.0)


func morte_mob() -> void:
	if not _sfx_interval_ok("morte", 46):
		return
	if _sfx_morte_cache == null:
		_sfx_morte_cache = _wav(func(t: float, _d: float) -> float:
			var env  : float = exp(-t * 12.0)
			var freq : float = max(520.0 - t * 1500.0, 70.0)
			return sin(t * TAU * freq) * env * 0.45
		, 0.18)
	_tocar(_sfx_morte_cache, -10.0)


func dano_torre() -> void:
	_tocar(_wav(func(t: float, _d: float) -> float:
		var env : float = exp(-t * 16.0)
		return (sin(t * TAU * 140.0) + sin(t * TAU * 210.0) * 0.4) * env * 0.8
	, 0.18), -4.0)


func upgrade() -> void:
	_tocar(_wav(func(t: float, dur: float) -> float:
		var freqs : Array = [523.0, 659.0, 784.0, 1047.0]
		var idx   : int   = int(t / dur * 4.0)
		var freq  : float = freqs[min(idx, 3)] as float
		var env   : float = sin(t / dur * PI)
		return sin(t * TAU * freq) * env * 0.6
	, 0.45), -5.0)


func wave_inicio() -> void:
	_tocar(_wav(func(t: float, dur: float) -> float:
		var freq : float = 180.0 + (t / dur) * 520.0
		var env  : float = sin(t / dur * PI) * 0.5
		return (sin(t * TAU * freq) + sin(t * TAU * freq * 1.5) * 0.3) * env
	, 0.55), -6.0)


func bau_abertura_inicio(tier: String) -> void:
	var k := _bau_tier_ok(tier)
	_tocar(_bau_inicio_stream(k), -4.0)


func bau_carta_revelar(tipo: String = "") -> void:
	_tocar(_bau_carta_stream(tipo), -5.0)


func bau_abertura_final(tier: String) -> void:
	var k := _bau_tier_ok(tier)
	_tocar(_bau_final_stream(k), -3.0)


func bau_celestial() -> void:
	if _bau_celestial_cache == null:
		_bau_celestial_cache = _gerar_bau_celestial()
	_tocar(_bau_celestial_cache, -2.0)


func critico() -> void:
	if not _sfx_interval_ok("critico", 55):
		return
	if _sfx_critico_cache == null:
		_sfx_critico_cache = _wav(func(t: float, _d: float) -> float:
			var env : float = exp(-t * 14.0)
			return (sin(t * TAU * 760.0) + sin(t * TAU * 1140.0) * 0.35) * env * 0.55
		, 0.14)
	_tocar(_sfx_critico_cache, -5.0)


func veneno_impacto() -> void:
	if not _sfx_interval_ok("veneno", 38):
		return
	if _sfx_veneno_cache == null:
		_sfx_veneno_cache = _wav(func(t: float, _d: float) -> float:
			var env : float = exp(-t * 38.0)
			return sin(t * TAU * 195.0) * env * 0.34
		, 0.07)
	_tocar(_sfx_veneno_cache, -12.0)


func explosao_forte() -> void:
	_tocar(_wav(func(t: float, _d: float) -> float:
		var env   : float = exp(-t * 7.0)
		var noise : float = randf_range(-1.0, 1.0) * 0.55
		return (sin(t * TAU * maxf(30.0, 75.0 - t * 130.0)) + noise) * env * 0.88
	, 0.50), -3.0)


func talento_ramo() -> void:
	# Arpejo ascendente curto — "poder desbloqueado"
	_tocar(_wav(func(t: float, dur: float) -> float:
		var freqs : Array = [392.0, 523.0, 659.0, 784.0]
		var idx   : int   = int(t / dur * 4.0)
		var freq  : float = freqs[min(idx, 3)] as float
		var env   : float = sin(t / dur * PI) * exp(-t * 2.2)
		return (sin(t * TAU * freq) * 0.70 +
				sin(t * TAU * freq * 2.0) * 0.18) * env
	, 0.38), -4.0)


func talento_fusao() -> void:
	# Acorde ressonante místico — "magia combinada"
	_tocar(_wav(func(t: float, dur: float) -> float:
		var env   : float = sin(t / dur * PI) * exp(-t * 0.90)
		var atk   : float = exp(-t * 12.0)   # ataque percussivo inicial
		return (sin(t * TAU * 220.0) * 0.45 +
				sin(t * TAU * 277.0) * 0.30 +
				sin(t * TAU * 330.0) * 0.20 +
				sin(t * TAU * 440.0) * 0.12 +
				atk * 0.35) * env * 0.72
	, 0.75), -3.0)


func talento_especial() -> void:
	# Fanfarra brilhante curta — "conquista épica"
	_tocar(_wav(func(t: float, dur: float) -> float:
		var env   : float = sin(t / dur * PI) * exp(-t * 1.10)
		var bell  : float = sin(t * TAU * 1047.0) * exp(-t * 9.0)
		var bell2 : float = sin(t * TAU * 1568.0) * exp(-t * 14.0)
		return (sin(t * TAU * 523.0)  * 0.38 +
				sin(t * TAU * 659.0)  * 0.28 +
				sin(t * TAU * 784.0)  * 0.18 +
				bell  * 0.55 +
				bell2 * 0.35) * env * 0.68
	, 0.55), -2.0)


func tocar_intro_synth() -> void:
	# ── Voz "CYYYYROOOON" — Y longo → O longo, C3·E3·G3 ────────────────────
	# wi = formantes "Y/I" (ee), wo = formantes "O"
	var wi : Array[float] = [0.06, 0.04, 0.38, 0.28, 0.32, 0.22, 0.14, 0.07, 0.04, 0.02]
	var wo : Array[float] = [0.60, 0.32, 0.07, 0.03, 0.01, 0.01, 0.00, 0.00, 0.00, 0.00]
	var cf : Array[float] = [130.8*0.991, 130.8*1.009, 164.8*0.992, 164.8*1.008, 196.0*0.993, 196.0*1.007]
	_tocar(_wav(func(t: float, dur: float) -> float:
		# "C" burst → "YYYY" (0–1.1s) → crossfade suave "R" (1.1–1.8s) → "OOOON" (1.8s+)
		var tv    : float = clampf((t - 1.10) / 0.70, 0.0, 1.0)
		# suaviza com smoothstep para evitar descontinuidade
		tv = tv * tv * (3.0 - 2.0 * tv)
		var voice : float = 0.0
		for vi in range(6):
			var v : float = 0.0
			for k in range(10):
				v += sin(t * TAU * cf[vi] * float(k + 1)) * lerpf(wi[k], wo[k], tv)
			voice += v
		voice *= 0.062
		if t < 0.04:
			voice += randf_range(-1.0, 1.0) * exp(-t * 150.0) * 0.60
		var env : float = minf(t / 0.04, 1.0) * clampf((dur - t) / 1.20, 0.0, 1.0)
		return clampf(voice * env, -1.0, 1.0)
	, 4.5), 1.5)
	# ── Synth cyberpunk de fundo ─────────────────────────────────────────────
	_tocar(_wav(func(t: float, dur: float) -> float:
		var env   : float = sin(t / dur * PI) * exp(-t * 0.38)
		var freq1 : float = 220.0 + 880.0 * sin(t * TAU * 0.9)
		var s1    : float = sin(t * TAU * freq1) * 0.22
		var freq2 : float = 440.0 + 440.0 * float(int(t * 8.0) % 3) * 0.5
		var sq    : float = sign(sin(t * TAU * freq2)) * exp(-fmod(t, 0.125) * 18.0) * 0.16
		var freq3 : float = 1760.0 + 880.0 * sin(t * TAU * 2.1)
		var s3    : float = sin(t * TAU * freq3) * exp(-t * 4.5) * 0.12
		var glitch : float = (randf() * 2.0 - 1.0) * exp(-t * 30.0) * 0.10
		return clampf((s1 + sq + s3 + glitch) * env, -1.0, 1.0)
	, 2.5), -4.0)


func saberpunk_resgatar() -> void:
	# ── Coro "BETAAA" — C4·E4·G4, 10 harmônicos, formantes E→A ──────────────
	var we : Array[float] = [0.22, 0.70, 0.12, 0.08, 0.05, 0.04, 0.03, 0.22, 0.12, 0.05]
	var wa : Array[float] = [0.42, 0.16, 0.62, 0.14, 0.45, 0.08, 0.05, 0.04, 0.03, 0.02]
	var cf : Array[float] = [261.0*0.992, 261.0*1.008, 329.0*0.993, 329.0*1.007, 392.0*0.994, 392.0*1.006]

	_tocar(_wav(func(t: float, dur: float) -> float:
		var tv    : float = clampf((t - 0.56) / 0.18, 0.0, 1.0)
		var vgain : float = 1.0
		if t >= 0.36 and t < 0.56:
			vgain = maxf(0.0, 1.0 - clampf((t - 0.36) / 0.10, 0.0, 1.0))
		var voice : float = 0.0
		for vi in range(6):
			var v : float = 0.0
			for k in range(10):
				v += sin(t * TAU * cf[vi] * float(k + 1)) * lerpf(we[k], wa[k], tv)
			voice += v
		voice *= 0.060
		if t < 0.055:
			voice += randf_range(-1.0, 1.0) * exp(-t * 130.0) * 0.50
		if t >= 0.38 and t < 0.50:
			voice += randf_range(-1.0, 1.0) * exp(-(t - 0.38) * 105.0) * 0.42
		var env : float = minf(t / 0.06, 1.0) * clampf((dur - t) / 0.70, 0.0, 1.0)
		return clampf(voice * vgain * env, -1.0, 1.0)
	, 3.5), 1.5)

	# ── Synth cyberpunk em fundo ──────────────────────────────────────────────
	_tocar(_wav(func(t: float, dur: float) -> float:
		var env   : float = sin(t / dur * PI) * exp(-t * 0.38)
		var freq1 : float = 220.0 + 880.0 * sin(t * TAU * 0.9)
		var s1    : float = sin(t * TAU * freq1) * 0.22
		var freq2 : float = 440.0 + 440.0 * float(int(t * 8.0) % 3) * 0.5
		var sq    : float = sign(sin(t * TAU * freq2)) * exp(-fmod(t, 0.125) * 18.0) * 0.16
		var freq3 : float = 1760.0 + 880.0 * sin(t * TAU * 2.1)
		var s3    : float = sin(t * TAU * freq3) * exp(-t * 4.5) * 0.12
		var glitch : float = (randf() * 2.0 - 1.0) * exp(-t * 30.0) * 0.10
		return clampf((s1 + sq + s3 + glitch) * env, -1.0, 1.0)
	, 2.5), -8.0)


func game_over_som() -> void:
	_tocar(_wav(func(t: float, dur: float) -> float:
		var freqs : Array = [440.0, 370.0, 311.0, 220.0]
		var idx   : int   = int(t / dur * 4.0)
		var freq  : float = freqs[min(idx, 3)] as float
		var env   : float = sin(t / dur * PI) * exp(-t * 1.2)
		return sin(t * TAU * freq) * env * 0.85
	, 1.1), -4.0)


# ── Internos ──────────────────────────────────────────────────────────────────

func _bau_tier_ok(tier: String) -> String:
	if tier in ["comum", "raro", "epico", "lendario"]:
		return tier
	return "comum"


func _bau_cfg(tier: String) -> Dictionary:
	match tier:
		"raro":
			return {"dur": 2.20, "root": 293.66, "spark": 1318.51, "peso": 1.08,
				"notas": [293.66, 369.99, 587.33, 739.99]}
		"epico":
			return {"dur": 2.72, "root": 196.00, "spark": 1567.98, "peso": 1.18,
				"notas": [196.00, 261.63, 392.00, 523.25, 783.99]}
		"lendario":
			return {"dur": 3.25, "root": 220.00, "spark": 2093.00, "peso": 1.32,
				"notas": [220.00, 277.18, 329.63, 440.00, 554.37, 659.25, 880.00]}
		_:
			return {"dur": 1.82, "root": 261.63, "spark": 987.77, "peso": 0.96,
				"notas": [261.63, 329.63, 392.00]}


func _bau_inicio_stream(tier: String) -> AudioStreamWAV:
	if _bau_inicio_cache.has(tier):
		return _bau_inicio_cache[tier] as AudioStreamWAV
	var cfg := _bau_cfg(tier)
	var dur : float = float(cfg["dur"])
	var root : float = float(cfg["root"])
	var spark : float = float(cfg["spark"])
	var peso : float = float(cfg["peso"])
	var notas : Array = cfg["notas"] as Array
	var stream := _wav(func(t: float, d: float) -> float:
		var s : float = 0.0
		if t < 0.34:
			var env_hit : float = exp(-t * 8.0)
			s += sin(t * TAU * maxf(38.0, 128.0 * peso - t * 180.0)) * env_hit * 0.42
			s += randf_range(-1.0, 1.0) * exp(-t * 34.0) * 0.16
		for i in range(4):
			var st : float = 0.10 + float(i) * (0.16 if tier != "lendario" else 0.13)
			if t >= st and t <= st + 0.10:
				var lt : float = t - st
				s += (sin(t * TAU * (root * (0.7 + float(i) * 0.25))) + randf_range(-0.18, 0.18)) * exp(-lt * 34.0) * 0.20
		var reveal_t : float = d * 0.48
		if t >= reveal_t - 0.72 and t <= reveal_t:
			var p : float = clampf((t - (reveal_t - 0.72)) / 0.72, 0.0, 1.0)
			var freq : float = lerpf(root * 0.70, spark * 0.82, p * p)
			s += sin(t * TAU * freq) * p * p * 0.24
			s += randf_range(-1.0, 1.0) * p * 0.055
		for ni in range(notas.size()):
			var nf : float = float(notas[ni])
			var stn : float = reveal_t + float(ni) * (0.105 if tier != "lendario" else 0.085)
			if t >= stn:
				var lt2 : float = t - stn
				var env : float = exp(-lt2 * (2.8 if tier == "lendario" else 3.5)) * clampf(lt2 / 0.018, 0.0, 1.0)
				s += (sin(t * TAU * nf * 2.0) * 0.33 + sin(t * TAU * nf * 4.0) * 0.10) * env
		if t >= reveal_t:
			var rt : float = t - reveal_t
			s += sin(t * TAU * root) * exp(-rt * 1.25) * 0.18
			for pi in range(3 if tier != "lendario" else 6):
				var rate : float = 16.0 + float(pi) * 1.7
				var step : float = floor(rt * rate)
				var dust_env : float = exp(-fmod(rt * rate, 1.0) * 8.0)
				var pf : float = spark * (1.0 + fmod(step + float(pi), 5.0) * 0.22)
				s += sin(t * TAU * pf) * dust_env * 0.025
		return clampf(s * 0.78 * peso, -1.0, 1.0)
	, dur)
	_bau_inicio_cache[tier] = stream
	return stream


func _bau_final_stream(tier: String) -> AudioStreamWAV:
	if _bau_final_cache.has(tier):
		return _bau_final_cache[tier] as AudioStreamWAV
	var cfg := _bau_cfg(tier)
	var root : float = float(cfg["root"])
	var spark : float = float(cfg["spark"])
	var peso : float = float(cfg["peso"])
	var dur : float = 0.72 if tier != "lendario" else 1.05
	var stream := _wav(func(t: float, d: float) -> float:
		var env : float = sin(t / d * PI) * exp(-t * 0.9)
		var s : float = 0.0
		s += sin(t * TAU * root * 2.0) * 0.28
		s += sin(t * TAU * root * 2.5) * 0.20
		s += sin(t * TAU * root * 3.0) * 0.16
		s += sin(t * TAU * spark) * exp(-t * 5.0) * 0.18
		s += randf_range(-1.0, 1.0) * exp(-t * 18.0) * 0.05
		return clampf(s * env * peso, -1.0, 1.0)
	, dur)
	_bau_final_cache[tier] = stream
	return stream


func _bau_carta_stream(tipo: String) -> AudioStreamWAV:
	var key := tipo
	if _bau_carta_cache.has(key):
		return _bau_carta_cache[key] as AudioStreamWAV
	var base : float = 880.0
	match tipo:
		"ouro":
			base = 740.0
		"cristais":
			base = 1180.0
		"skin":
			base = 980.0
		"pet":
			base = 1040.0
		"habil":
			base = 1320.0
		"cons":
			base = 820.0
		"bau":
			base = 660.0
	var stream := _wav(func(t: float, d: float) -> float:
		var env : float = sin(t / d * PI) * exp(-t * 3.0)
		var flip : float = sin(t * TAU * lerpf(base * 0.45, base * 1.35, clampf(t / d, 0.0, 1.0))) * exp(-t * 8.0) * 0.30
		var bell : float = (sin(t * TAU * base) * 0.42 + sin(t * TAU * base * 2.0) * 0.16) * env
		var snap : float = randf_range(-1.0, 1.0) * exp(-t * 42.0) * 0.12
		return clampf(flip + bell + snap, -1.0, 1.0)
	, 0.42)
	_bau_carta_cache[key] = stream
	return stream


func _gerar_bau_celestial() -> AudioStreamWAV:
	# Sinos C5 E5 G5 C6 → coral "Ooohhh" angelical
	var btimes : Array[float] = [0.0,    0.30,   0.60,   0.94,   1.42]
	var bfreqs : Array[float] = [523.25, 659.25, 784.0, 1046.5, 1046.5]
	var bdecay : Array[float] = [15.0,   15.0,   15.0,   11.0,    3.0]
	var bvols  : Array[float] = [0.30,   0.33,   0.36,   0.42,   0.48]
	# Formantes "Ooh" (vogal arredondada celestial)
	var wo : Array[float] = [0.60, 0.32, 0.07, 0.03, 0.01, 0.01, 0.00, 0.00, 0.00, 0.00]
	# 6 vozes do coro: C4 E4 G4 com detuning bilateral para largura coral
	var cv : Array[float] = [261.63*0.991, 261.63*1.009, 329.63*0.993,
							 329.63*1.007, 392.0*0.994,  392.0*1.006]
	return _wav(func(t: float, d: float) -> float:
		var s := 0.0

		# ── Sinos ascendentes "tan tan tan tam tammm" ────────────────────────
		for bi in range(5):
			if t >= btimes[bi]:
				var lt  := t - btimes[bi]
				var env := exp(-lt * bdecay[bi])
				var f   := bfreqs[bi]
				s += sin(t * TAU * f)       * env * bvols[bi]
				s += sin(t * TAU * f * 2.0) * exp(-lt * bdecay[bi] * 1.7) * bvols[bi] * 0.28
				s += sin(t * TAU * f * 3.0) * exp(-lt * bdecay[bi] * 2.5) * bvols[bi] * 0.10
				if bi == 4:
					# sub-oitava na última nota — peso angélico
					s += sin(t * TAU * f * 0.5) * exp(-lt * 2.2) * 0.22

		# ── Coral "Ooohhh" angelical — swell suave a partir da 4ª nota ───────
		if t >= 0.90:
			var ct   := t - 0.90
			var rem  := d - t
			var rise := clampf(ct / 1.10, 0.0, 1.0)
			rise       = rise * rise * (3.0 - 2.0 * rise)   # smoothstep
			var fall := clampf(rem / 1.40, 0.0, 1.0)
			var cenv := rise * fall

			var choir := 0.0
			for vi in range(6):
				var v := 0.0
				for k in range(10):
					v += sin(t * TAU * cv[vi] * float(k + 1)) * wo[k]
				choir += v
			s += choir * 0.040 * cenv * 0.70

			# Shimmer etéreo (agudo suave)
			var senv := clampf(ct / 0.5, 0.0, 1.0) * clampf(rem / 1.0, 0.0, 1.0)
			s += sin(t * TAU * 1318.51) * senv * 0.042
			s += sin(t * TAU * 1567.98) * senv * 0.028
			s += sin(t * TAU * 2093.00) * senv * 0.016

		return clampf(s * 0.82, -1.0, 1.0)
	, 4.5)


func _wav(fn: Callable, dur: float, vol: float = 1.0) -> AudioStreamWAV:
	var stream      := AudioStreamWAV.new()
	stream.format   = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo   = false
	stream.mix_rate = SR

	var n   : int           = int(SR * dur)
	var buf : PackedByteArray = PackedByteArray()
	buf.resize(n * 2)

	for i in range(n):
		var t : float = float(i) / float(SR)
		var s : float = clamp(float(fn.call(t, dur)) * vol, -1.0, 1.0)
		var v : int   = int(s * 32767.0)
		buf[i * 2]     = v & 0xFF
		buf[i * 2 + 1] = (v >> 8) & 0xFF

	stream.data = buf
	return stream


func _tocar(stream: AudioStreamWAV, volume_db: float = 0.0) -> void:
	if volume_sfx <= 0.001:
		return   # mudo
	var db_final : float = volume_db + linear_to_db(clampf(volume_sfx, 0.001, 1.0))
	for p in _pool:
		if not p.playing:
			p.stream    = stream
			p.volume_db = db_final
			p.play()
			return


func _sfx_interval_ok(key: String, min_ms: int) -> bool:
	var now : int = Time.get_ticks_msec()
	var last : int = int(_sfx_last_ms.get(key, -1000000))
	if now - last < min_ms:
		return false
	_sfx_last_ms[key] = now
	return true
