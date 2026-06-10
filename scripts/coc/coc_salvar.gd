extends Node
## COC_SALVAR — Persistência independente para o sistema CoC

const _DADOS = preload("res://scripts/coc/coc_dados.gd")
## Salva em user://coc_save.json (separado do save principal do tower defense)
## Integração com o jogo principal: coc_main.gd lê/grava via este singleton

const SAVE_PATH := "user://coc_save.json"

# ── Recursos ──────────────────────────────────────────────────────────────────
var ouro         : int  = 1000   # Gold
var elixir       : int  = 1000   # Elixir
var escuro       : int  = 0      # Dark Elixir
var gemas        : int  = 250    # Gems (premium)
var trofeus      : int  = 1000   # Trophies

# ── Construtores ──────────────────────────────────────────────────────────────
var construtores_total : int   = 2          # aumenta com cabana_construtor

# ── Vila ──────────────────────────────────────────────────────────────────────
# "gx,gy" → {tipo, nivel, hp, acum, ultimo_tick_ms}
var slots        : Dictionary = {}

# ── Construção ────────────────────────────────────────────────────────────────
# [{key, tipo, nivel_alvo, fim_ms}]
var construcoes  : Array      = []

# ── Treino ────────────────────────────────────────────────────────────────────
# {barracks_key: [{tipo, fim_ms}]}  — fila por quartel
var fila_treino  : Dictionary = {}

# Tropas prontas: {tipo: count}
var tropas       : Dictionary = {}

# Feitiços prontos: {tipo: count}
var feiticos     : Dictionary = {}

# ── Pesquisa ──────────────────────────────────────────────────────────────────
# {} ou {tipo, nivel_alvo, fim_ms}
var pesquisa     : Dictionary = {}

# Níveis das tropas/feitiços pós-pesquisa: {tipo: nivel}
var niveis       : Dictionary = {}

# ── Batalha ───────────────────────────────────────────────────────────────────
var trofeus_historico : Array = []    # últimas vitórias/derrotas

# ── Raid (Fase 2 — naves atacam a vila, ligado às waves) ──────────────────────
var raid_pendente : int = 0           # poder de invasão acumulado pelas waves
var raid_wave_ref : int = 1           # wave de referência (escala dificuldade)

