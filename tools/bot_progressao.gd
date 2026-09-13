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
## O bot para na wave final do jogo -- e le' o numero DE LA', em vez de
## repeti-lo. Foi o erro que ja' custou uma medicao inteira: numero copiado
## envelhece calado.
var MAX_WAVE : int = MAIN.WAVE_FINAL

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


## A torre montada pelo PRÓPRIO _criar_torre do jogo.
##
## A primeira versão disto repetia a sequência de bônus aqui dentro. Custou
## caro: quando o jogo ganhou o reforço por tecnologia, o bot continuou
## medindo a versão antiga e reportou, com confiança, uma zona morta que já
## tinha sido consertada. Um simulador que duplica o código mede o passado.
##
## Agora ele empresta o estado ao `Salvar` de verdade e chama a função de
## verdade. Tudo que _criar_torre fizer daqui em diante -- talento novo, skin,
## equipamento, bônus de conta -- entra aqui sozinho.
func _montar_torre(melhorias: Dictionary, talentos: Dictionary, asc: int = 0) -> Node:
	var mel_antes : Dictionary = Salvar.melhorias.duplicate(true)
	var tal_antes : Dictionary = Salvar.talentos.duplicate(true)
	var asc_antes : int = Salvar.ascensoes

	for k in melhorias.keys():
		Salvar.melhorias[k] = int(melhorias[k])
	Salvar.talentos = talentos.duplicate(true)
	Salvar.ascensoes = asc

	## NAO entra na arvore de proposito: o `_ready` do main faz `ui_node = $UI`,
	## e num Main pelado esse filho nao existe. `add_child` funciona em no
	## solto, entao `_criar_torre` roda inteiro sem o `_ready` junto.
	var jogo = MAIN.new()
	jogo.call("_criar_torre")
	var t : Node = jogo.torre
	if t != null and is_instance_valid(t):
		jogo.remove_child(t)
		add_child(t)
	jogo.free()

	Salvar.melhorias = mel_antes
	Salvar.talentos = tal_antes
	Salvar.ascensoes = asc_antes
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
func _jogar(melhorias: Dictionary, talentos: Dictionary, politica: String, arma: Dictionary, asc: int = 0) -> Dictionary:
	var t : Node = _montar_torre(melhorias, talentos, asc)
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
		ouro += int(float(h["ouro"]) * 0.45 * (1.0 + float(Salvar.bonus_ascensao_stats(asc).get("ouro_mult", 0.0))))
		var _cm : float = float(Salvar.bonus_ascensao_stats(asc).get("cristais_mult", 1.0))
		cristais += maxi(1, int(round(float(maxi(1, wave / 10)) * _cm)))
		energia += int(round(float(int(h["n"]) + 5 + wave) * (1.0 + float(p._niveis.get("energia", 0)) * 0.06)))

	t.free()
	return {"wave": wave, "venceu": wave >= MAX_WAVE and hp > 0.0,
			"ouro": ouro, "cristais": cristais, "min": segundos / 60.0,
			"dano_fim": float(t.damage) if is_instance_valid(t) else 0.0}


# ── A carreira: partida após partida, comprando o que dá ─────────────────────

func _comprar_talentos(talentos: Dictionary, cristais: int, asc: int = 0) -> int:
	var _desc : float = float(Salvar.bonus_ascensao_stats(asc).get("talento_desconto", 0.0))
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
			var custo : int = maxi(1, int(round(float(int(info.get("custo", 0))) * (1.0 - _desc))))
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


## A carreira INTEIRA, ate' o teto do bonus de ascensao.
##
## "Zerar" nunca foi completar a arvore uma vez: a ascensao ZERA a arvore e as
## melhorias e pede tudo de novo, e o bonus so' para de crescer no nivel 50.
## Esse e' o jogo longo, e ninguem tinha medido quanto ele dura.
func _carreira(politica: String, arma_nome: String, arma: Dictionary) -> void:
	var melhorias : Dictionary = {"forca": 0, "resistencia": 0, "visao": 0, "cadencia": 0, "fortuna": 0}
	var talentos : Dictionary = {}
	var cristais : int = 0
	var ouro : int = 0
	var minutos : float = 0.0
	var asc : int = 0
	var partidas : int = 0
	var vitorias : int = 0
	var primeira_vitoria : int = -1
	var total_talentos : int = 0
	for tid in Salvar.TALENTOS_INFO.keys():
		if str(tid) != "raiz":
			total_talentos += 1
	var teto_asc : int = int(ceil(Salvar.ASCENSAO_MAX_DANO_VIDA / Salvar.ASCENSAO_DANO_VIDA_POR_NIVEL))

	print("\n═══ %s · %s ═══" % [arma_nome, politica])
	print(" part. | wave | tecs | dano | horas   (ascensao)")

	while asc < teto_asc and partidas < MAX_PARTIDAS:
		var tt : Node = _montar_torre(melhorias, talentos, asc)
		var dano_ini : float = float(tt.damage)
		tt.free()
		var r : Dictionary = _jogar(melhorias, talentos, politica, arma, asc)
		partidas += 1
		minutos += float(r["min"])
		cristais += int(r["cristais"])
		ouro += int(r["ouro"])
		if bool(r["venceu"]):
			vitorias += 1
			if primeira_vitoria < 0:
				primeira_vitoria = asc
				print("  ★ PRIMEIRA VITORIA na ascensao %d, partida %d, %.0f h"
						% [asc, partidas, minutos / 60.0])
		cristais = _comprar_talentos(talentos, cristais, asc)
		ouro = _comprar_loja(melhorias, ouro)
		if asc == 0 and partidas <= 22:
			print("  %4d | %4d%s | %3d  | %4.0f | %5.1f h" % [partidas, int(r["wave"]),
					" VENCEU" if bool(r["venceu"]) else "      ", talentos.size(), dano_ini, minutos / 60.0])
		if talentos.size() >= total_talentos and cristais >= Salvar.ascensao_custo_cristais(asc + 1):
			cristais -= Salvar.ascensao_custo_cristais(asc + 1)
			talentos.clear()
			for k in melhorias.keys():
				melhorias[k] = 0
			ouro = 0
			asc += 1
			if asc <= 2 or asc % 10 == 0 or asc == teto_asc:
				print("  ---- ascensao %d em %d partidas, %.0f h" % [asc, partidas, minutos / 60.0])
	print("  ➜ %d ascensoes · %d partidas · %.0f horas · %.1f MESES a 1h/dia"
			% [asc, partidas, minutos / 60.0, minutos / 60.0 / 30.0])
	if primeira_vitoria < 0:
		print("  ➜ NUNCA venceu a wave %d em %d partidas -- o fim existe e nao foi alcancado."
				% [MAX_WAVE, partidas])
	else:
		print("  ➜ venceu a wave %d em %d de %d partidas (a primeira na ascensao %d)"
				% [MAX_WAVE, vitorias, partidas, primeira_vitoria])


func _run() -> void:
	_jogo_aux = MAIN.new()
	print("BOT DE PROGRESSAO — Cyron Defense")
	print("Combate e' MODELO; economia, custos e escalas sao o codigo real.")
	print("Reforco por tecnologia lido do jogo: %.1f%% | p4 %.0f tita %.0f colosso %.0f\n"
			% [MAIN.NUCLEO_POR_TECNOLOGIA * 100.0, MAIN.P4_DANO, MAIN.TITA_DANO, MAIN.COLOSSO_DANO])
	_carreira("dano", "jogo atual", {"cad": 1.0, "dano": 1.0})
	_jogo_aux.free()
	get_tree().quit(0)
