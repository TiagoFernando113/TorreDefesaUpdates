extends Node
## Um jogador de mentira, jogando o jogo de verdade.
##
## Existe para responder uma pergunta que ninguém consegue responder jogando:
## quantas HORAS um jogador leva para zerar o Cyron Defense, e onde exatamente
## a progressão trava. Sentar e jogar 35 horas para descobrir não é opção, e
## palpite sobre curva de progressão erra por ordens de grandeza.
##
## ─────────────────────────────────────────────────────────────────────────
## O QUE AQUI É O JOGO DE VERDADE, E O QUE É MODELO
##
## Isto importa mais que qualquer número que sai daqui. Um simulador que se
## passa por jogo mente com confiança.
##
## SÃO O JOGO DE VERDADE (lidos do código, nunca copiados):
##   · a composição de cada wave  → main.gd::_get_wave_config
##   · o HP, dano e velocidade de cada mob por wave → mob.gd, instanciado
##   · os atributos da torre e os bônus de loja/talentos → torre.gd + a mesma
##     sequência de _criar_torre
##   · custos, tetos e efeito de cada trilha do painel → painel_comando.gd
##   · custo e requisito de cada talento → Salvar.TALENTOS_INFO
##   · preços da loja → Salvar.LOJA_INFO
##   · ouro e cristais por wave → as mesmas fórmulas do main.gd
##
## É MODELO (aproximação minha, e pode errar):
##   · O COMBATE. Não há projétil, mira, alcance nem caminho aqui. A wave é
##     resolvida comparando o dano que a torre consegue despejar durante a
##     wave com o HP total da horda; o que sobra vaza e bate na torre.
##
## O que isso quer dizer na prática: os números de ECONOMIA e de TEMPO são
## confiáveis, porque saem das fórmulas reais. Os de "até que wave chega" são
## uma estimativa OTIMISTA -- o bot não erra tiro, não perde mob por alcance e
## não morre por um colossus que passou. Trate-os como teto, não como média.
##
## ─────────────────────────────────────────────────────────────────────────
## COMO RODAR
##
##   godot --headless --path . res://tools/bot_progressao.tscn
##
## Fica em tools/ e não em tests/ de propósito: o test runner roda tudo que
## casa com tests/test_*.tscn, e isto leva minutos. Simulação não é teste --
## ela não tem certo e errado, tem resultado.

const MAIN  := preload("res://scripts/main.gd")
const MOB   := preload("res://scripts/mob.gd")
const TORRE := preload("res://scripts/torre.gd")
const PAINEL := preload("res://scripts/partida/painel_comando.gd")

## Quantas partidas simular antes de desistir de "zerar".
const MAX_PARTIDAS : int = 4000
## Teto de wave por partida. A dificuldade congela na 250; passar muito disso
## só gastaria tempo de CPU dizendo a mesma coisa.
const MAX_WAVE : int = 300

var _cfg_cache : Dictionary = {}
var _hp_cache  : Dictionary = {}
var _jogo_aux : Node = null


func _ready() -> void:
	call_deferred("_run")


# ── O jogo de verdade, consultado ────────────────────────────────────────────

func _wave_cfg(w: int) -> Dictionary:
	if _cfg_cache.has(w):
		return _cfg_cache[w]
	var c : Dictionary = _jogo_aux.call("_get_wave_config", w)
	_cfg_cache[w] = c
	return c


## HP e dano REAIS de um mob, lidos de um mob de verdade construído para
## aquela wave. Copiar a fórmula para cá seria o erro clássico: ela mudaria no
## jogo e o simulador continuaria respondendo com a antiga.
func _mob_real(tipo: String, w: int) -> Dictionary:
	var chave : String = "%s@%d" % [tipo, w]
	if _hp_cache.has(chave):
		return _hp_cache[chave]
	var m = MOB.new()
	m.tipo = tipo
	m.wave_num = w
	add_child(m)
	var d : Dictionary = {"hp": float(m.hp), "dano": float(m.damage), "speed": float(m.speed),
			"ouro": int(m.gold_v), "score": int(m.score_v)}
	m.free()
	_hp_cache[chave] = d
	return d


func _horda(w: int) -> Dictionary:
	var cfg : Dictionary = _wave_cfg(w)
	var hp : float = 0.0
	var dano : float = 0.0
	var n : int = 0
	var ouro : int = 0
	for tipo in cfg.keys():
		if tipo == "intervalo":
			continue
		var q : int = int(cfg[tipo])
		if q <= 0:
			continue
		var m : Dictionary = _mob_real(str(tipo), w)
		hp   += float(m["hp"]) * float(q)
		dano += float(m["dano"]) * float(q)
		ouro += int(m["ouro"]) * q
		n    += q
	return {"hp": hp, "dano": dano, "n": n, "ouro": ouro,
			"dur": float(n) * float(cfg.get("intervalo", 0.5))}