# ══════════════════════════════════════════════════════════════════════════════
#  SAVE / LOAD
# ══════════════════════════════════════════════════════════════════════════════
func salvar() -> void:
	var data := {
		"ouro":        ouro,
		"elixir":      elixir,
		"escuro":      escuro,
		"gemas":       gemas,
		"trofeus":     trofeus,
		"construtores_total": construtores_total,
		"slots":       slots,
		"construcoes": construcoes,
		"fila_treino": fila_treino,
		"tropas":      tropas,
		"feiticos":    feiticos,
		"pesquisa":    pesquisa,
		"niveis":      niveis,
		"raid_pendente": raid_pendente,
		"raid_wave_ref": raid_wave_ref,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func carregar() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f    := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data  = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary: return
	ouro        = int(data.get("ouro",        1000))
	elixir      = int(data.get("elixir",      1000))
	escuro      = int(data.get("escuro",      0))
	gemas       = int(data.get("gemas",       250))
	trofeus     = int(data.get("trofeus",     1000))
	construtores_total = int(data.get("construtores_total", 2))
	var sl = data.get("slots", {});       slots       = sl if sl is Dictionary else {}
	var co = data.get("construcoes", []); construcoes = co if co is Array else []
	var ft = data.get("fila_treino", {}); fila_treino = ft if ft is Dictionary else {}
	var tr = data.get("tropas",      {}); tropas      = tr if tr is Dictionary else {}
	var fe = data.get("feiticos",    {}); feiticos    = fe if fe is Dictionary else {}
	var pe = data.get("pesquisa",    {}); pesquisa    = pe if pe is Dictionary else {}
	var ni = data.get("niveis",      {}); niveis      = ni if ni is Dictionary else {}
	raid_pendente = int(data.get("raid_pendente", 0))
	raid_wave_ref = int(data.get("raid_wave_ref", 1))

# ══════════════════════════════════════════════════════════════════════════════
#  HELPERS DE RECURSOS
# ══════════════════════════════════════════════════════════════════════════════
func tem_ouro(n: int) -> bool:   return ouro   >= n
func tem_elixir(n: int) -> bool: return elixir >= n
func tem_escuro(n: int) -> bool: return escuro >= n
func tem_gemas(n: int) -> bool:  return gemas  >= n

func gastar_ouro(n: int) -> bool:
	if ouro < n: return false
	ouro -= n; salvar(); return true

func gastar_elixir(n: int) -> bool:
	if elixir < n: return false
	elixir -= n; salvar(); return true

func gastar_escuro(n: int) -> bool:
	if escuro < n: return false
	escuro -= n; salvar(); return true

func gastar_gemas(n: int) -> bool:
	if gemas < n: return false
	gemas -= n; salvar(); return true

func ganhar_ouro(n: int, cap: int = 999999) -> void:
	ouro = mini(ouro + n, cap); salvar()

func ganhar_elixir(n: int, cap: int = 999999) -> void:
	elixir = mini(elixir + n, cap); salvar()

func ganhar_escuro(n: int, cap: int = 999999) -> void:
	escuro = mini(escuro + n, cap); salvar()

# ══════════════════════════════════════════════════════════════════════════════
#  CONSTRUTORES
# ══════════════════════════════════════════════════════════════════════════════
func construtores_ocupados() -> int:
	return construcoes.size()

func construtores_livres() -> int:
	return maxi(0, construtores_total - construtores_ocupados())

func tem_construtor_livre() -> bool:
	return construtores_livres() > 0

# ══════════════════════════════════════════════════════════════════════════════
#  SLOTS
# ══════════════════════════════════════════════════════════════════════════════
func slot(key: String) -> Dictionary:
	return slots.get(key, {}) as Dictionary

func slot_tipo(key: String) -> String:
	return (slot(key) as Dictionary).get("tipo","") as String

func slot_nivel(key: String) -> int:
	return int((slot(key) as Dictionary).get("nivel",1))

func slot_hp(key: String) -> int:
	return int((slot(key) as Dictionary).get("hp",0))

func slot_em_construcao(key: String) -> bool:
	for c in construcoes:
		if (c as Dictionary).get("key","") == key: return true
	return false

func slot_acum(key: String) -> float:
	return float((slot(key) as Dictionary).get("acum",0.0))

# ══════════════════════════════════════════════════════════════════════════════
#  CAPACIDADE ARMAZENAMENTO
# ══════════════════════════════════════════════════════════════════════════════
func cap_ouro() -> int:
	var v : int = 0
	for d in slots.values():
		var tp := (d as Dictionary).get("tipo","") as String
		var nv := int((d as Dictionary).get("nivel",1))
		var caps_arr : Array = []
		if tp == "deposito_ouro":   caps_arr = [1500, 3000, 6000]
		elif tp == "prefeitura":    caps_arr = [500,  1000, 2000]
		if caps_arr.size() > 0:
			v += int(caps_arr[clampi(nv-1,0,caps_arr.size()-1)])
	return maxi(v, 1000)

func cap_elixir() -> int:
	var v : int = 0
	for d in slots.values():
		var tp := (d as Dictionary).get("tipo","") as String
		var nv := int((d as Dictionary).get("nivel",1))
		var caps_arr : Array = []
		if tp == "deposito_elixir": caps_arr = [1500, 3000, 6000]
		elif tp == "prefeitura":    caps_arr = [500,  1000, 2000]
		if caps_arr.size() > 0:
			v += int(caps_arr[clampi(nv-1,0,caps_arr.size()-1)])
	return maxi(v, 1000)

func cap_escuro() -> int:
	var v : int = 0
	for d in slots.values():
		var tp := (d as Dictionary).get("tipo","") as String
		var nv := int((d as Dictionary).get("nivel",1))
		if tp == "deposito_escuro":
			var caps_arr : Array = [500, 1000, 2500]
			v += int(caps_arr[clampi(nv-1,0,caps_arr.size()-1)])
	return maxi(v, 100)

# ══════════════════════════════════════════════════════════════════════════════
#  CAPACIDADE DE TROPAS
# ══════════════════════════════════════════════════════════════════════════════
func cap_tropas_total() -> int:
	var v : int = 0
	for d in slots.values():
		var tp := (d as Dictionary).get("tipo","") as String
		var nv := int((d as Dictionary).get("nivel",1))
		if tp == "acampamento":
			var caps_arr : Array = [20, 40, 60]
			v += int(caps_arr[clampi(nv-1,0,caps_arr.size()-1)])
		elif tp == "castelo_cla":
			var caps_arr : Array = [10, 15, 25]
			v += int(caps_arr[clampi(nv-1,0,caps_arr.size()-1)])
	return v

func cap_tropas_usada() -> int:
	var v : int = 0
	for tipo in tropas.keys():
		var count : int = int(tropas[tipo])
		if count <= 0: continue
		var td := (_DADOS.TROPAS.get(tipo,{}) as Dictionary)
		v += int(td.get("cap",1)) * count
	return v

func cap_tropas_livre() -> int:
	return maxi(0, cap_tropas_total() - cap_tropas_usada())

# ══════════════════════════════════════════════════════════════════════════════
#  TICK — atualizar acúmulo de recursos (chamado por _process)
# ══════════════════════════════════════════════════════════════════════════════
func tick_recursos(delta: float) -> void:
	var agora_ms := Time.get_ticks_msec()
	var changed  := false
	for key in slots.keys():
		var d := slots[key] as Dictionary
		var tipo := d.get("tipo","") as String
		var nivel := int(d.get("nivel",1))
		var hp    := int(d.get("hp",0))
		if hp <= 0: continue
		var prod_arr : Array = []
		var cap_arr  : Array = []
		var rec_tipo := ""
		match tipo:
			"mina_ouro":
				prod_arr = [5,12,25]; cap_arr = [500,1000,2000]; rec_tipo = "ouro"
			"coletor_elixir":
				prod_arr = [5,12,25]; cap_arr = [500,1000,2000]; rec_tipo = "elixir"
			"mina_escura":
				prod_arr = [1,3,6]; cap_arr = [100,250,500]; rec_tipo = "escuro"
		if rec_tipo == "": continue
		var idx := clampi(nivel-1, 0, prod_arr.size()-1)
		var prod_por_segundo : float = float(int(prod_arr[idx])) / 60.0
		var cap_local        : int   = int(cap_arr[idx])
		var acum             : float = float(d.get("acum", 0.0))
		acum = minf(acum + prod_por_segundo * delta, float(cap_local))
		d["acum"] = acum
		slots[key] = d
		changed = true
	if changed: pass  # salvar() chamado externamente para não sobrecarregar I/O

# ══════════════════════════════════════════════════════════════════════════════
#  TICK — verificar construções concluídas
# ══════════════════════════════════════════════════════════════════════════════
func tick_construcoes() -> Array:
	## Retorna lista de tipos concluídos (para notificação na UI)
	var concluidos : Array = []
	var agora_ms := Time.get_ticks_msec()
	var remover  : Array = []
	for c in construcoes:
		var cd := c as Dictionary
		if agora_ms >= int(cd.get("fim_ms",0)):
			var key       := cd.get("key","") as String
			var tipo      := cd.get("tipo","") as String
			var nivel_alvo := int(cd.get("nivel_alvo",1))
			if slots.has(key):
				var d := slots[key] as Dictionary
				var dados_ef := _DADOS.EDIFICIOS.get(tipo,{}) as Dictionary
				var hp_arr := dados_ef.get("hp",[100,200,300]) as Array
				d["nivel"] = nivel_alvo
				d["hp"]    = int(hp_arr[clampi(nivel_alvo-1,0,hp_arr.size()-1)])
				slots[key] = d
			concluidos.append({"key":key,"tipo":tipo,"nivel":nivel_alvo})
			remover.append(c)
	for c in remover:
		construcoes.erase(c)
	if not remover.is_empty(): salvar()
	return concluidos

# ══════════════════════════════════════════════════════════════════════════════
#  TICK — verificar treino concluído
# ══════════════════════════════════════════════════════════════════════════════
func tick_treino() -> Array:
	## Retorna lista de tropas prontas (para notificação)
	var prontas : Array = []
	var agora_ms := Time.get_ticks_msec()
	for bk in fila_treino.keys():
		var fila := fila_treino[bk] as Array
		if fila.is_empty(): continue
		var item := fila[0] as Dictionary
		if agora_ms >= int(item.get("fim_ms",0)):
			var tipo := item.get("tipo","") as String
			tropas[tipo] = int(tropas.get(tipo,0)) + 1
			fila.remove_at(0)
			fila_treino[bk] = fila
			prontas.append(tipo)
			# Atualiza fim_ms do próximo na fila
			if not fila.is_empty():
				var tempo := int((_DADOS.TROPAS.get(tipo,{}) as Dictionary).get("tempo_treino_s",60)) * 1000
				(fila[0] as Dictionary)["fim_ms"] = agora_ms + tempo
	if not prontas.is_empty(): salvar()
	return prontas

# ══════════════════════════════════════════════════════════════════════════════
#  TICK — verificar pesquisa concluída
# ══════════════════════════════════════════════════════════════════════════════
func tick_pesquisa() -> Dictionary:
	if pesquisa.is_empty(): return {}
	var agora_ms := Time.get_ticks_msec()
	if agora_ms >= int(pesquisa.get("fim_ms",0)):
		var tipo       := pesquisa.get("tipo","") as String
		var nivel_alvo := int(pesquisa.get("nivel_alvo",1))
		niveis[tipo]   = nivel_alvo
		var resultado  := pesquisa.duplicate()
		pesquisa       = {}
		salvar()
		return resultado
	return {}

# ══════════════════════════════════════════════════════════════════════════════
#  COLETAR recurso de um edifício
# ══════════════════════════════════════════════════════════════════════════════
func coletar(key: String) -> int:
	var d := slots.get(key, {}) as Dictionary
	if d.is_empty(): return 0
	var tipo     := d.get("tipo","") as String
	var acum_f   := float(d.get("acum", 0.0))
	var acum_int := int(acum_f)
	if acum_int <= 0: return 0
	match tipo:
		"mina_ouro":
			var cap := cap_ouro()
			var add := mini(acum_int, cap - ouro)
			ouro += add; acum_int -= add
		"coletor_elixir":
			var cap := cap_elixir()
			var add := mini(acum_int, cap - elixir)
			elixir += add; acum_int -= add
		"mina_escura":
			var cap := cap_escuro()
			var add := mini(acum_int, cap - escuro)
			escuro += add; acum_int -= add
		_: return 0
	d["acum"] = float(acum_int)
	slots[key] = d
	salvar()
	return acum_int

# ══════════════════════════════════════════════════════════════════════════════
#  INICIALIZAÇÃO DA VILA (primeira vez)
# ══════════════════════════════════════════════════════════════════════════════
func init_vila_padrao() -> void:
	## Coloca Prefeitura no centro do grid isométrico 14×14 e recursos básicos
	if _tem_tipo("prefeitura"): return
	slots["7,7"]  = {"tipo":"prefeitura","nivel":1,"hp":500,"acum":0.0}
	slots["5,5"]  = {"tipo":"mina_ouro","nivel":1,"hp":200,"acum":0.0}
	slots["9,5"]  = {"tipo":"coletor_elixir","nivel":1,"hp":200,"acum":0.0}
	slots["5,9"]  = {"tipo":"deposito_ouro","nivel":1,"hp":400,"acum":0.0}
	slots["9,9"]  = {"tipo":"deposito_elixir","nivel":1,"hp":400,"acum":0.0}
	slots["7,5"]  = {"tipo":"quartel","nivel":1,"hp":250,"acum":0.0}
	slots["7,9"]  = {"tipo":"acampamento","nivel":1,"hp":250,"acum":0.0}
	salvar()

func _tem_tipo(tipo: String) -> bool:
	for d in slots.values():
		if (d as Dictionary).get("tipo","") == tipo: return true
	return false