## Monta a torre exatamente como _criar_torre monta, com a loja e os talentos
## que o bot já comprou.
func _montar_torre(melhorias: Dictionary, talentos: Dictionary) -> Node:
	var t = TORRE.new()
	add_child(t)
	t.damage    += float(int(melhorias.get("forca", 0))) * 8.0
	t.max_hp    += float(int(melhorias.get("resistencia", 0))) * 40.0
	t.range_r   += float(int(melhorias.get("visao", 0))) * 25.0
	t.fire_rate += float(int(melhorias.get("cadencia", 0))) * 0.2
	# Raiz, sempre ativa
	t.damage += 10.0
	t.max_hp += 20.0
	if talentos.get("p1", false): t.damage    += 30.0
	if talentos.get("p2", false): t.fire_rate += 0.5
	if talentos.get("p4", false): t.damage    += 80.0
	if talentos.get("r1", false): t.damage_reduction = 0.25
	if talentos.get("r2", false): t.regen_rate += 4.0
	if talentos.get("r4", false): t.max_hp     += 100.0
	if talentos.get("colosso", false):
		t.damage += 50.0; t.max_hp += 50.0; t.fire_rate += 0.3
	if talentos.get("tita", false):
		t.damage += 150.0; t.max_hp += 200.0
	if talentos.get("sobrev", false): t.regen_rate += 1.0
	t.hp = t.max_hp
	return t


# ── O modelo de combate (a parte que NÃO é o jogo) ───────────────────────────

func _dps(t: Node, arma: Dictionary) -> float:
	var crit : float = 1.0 + float(t.crit_chance) * (float(t.crit_mult) - 1.0)
	return float(t.damage) * float(arma.get("dano", 1.0)) \
		* float(t.fire_rate) * float(arma.get("cad", 1.0)) * crit


# ── A partida ────────────────────────────────────────────────────────────────

## Joga uma partida inteira e devolve o que ela rendeu.
##
## `politica` diz como o bot gasta energia. Duas de propósito: um jogador que
## só empilha dano e um que distribui. A diferença entre as duas diz se a
## progressão depende de saber jogar ou não.
func _jogar(melhorias: Dictionary, talentos: Dictionary, politica: String, arma: Dictionary) -> Dictionary:
	var t : Node = _montar_torre(melhorias, talentos)
	var p = PAINEL.new(null)
	# O painel precisa da base da torre; sem o `jogo` ele não captura sozinho.
	p._base = {"dano": float(t.damage), "cadencia": float(t.fire_rate),
			"vida": float(t.max_hp), "alcance": float(t.range_r)}
	var energia : int = p.ENERGIA_INICIAL

	var hp : float = float(t.max_hp)
	var ouro : int = 0
	var cristais : int = 0
	var segundos : float = 0.0
	var wave : int = 0

	var ordem : Array = ["dano", "cadencia", "crit", "critdano"] if politica == "dano" \
			else ["dano", "cadencia", "vida", "energia", "crit", "critdano", "regen", "alcance"]

	while wave < MAX_WAVE:
		wave += 1
		var h : Dictionary = _horda(wave)

		# ── o bot gasta energia antes da wave ──
		var mudou : bool = true
		while mudou:
			mudou = false
			for trilha in ordem:
				var nv : int = int(p._niveis.get(trilha, 0))
				if nv >= p.cap(trilha):
					continue
				var custo : int = int(p._cfg(trilha)["base"]) + nv * int(p._cfg(trilha)["step"])
				if energia < custo:
					continue
				energia -= custo
				p._niveis[trilha] = nv + 1
				var c : Dictionary = p._cfg(trilha)
				var frac : float = float(c["frac"])
				match str(c.get("modo", "pct")):
					"pct":
						match trilha:
							"dano":     t.damage    += float(p._base["dano"]) * frac
							"cadencia": t.fire_rate += float(p._base["cadencia"]) * frac
							"vida":
								t.max_hp += float(p._base["vida"]) * frac
								hp += float(p._base["vida"]) * frac
							"alcance":  t.range_r   += float(p._base["alcance"]) * frac
					"regen_pct": t.regen_rate += float(p._base["vida"]) * frac
					"crit_chance": t.crit_chance += frac
					"crit_mult":   t.crit_mult   += frac
				mudou = true

		# ── resolve a wave (MODELO) ──
		var dur : float = maxf(1.0, float(h["dur"]))
		var saida : float = _dps(t, arma) * dur
		var sobra : float = maxf(0.0, float(h["hp"]) - saida)
		var frac_viva : float = sobra / maxf(1.0, float(h["hp"]))
		# O que não morreu chega na torre. `damage_reduction` é real.
		var levou : float = float(h["dano"]) * frac_viva * (1.0 - float(t.damage_reduction))
		hp = minf(float(t.max_hp), hp + float(t.regen_rate) * dur) - levou
		segundos += dur

		if hp <= 0.0:
			break

		# ── renda da wave, com as fórmulas do jogo ──
		ouro += int(float(5 + wave * 2) * 0.45)
		ouro += int(float(h["ouro"]) * 0.45)
		cristais += maxi(1, wave / 10)
		energia += int(round(float(int(h["n"]) + 5 + wave) * (1.0 + float(p._niveis.get("energia", 0)) * 0.06)))

	t.free()
	return {"wave": wave, "ouro": ouro, "cristais": cristais, "min": segundos / 60.0,
			"dano_fim": float(t.damage) if is_instance_valid(t) else 0.0}


# ── A carreira: partida após partida, comprando o que dá ─────────────────────

func _comprar_talentos(talentos: Dictionary, cristais: int) -> int:
	## Mais barato primeiro, respeitando requisito. É a ordem que um jogador
	## racional segue, e a mais rápida de zerar -- então o tempo que sai daqui
	## é o MELHOR caso.
	var mudou : bool = true
	while mudou:
		mudou = false
		var melhor : String = ""
		var melhor_custo : int = 1 << 30
		for tid in Salvar.TALENTOS_INFO.keys():
			var id : String = tid as String
			if id == "raiz" or talentos.get(id, false):
				continue
			var info : Dictionary = Salvar.TALENTOS_INFO[id] as Dictionary
			var custo : int = int(info.get("custo", 0))
			if custo > cristais or custo >= melhor_custo:
				continue
			var ok : bool = true
			for r in (info.get("req", []) as Array):
				if str(r) != "raiz" and not talentos.get(str(r), false):
					ok = false
					break
			if ok:
				melhor = id
				melhor_custo = custo
		if melhor != "":
			cristais -= melhor_custo
			talentos[melhor] = true
			mudou = true
	return cristais


func _comprar_loja(melhorias: Dictionary, ouro: int) -> int:
	var mudou : bool = true
	while mudou:
		mudou = false
		for lid in Salvar.LOJA_INFO.keys():
			var id : String = lid as String
			var nv : int = int(melhorias.get(id, 0))
			var custos : Array = (Salvar.LOJA_INFO[id] as Dictionary)["custos"] as Array
			if nv >= custos.size():
				continue
			var c : int = int(custos[nv])
			if ouro >= c:
				ouro -= c
				melhorias[id] = nv + 1
				mudou = true
	return ouro


func _carreira(politica: String, arma_nome: String, arma: Dictionary) -> void:
	var melhorias : Dictionary = {"forca": 0, "resistencia": 0, "visao": 0, "cadencia": 0, "fortuna": 0}
	var talentos : Dictionary = {}
	var cristais : int = 0
	var ouro : int = 0
	var minutos : float = 0.0
	var total_talentos : int = 0
	for tid in Salvar.TALENTOS_INFO.keys():
		if str(tid) != "raiz":
			total_talentos += 1

	print("\n═══ %s · politica de gasto: %s ═══" % [arma_nome, politica])
	print(" part. | wave |  min  | talentos | loja  |  torre no inicio  | horas")

	var loja_cheia : int = -1
	for n in range(1, MAX_PARTIDAS + 1):
		var tt : Node = _montar_torre(melhorias, talentos)
		var dano_ini : float = float(tt.damage)
		var hp_ini : float = float(tt.max_hp)
		tt.free()
		var r : Dictionary = _jogar(melhorias, talentos, politica, arma)
		minutos += float(r["min"])
		cristais += int(r["cristais"])
		ouro += int(r["ouro"])
		cristais = _comprar_talentos(talentos, cristais)
		ouro = _comprar_loja(melhorias, ouro)

		var nt : int = talentos.size()
		var nl : int = 0
		for k in melhorias.keys():
			nl += int(melhorias[k])
		if nl >= 15 and loja_cheia < 0:
			loja_cheia = n

		if true:
			print("  %4d | %4d | %5.0f |  %3d/%d  | %2d/15 | dano %5.0f hp %4.0f | %6.1f h"
					% [n, int(r["wave"]), float(r["min"]), nt, total_talentos, nl, dano_ini, hp_ini, minutos / 60.0])
		if nt >= total_talentos:
			print("  ➜ TUDO comprado na partida %d, com %.1f horas de jogo." % [n, minutos / 60.0])
			if loja_cheia > 0:
				print("  ➜ A loja ja' estava cheia na partida %d." % loja_cheia)
			return
	print("  ➜ nao zerou em %d partidas (%.0f h)" % [MAX_PARTIDAS, minutos / 60.0])


func _run() -> void:
	_jogo_aux = MAIN.new()
	print("BOT DE PROGRESSAO — Cyron Defense")
	print("Combate e' MODELO; economia, custos e escalas sao o codigo real.")
	_carreira("dano", "arma Padrao", {"cad": 1.0, "dano": 1.0})
	_jogo_aux.free()
	get_tree().quit(0)
