extends RefCounted
## Modulo do menu - tela de RANKING GLOBAL (Fase 1 da modularizacao).
## Estado da tela vive aqui; helpers compartilhados ficam no menu (acesso via m).
## Extraido de menu.gd em 2026-06-12 (tools/extrair_ranking.ps1).

var m  # menu principal (menu.gd)

func _init(menu) -> void:
	m = menu

var _ranking_overlay = null
var _ranking_panel = null
var _ranking_lista: Control = null
var _ranking_ts_lbl: Label = null
var _ranking_pos_lbl: Label = null
var _ranking_campeoes_cont: Control = null
var _ranking_carregando: bool = false


func limpar_refs() -> void:
	# Resize recria a UI inteira: solta as referencias sem queue_free
	_ranking_overlay = null
	_ranking_panel = null
	_ranking_lista = null
	_ranking_ts_lbl = null
	_ranking_pos_lbl = null
	_ranking_campeoes_cont = null


func _on_premio_temporada_aplicado(posicao: int, temporada: int, baus_lendarios: int, cristais_bonus: int) -> void:
	if not m._ui_main or not is_instance_valid(m._ui_main):
		return
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	var ov:= ColorRect.new()
	ov.color = Color(0.0, 0.0, 0.0, 0.72)
	ov.position = Vector2.ZERO
	ov.size = vp
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	m._ui_main.add_child(ov)

	var pw: float = minf(620.0, vp.x - 34.0)
	var ph: float = 300.0
	var pnl:= Panel.new()
	pnl.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	pnl.size = Vector2(pw, ph)
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(0.035, 0.025, 0.01, 0.98)
	sty.border_color = Color(1.0, 0.78, 0.12, 0.95)
	for s in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + s, 2)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + c, 12)
	pnl.add_theme_stylebox_override("panel", sty)
	ov.add_child(pnl)

	var tit:= Label.new()
	tit.text = "PREMIO DA TEMPORADA"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(20, 24)
	tit.size = Vector2(pw - 40, 40)
	tit.add_theme_font_size_override("font_size", 30)
	tit.add_theme_color_override("font_color", Color(1.0, 0.86, 0.18))
	pnl.add_child(tit)

	var msg:= Label.new()
	msg.text = "Você terminou a temporada %d em %dº lugar." % [temporada, posicao]
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.position = Vector2(30, 76)
	msg.size = Vector2(pw - 60, 30)
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	pnl.add_child(msg)

	var rec:= Label.new()
	rec.text = "+%d Bau%s Estelar%s    +%d cristais" % [
		baus_lendarios,
		"" if baus_lendarios == 1 else "s",
		"" if baus_lendarios == 1 else "es",
		cristais_bonus
	]
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rec.position = Vector2(28, 122)
	rec.size = Vector2(pw - 56, 44)
	rec.add_theme_font_size_override("font_size", 25)
	rec.add_theme_color_override("font_color", Color(1.0, 0.92, 0.36))
	pnl.add_child(rec)

	var sub:= Label.new()
	sub.text = "Recompensa enviada para sua mochila."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(36, 172)
	sub.size = Vector2(pw - 72, 28)
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.58, 0.72, 0.86))
	pnl.add_child(sub)

	var btn:= Button.new()
	btn.text = "CONTINUAR"
	btn.position = Vector2((pw - 230.0) * 0.5, ph - 72.0)
	btn.size = Vector2(230, 48)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 22)
	var bsty:= StyleBoxFlat.new()
	bsty.bg_color = Color(0.12, 0.1, 0.02, 0.95)
	bsty.border_color = Color(1.0, 0.82, 0.12, 0.95)
	for s2 in ["left", "right", "top", "bottom"]:
		bsty.set("border_width_" + s2, 2)
	for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		bsty.set("corner_radius_" + c2, 8)
	btn.add_theme_stylebox_override("normal", bsty)
	btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.26))
	btn.pressed.connect(func(): ov.queue_free())
	pnl.add_child(btn)


func _abrir_ranking(ui: CanvasLayer) -> void :
	if _ranking_overlay:
		return
	if m._menu_contents:
		m._menu_contents.hide()

	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	var VW: float = vp.x
	var VH: float = vp.y


	var bg:= ColorRect.new()
	bg.color = Color(0.01, 0.012, 0.024, 0.985)
	bg.position = Vector2.ZERO
	bg.size = vp
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(bg)
	_ranking_overlay = bg
	_ranking_panel = bg


	var tit:= Label.new()
	tit.text = "RANKING GLOBAL"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tit.position = Vector2(24, 10)
	tit.size = Vector2(VW * 0.55, 46)
	tit.add_theme_font_size_override("font_size", 34)
	tit.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	m._ui_title_label(tit, 3.0)
	tit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(tit)

	var sub:= Label.new()
	sub.text = "BETA TEMPORADA %d  |  FINALIZA EM %s  |  MAIOR WAVE ALCANCADA" % [
		RankingOnline.temporada_display_numero(),
		_ranking_tempo_temporada_texto()
	]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sub.position = Vector2(28, 44)
	sub.size = Vector2(VW * 0.76, 26)
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.38, 0.86, 1.0, 0.82))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sub)


	var ts_lbl:= Label.new()
	ts_lbl.name = "TimestampLbl"
	ts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ts_lbl.position = Vector2(VW - 430, 14)
	ts_lbl.size = Vector2(406, 24)
	ts_lbl.add_theme_font_size_override("font_size", 13)
	ts_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7, 0.8))
	ts_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(ts_lbl)
	_ranking_ts_lbl = ts_lbl

	var sep:= ColorRect.new()
	sep.color = Color(1.0, 0.78, 0.1, 0.28)
	sep.position = Vector2(20, 78)
	sep.size = Vector2(VW - 40, 2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sep)


	var sep2:= ColorRect.new()
	sep2.color = Color(1.0, 0.78, 0.1, 0.18)
	sep2.position = Vector2(20, 90)
	sep2.size = Vector2(VW - 40, 2)
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sep2)

	var premio_lbl:= Label.new()
	premio_lbl.text = "PRÊMIOS TOP 3: TOP 1 - 3x Baú Estelar + 300 cristais   |   TOP 2 - 2x Baú Estelar + 180 cristais   |   TOP 3 - 1x Baú Estelar + 100 cristais"
	premio_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	premio_lbl.position = Vector2(26, 94)
	premio_lbl.size = Vector2(VW - 52, 22)
	premio_lbl.add_theme_font_size_override("font_size", 14)
	premio_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.28, 0.86))
	premio_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(premio_lbl)

	var campeoes_cont:= Control.new()
	campeoes_cont.name = "CampeoesTemporadaAnterior"
	campeoes_cont.position = Vector2(28, 116)
	campeoes_cont.size = Vector2(VW - 56, 26)
	campeoes_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(campeoes_cont)
	_ranking_campeoes_cont = campeoes_cont
	_render_campeoes_temporada_anterior(-1, [])


	var podio_ctrl:= Control.new()
	podio_ctrl.position = Vector2(0, 142)
	podio_ctrl.size = Vector2(VW, 222)
	podio_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	podio_ctrl.set_meta("podio", true)
	podio_ctrl.set_meta("entries", [])
	podio_ctrl.set_meta("ctrl_w", VW)
	podio_ctrl.draw.connect( func(): _draw_podio(podio_ctrl, podio_ctrl.get_meta("entries", [])))
	bg.add_child(podio_ctrl)

	var sep3:= ColorRect.new()
	sep3.color = Color(1.0, 0.78, 0.1, 0.18)
	sep3.position = Vector2(20, 370)
	sep3.size = Vector2(VW - 40, 2)
	sep3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sep3)


	var hdr_pos:= Label.new()
	hdr_pos.text = "#"
	hdr_pos.position = Vector2(28, 376)
	hdr_pos.size = Vector2(58, 28)
	hdr_pos.add_theme_font_size_override("font_size", 17)
	hdr_pos.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	hdr_pos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(hdr_pos)

	var hdr_nome:= Label.new()
	hdr_nome.text = "NOME"
	hdr_nome.position = Vector2(96, 376)
	hdr_nome.size = Vector2(560, 28)
	hdr_nome.add_theme_font_size_override("font_size", 17)
	hdr_nome.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	hdr_nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(hdr_nome)

	var hdr_wave:= Label.new()
	hdr_wave.text = "WAVE"
	hdr_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr_wave.position = Vector2(680, 376)
	hdr_wave.size = Vector2(240, 28)
	hdr_wave.add_theme_font_size_override("font_size", 17)
	hdr_wave.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	hdr_wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(hdr_wave)

	var hdr_score:= Label.new()
	hdr_score.text = "SCORE"
	hdr_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hdr_score.position = Vector2(940, 376)
	hdr_score.size = Vector2(VW - 960, 28)
	hdr_score.add_theme_font_size_override("font_size", 17)
	hdr_score.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	hdr_score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(hdr_score)

	var sep4:= ColorRect.new()
	sep4.color = Color(0.55, 0.65, 0.75, 0.15)
	sep4.position = Vector2(20, 406)
	sep4.size = Vector2(VW - 40, 2)
	sep4.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sep4)


	for gi in range(4, 0, -1):
		var g_rect:= ColorRect.new()
		g_rect.color = Color(1.0, 0.78, 0.1, 0.04 / float(gi))
		g_rect.position = Vector2(0, float(gi) - 1)
		g_rect.size = Vector2(VW, 3)
		g_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(g_rect)
	var neon_top:= ColorRect.new()
	neon_top.color = Color(1.0, 0.85, 0.15, 0.7)
	neon_top.position = Vector2(0, 0)
	neon_top.size = Vector2(VW, 2)
	neon_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(neon_top)



	var scroll:= ScrollContainer.new()
	scroll.position = Vector2(20, 410)
	scroll.size = Vector2(VW - 40, VH - 410 - 56)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.add_child(scroll)

	var lista_cont:= VBoxContainer.new()
	lista_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista_cont.add_theme_constant_override("separation", 2)
	lista_cont.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(lista_cont)
	_ranking_lista = lista_cont

	var load_lbl:= Label.new()
	load_lbl.name = "LoadLabel"
	load_lbl.text = "Carregando ranking..."
	load_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_lbl.add_theme_font_size_override("font_size", 22)
	load_lbl.add_theme_color_override("font_color", Color(0.5, 0.65, 0.8))
	lista_cont.add_child(load_lbl)


	var pos_lbl:= Label.new()
	pos_lbl.name = "PosicaoJogador"
	pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pos_lbl.position = Vector2(20, VH - 46)
	pos_lbl.size = Vector2(400, 38)
	pos_lbl.add_theme_font_size_override("font_size", 15)
	pos_lbl.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0, 0.8))
	pos_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(pos_lbl)
	_ranking_pos_lbl = pos_lbl


	var btn_f:= Button.new()
	btn_f.text = "FECHAR"
	btn_f.position = Vector2((VW - 220) * 0.5, VH - 50)
	btn_f.size = Vector2(220, 46)
	btn_f.focus_mode = Control.FOCUS_NONE
	btn_f.add_theme_font_size_override("font_size", 22)
	var sty_f:= StyleBoxFlat.new()
	sty_f.bg_color = Color(0.08, 0.08, 0.05, 0.95)
	sty_f.border_color = Color(1.0, 0.78, 0.1, 0.85)
	for side in ["left", "right", "top", "bottom"]:
		sty_f.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_f.set("corner_radius_" + corner, 8)
	btn_f.add_theme_stylebox_override("normal", sty_f)
	var sty_fh: StyleBoxFlat = sty_f.duplicate()
	sty_fh.bg_color = Color(0.18, 0.14, 0.02, 0.98)
	sty_fh.border_color = Color(1.0, 0.95, 0.3, 1.0)
	btn_f.add_theme_stylebox_override("hover", sty_fh)
	btn_f.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	btn_f.pressed.connect(_fechar_ranking)
	bg.add_child(btn_f)

	if Salvar.nome_jogador.strip_edges().to_upper() == "BOSS QUEIXO":
		var btn_adm:= Button.new()
		btn_adm.text = "ADMIN: FORCAR SYNC"
		btn_adm.position = Vector2(20, VH - 50)
		btn_adm.size = Vector2(340, 46)
		btn_adm.focus_mode = Control.FOCUS_NONE
		btn_adm.add_theme_font_size_override("font_size", 18)
		var sty_adm:= StyleBoxFlat.new()
		sty_adm.bg_color = Color(0.18, 0.06, 0.02, 0.95)
		sty_adm.border_color = Color(1.0, 0.45, 0.1, 0.85)
		for s in ["left", "right", "top", "bottom"]: sty_adm.set("border_width_" + s, 2)
		for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_adm.set("corner_radius_" + c2, 6)
		btn_adm.add_theme_stylebox_override("normal", sty_adm)
		btn_adm.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
		btn_adm.pressed.connect( func() -> void :
			RankingOnline.envio_inicial()
			_ranking_carregando = false
			_carregar_ranking()
			btn_adm.text = "Sincronizando..."
			btn_adm.disabled = true
			await m.get_tree().create_timer(4.0).timeout
			if btn_adm and is_instance_valid(btn_adm):
				btn_adm.text = "ADMIN: FORCAR SYNC"
				btn_adm.disabled = false
		)
		bg.add_child(btn_adm)


	if not RankingOnline.ranking_carregado.is_connected(_on_ranking_carregado):
		RankingOnline.ranking_carregado.connect(_on_ranking_carregado)
	if not RankingOnline.campeoes_temporada_anterior_carregados.is_connected(_on_campeoes_temporada_anterior_carregados):
		RankingOnline.campeoes_temporada_anterior_carregados.connect(_on_campeoes_temporada_anterior_carregados)


	if Salvar.nome_jogador.strip_edges() == "":
		var banner:= Panel.new()
		banner.name = "BannerSemNome"
		banner.position = Vector2(20, 344)
		banner.size = Vector2(VW - 40, 76)
		banner.z_index = 2
		var sty_b:= StyleBoxFlat.new()
		sty_b.bg_color = Color(0.1, 0.07, 0.02, 0.97)
		sty_b.border_color = Color(1.0, 0.78, 0.1, 0.8)
		for s in ["left", "right", "top", "bottom"]: sty_b.set("border_width_" + s, 1)
		for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_b.set("corner_radius_" + c2, 8)
		banner.add_theme_stylebox_override("panel", sty_b)
		bg.add_child(banner)

		var lban:= Label.new()
		lban.text = "Voce ainda nao definiu seu nome — configure no perfil para aparecer no ranking!"
		lban.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lban.autowrap_mode = TextServer.AUTOWRAP_WORD
		lban.position = Vector2(10, 5)
		lban.size = Vector2(VW - 280, 66)
		lban.add_theme_font_size_override("font_size", 19)
		lban.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
		banner.add_child(lban)

		var btn_ir:= Button.new()
		btn_ir.text = "IR AO PERFIL"
		btn_ir.position = Vector2(VW - 268, 8)
		btn_ir.size = Vector2(240, 58)
		btn_ir.focus_mode = Control.FOCUS_NONE
		btn_ir.add_theme_font_size_override("font_size", 18)
		var sty_ir:= StyleBoxFlat.new()
		sty_ir.bg_color = Color(0.18, 0.12, 0.02, 0.95)
		sty_ir.border_color = Color(1.0, 0.78, 0.1, 1.0)
		for s in ["left", "right", "top", "bottom"]: sty_ir.set("border_width_" + s, 2)
		for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_ir.set("corner_radius_" + c2, 6)
		btn_ir.add_theme_stylebox_override("normal", sty_ir)
		btn_ir.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		btn_ir.pressed.connect( func():
			_fechar_ranking()
			m._abrir_perfil(m._ui_main)
		)
		banner.add_child(btn_ir)

	_carregar_ranking()


func _fechar_ranking() -> void :
	if _ranking_overlay and is_instance_valid(_ranking_overlay):
		_ranking_overlay.queue_free()
	_ranking_overlay = null
	_ranking_panel = null
	_ranking_lista = null
	_ranking_ts_lbl = null
	_ranking_pos_lbl = null
	_ranking_campeoes_cont = null
	if m._menu_contents:
		m._menu_contents.show()


func _carregar_ranking() -> void :
	if _ranking_carregando:
		return
	_ranking_carregando = true


	var estimado: Array = RankingOnline.get_lista_estimada()
	_popular_lista(estimado, true)


	_atualizar_timestamp(true)


	RankingOnline.buscar_ranking()
	RankingOnline.buscar_campeoes_temporada_anterior()


func _atualizar_timestamp(estimado: bool) -> void :
	if not _ranking_ts_lbl or not is_instance_valid(_ranking_ts_lbl):
		return
	var seg: int = RankingOnline.segundos_desde_atualizacao()
	if seg < 0:
		_ranking_ts_lbl.text = "Sem dados em cache — sincronizando..."
	elif estimado:
		if seg < 60:
			_ranking_ts_lbl.text = "Estimado · atualizado há menos de 1 min"
		elif seg < 3600:
			_ranking_ts_lbl.text = "Estimado · atualizado há %d min" % (seg / 60)
		else:
			_ranking_ts_lbl.text = "Estimado · atualizado há %dh" % (seg / 3600)
	else:
		_ranking_ts_lbl.text = "Dados reais do servidor"


func _ranking_tempo_temporada_texto() -> String:
	var seg: int = RankingOnline.segundos_para_fim_temporada()
	var dias: int = seg / 86400
	var horas: int = (seg % 86400) / 3600
	var mins: int = (seg % 3600) / 60
	if dias > 0:
		return "%dd %dh" % [dias, horas]
	if horas > 0:
		return "%dh %dmin" % [horas, mins]
	return "%dmin" % maxi(1, mins)


func _on_ranking_carregado(entradas: Array) -> void :
	_ranking_carregando = false
	if not _ranking_panel or not is_instance_valid(_ranking_panel):
		return
	if not _ranking_lista or not is_instance_valid(_ranking_lista):
		return
	_popular_lista(entradas, false)
	_atualizar_timestamp(false)


func _on_campeoes_temporada_anterior_carregados(temporada: int, entradas: Array) -> void :
	_render_campeoes_temporada_anterior(temporada, entradas)


func _render_campeoes_temporada_anterior(temporada: int, entradas: Array) -> void :
	if not _ranking_campeoes_cont or not is_instance_valid(_ranking_campeoes_cont):
		return
	for ch in _ranking_campeoes_cont.get_children():
		ch.queue_free()
	var cont: Control = _ranking_campeoes_cont
	cont.visible = true
	if not cont.draw.is_connected(_draw_ranking_campeoes_faixa):
		cont.draw.connect(_draw_ranking_campeoes_faixa)
	cont.queue_redraw()

	var titulo:= Label.new()
	titulo.text = "CAMPEOES TEMP. %s" % (str(temporada + 1) if temporada >= 0 else "ANTERIOR")
	titulo.position = Vector2(10, 1)
	titulo.size = Vector2(190, 24)
	titulo.add_theme_font_size_override("font_size", 12)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.86, 0.22, 0.95))
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(titulo)

	if temporada < 0 or entradas.is_empty():
		var vazio:= Label.new()
		vazio.text = "Nenhuma temporada encerrada ainda."
		vazio.position = Vector2(210, 1)
		vazio.size = Vector2(cont.size.x - 220, 24)
		vazio.add_theme_font_size_override("font_size", 12)
		vazio.add_theme_color_override("font_color", Color(0.60, 0.70, 0.82, 0.82))
		vazio.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cont.add_child(vazio)
		return

	var card_w: float = maxf(210.0, (cont.size.x - 220.0) / 3.0 - 8.0)
	for i in range(mini(3, entradas.size())):
		var e: Dictionary = entradas[i] as Dictionary
		var nome: String = str(e.get("nome", "?")).strip_edges()
		if nome == "":
			nome = "?"
		if nome.length() > 16:
			nome = nome.left(15) + "."
		var wave: int = int(e.get("wave", 0))
		var score: int = int(e.get("score", 0))
		var premio: Dictionary = RankingOnline.premio_temporada_info(i + 1)
		var baus: int = int(premio.get("baus_lendarios", 0))
		var cristais: int = int(premio.get("cristais", 0))
		var lbl:= Label.new()
		lbl.text = "TOP %d  %s  W%d  %s pts  %dx Bau + %d C" % [i + 1, nome, wave, m._format_num(score), baus, cristais]
		lbl.position = Vector2(206.0 + float(i) * (card_w + 8.0), 2)
		lbl.size = Vector2(card_w, 22)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.34, 0.95) if i == 0 else Color(0.86, 0.92, 1.0, 0.90))
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cont.add_child(lbl)


func _draw_ranking_campeoes_faixa() -> void:
	if not _ranking_campeoes_cont or not is_instance_valid(_ranking_campeoes_cont):
		return
	var cont: Control = _ranking_campeoes_cont
	var r := Rect2(Vector2.ZERO, cont.size)
	cont.draw_rect(r, Color(0.05, 0.04, 0.012, 0.72), true)
	cont.draw_rect(r, Color(1.0, 0.78, 0.16, 0.28), false, 1.0)
	cont.draw_line(Vector2(12, 2), Vector2(80, 2), Color(1.0, 0.86, 0.22, 0.45), 1.0)
	cont.draw_line(Vector2(cont.size.x - 80, cont.size.y - 2), Vector2(cont.size.x - 12, cont.size.y - 2), Color(1.0, 0.86, 0.22, 0.32), 1.0)


func _popular_lista(entradas: Array, is_estimado: bool) -> void :
	if not _ranking_lista or not is_instance_valid(_ranking_lista):
		return
	for ch in _ranking_lista.get_children():
		ch.queue_free()
	entradas = entradas.duplicate(true)
	entradas.sort_custom(func(a, b):
		var da: Dictionary = a as Dictionary
		var db: Dictionary = b as Dictionary
		var wa: int = int(da.get("wave", 0))
		var wb: int = int(db.get("wave", 0))
		if wa == wb:
			return int(da.get("score", 0)) > int(db.get("score", 0))
		return wa > wb
	)
	var _vw: float = m.get_viewport().get_visible_rect().size.x
	var _row_w: float = _vw - 40.0


	var _nome_local:= Salvar.nome_jogador.strip_edges()
	var entradas_podio:= entradas.duplicate(true)
	for _ep in range(entradas_podio.size()):
		var _ed: Dictionary = entradas_podio[_ep] as Dictionary
		var _en: String = str(_ed.get("nome", "")).strip_edges()
		var _el: bool = _ed.get("local", false) as bool
		if _el or (_nome_local != "" and _en == _nome_local):
			_ed["avatar_idx"] = Salvar.avatar_idx
			entradas_podio[_ep] = _ed


	if _ranking_panel and is_instance_valid(_ranking_panel):
		for ch in _ranking_panel.get_children():
			if ch.get_meta("podio", false):
				(ch as Control).set_meta("entries", entradas_podio)
				(ch as Control).queue_redraw()
				break

	if entradas.is_empty():
		var vazio:= Label.new()
		vazio.text = "Nenhum recorde por wave registrado ainda."
		vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vazio.add_theme_font_size_override("font_size", 22)
		vazio.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		_ranking_lista.add_child(vazio)
		return

	var nome_local: String = Salvar.nome_jogador.strip_edges()


	if _ranking_pos_lbl and is_instance_valid(_ranking_pos_lbl) and nome_local != "":
		var pos_jogador: int = -1
		for pi in range(entradas.size()):
			var pe: Dictionary = entradas[pi] as Dictionary
			var pn: String = pe.get("nome", "") as String
			var pe_local: bool = pe.get("local", false) as bool
			if pe_local or (pn == nome_local):
				pos_jogador = pi + 1
				break
		if pos_jogador > 0:
			_ranking_pos_lbl.text = "Sua posição: %dº lugar" % pos_jogador
		else:
			_ranking_pos_lbl.text = "Voce nao esta no top %d ainda" % entradas.size()

	for i in range(entradas.size()):
		var e: Dictionary = entradas[i] as Dictionary
		var nome: String = e.get("nome", "???") as String
		var scr: int = int(e.get("score", 0))
		var wave: int = int(e.get("wave", 0))
		var pos: int = i + 1
		var e_local: bool = e.get("local", false) as bool
		var e_voce: bool = e_local or (nome_local != "" and nome == nome_local)

		var row:= Control.new()
		row.custom_minimum_size = Vector2(_row_w, 44)
		row.mouse_filter = Control.MOUSE_FILTER_PASS


		var row_bg:= ColorRect.new()
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_bg.size = Vector2(_row_w, 44)
		if e_voce:
			row_bg.color = Color(0.1, 0.6, 1.0, 0.13)
		elif pos == 1:
			row_bg.color = Color(1.0, 0.82, 0.0, 0.1)
		elif pos == 2:
			row_bg.color = Color(0.75, 0.75, 0.75, 0.07)
		elif pos == 3:
			row_bg.color = Color(0.72, 0.38, 0.1, 0.1)
		elif i % 2 == 0:
			row_bg.color = Color(1.0, 1.0, 1.0, 0.03)
		else:
			row_bg.color = Color(0.0, 0.0, 0.0, 0.0)
		row.add_child(row_bg)


		var medal_txt: String
		var medal_cor: Color
		match pos:
			1: medal_txt = "1.";medal_cor = Color(1.0, 0.85, 0.1)
			2: medal_txt = "2.";medal_cor = Color(0.82, 0.82, 0.82)
			3: medal_txt = "3.";medal_cor = Color(0.8, 0.5, 0.2)
			_: medal_txt = str(pos);medal_cor = Color(0.5, 0.6, 0.7)

		var lbl_pos:= Label.new()
		lbl_pos.text = medal_txt
		lbl_pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_pos.position = Vector2(0, 0)
		lbl_pos.size = Vector2(66, 44)
		lbl_pos.add_theme_font_size_override("font_size", 20)
		lbl_pos.add_theme_color_override("font_color", medal_cor)
		lbl_pos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl_pos)


		var _asc: int = int(e.get("ascensoes", 0))
		var _nivel_asc: int = m._nivel_prestigio(_asc)

		var _row_av_idx: int = -1
		if e_voce:
			_row_av_idx = Salvar.avatar_idx
		else:
			var _rv = e.get("avatar_idx", null)
			if _rv != null:
				var _rvt:= typeof(_rv)
				if _rvt == TYPE_INT or _rvt == TYPE_FLOAT:
					var _rvi:= int(_rv)
					if _rvi >= 0 and _rvi < 5:
						_row_av_idx = _rvi
		if _row_av_idx >= 0:
			var av_ctrl:= Control.new()
			av_ctrl.position = Vector2(66, 4)
			av_ctrl.size = Vector2(36, 36)
			av_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var _cap_av     := _row_av_idx
			var _cap_niv_av := _nivel_asc
			av_ctrl.draw.connect(func():
				var _acor_av : Color = (m._AVATAR_CORES[_cap_av] if _cap_av < m._AVATAR_CORES.size() else Color(0.6, 0.6, 0.6))
				if _cap_niv_av > 0:
					var _ptex_row: Texture2D = m._carregar_simbolo_prestigio(_cap_niv_av)
					const _MAR_R : float = 9.0
					if _ptex_row != null:
						av_ctrl.draw_texture_rect(_ptex_row,
							Rect2(-_MAR_R, -_MAR_R, 36.0 + _MAR_R * 2.0, 36.0 + _MAR_R * 2.0),
							false, Color(1.0, 1.0, 1.0, 0.94))
					av_ctrl.draw_circle(Vector2(18, 18), 14.0, Color(0.04, 0.06, 0.12, 1.0))
				else:
					av_ctrl.draw_circle(Vector2(18, 18), 14.0, Color(0.04, 0.06, 0.12, 0.97))
					av_ctrl.draw_arc(Vector2(18, 18), 14.0, 0.0, TAU, 32,
						_acor_av * (Color(1, 1, 1, 0.85) if e_voce else Color(0.7, 0.7, 0.7, 0.7)), 1.5)
				m._draw_avatar_icone(av_ctrl, 18.0, 18.0, 11.0, _cap_av))
			row.add_child(av_ctrl)


		var nome_x: float = 108.0 if _row_av_idx >= 0 else 76.0

		# ── Badge de prestigio: rente ao nome + contador colorido ────────────
		const BADGE_SZ := 34.0
		const NOME_FONT_SZ := 20

		var _nome_max_w: float = (448.0 if e_voce else 548.0) if _row_av_idx >= 0 else (480.0 if e_voce else 580.0)
		var _font_r: Font = ThemeDB.fallback_font
		var _nome_txt_w: float = _font_r.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, NOME_FONT_SZ).x if _font_r != null else 120.0

		# Badge de prestigio fica DEPOIS do nome com margem — nome nao eh cortado
		const BADGE_SZ2 := 44.0
		const BADGE_MARGEM := 6.0   # espaco entre fim do nome e o badge
		var _nome_w_real : float = minf(_nome_txt_w + 4.0, _nome_max_w - (BADGE_SZ2 + BADGE_MARGEM + 2.0) if _nivel_asc > 0 else _nome_max_w)

		var lbl_nome:= Label.new()
		lbl_nome.text = nome
		lbl_nome.position = Vector2(nome_x, 0)
		lbl_nome.size = Vector2(_nome_w_real, 44)
		lbl_nome.add_theme_font_size_override("font_size", NOME_FONT_SZ)
		lbl_nome.add_theme_color_override("font_color",
			Color(0.4, 0.85, 1.0) if e_voce else
			(Color(1.0, 0.95, 0.7) if pos <= 3 else Color(0.78, 0.88, 1.0)))
		lbl_nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl_nome)

		if _nivel_asc > 0:
			var _ptex: Texture2D = m._carregar_simbolo_prestigio(_nivel_asc)
			var _badge_x: float = nome_x + _nome_w_real + BADGE_MARGEM

			# Cores exatas do sistema de baus do jogo
			var _num_cor : Color
			var _cor_base: Color
			var _cor_luz : Color
			match _nivel_asc:
				1, 2:
					_num_cor  = Color(0.72, 0.92, 1.0)
					_cor_base = Color(0.55, 0.64, 0.78)
					_cor_luz  = Color(0.72, 0.92, 1.0)
				3, 4:
					_num_cor  = Color(0.40, 0.95, 1.0)
					_cor_base = Color(0.22, 0.72, 1.0)
					_cor_luz  = Color(0.40, 0.95, 1.0)
				5, 6:
					_num_cor  = Color(1.0,  0.45, 1.0)
					_cor_base = Color(0.78, 0.25, 1.0)
					_cor_luz  = Color(1.0,  0.45, 1.0)
				_:  # 7 e 8 — lendario
					_num_cor  = Color(1.0,  0.92, 0.35)
					_cor_base = Color(1.0,  0.70, 0.12)
					_cor_luz  = Color(1.0,  0.92, 0.35)

			var _pbadge := Control.new()
			_pbadge.position = Vector2(_badge_x, (44.0 - BADGE_SZ2) * 0.5)
			_pbadge.size = Vector2(BADGE_SZ2, BADGE_SZ2)
			_pbadge.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var _cap_tx   := _ptex
			var _cap_asc  := _asc
			var _cap_niv  := _nivel_asc
			var _cap_ncor := _num_cor
			var _cap_cb   := _cor_base
			var _cap_cl   := _cor_luz

			_pbadge.draw.connect(func():
				var _t   : float = float(Time.get_ticks_msec()) / 1000.0
				var _ctr := Vector2(BADGE_SZ2 * 0.5, BADGE_SZ2 * 0.5)

				# ── Fragmentos de cristal flutuando ao redor do badge ─────────
				# Quantidade cresce com nivel: 3 (comum) ate 10 (lendario max)
				var _nf      : int   = 2 + _cap_niv
				var _orb     : float = BADGE_SZ2 * 0.35   # raio proximo ao badge
				var _spd     : float = 0.25 + float(_cap_niv) * 0.04
				var _max_r   : float = BADGE_SZ2 * 0.40   # fragmentos nao passam daqui

				for _fi in _nf:
					var _seed   : float = float(_fi) * 1.618
					var _ang    : float = _t * _spd * TAU + (TAU / float(_nf)) * float(_fi)
					var _drift  : float = sin(_t * 1.2 + _seed * 2.3) * BADGE_SZ2 * 0.04
					var _r      : float = _orb + _drift
					var _pos    := _ctr + Vector2(cos(_ang), sin(_ang)) * _r

					# Garante que fragmento nao sai dos limites do badge
					if (_pos - _ctr).length() > _max_r:
						continue

					var _pulse  : float = (sin(_t * 1.8 + _seed * 1.7) + 1.0) * 0.5
					var _sz     : float = 1.5 + _pulse * 1.8   # 1.5 a 3.3 px
					var _alpha  : float = 0.35 + _pulse * 0.55

					var _fc := Color(_cap_cb.r, _cap_cb.g, _cap_cb.b, _alpha)
					var _fl := Color(_cap_cl.r, _cap_cl.g, _cap_cl.b, _alpha * 0.6)

					_pbadge.draw_circle(_pos, _sz, _fc)
					_pbadge.draw_circle(_pos + Vector2(0, -_sz * 0.5), _sz * 0.4, _fl)

					# Trilha curta
					for _tr in 2:
						var _ta  : float = _ang - (_tr + 1) * 0.10
						var _tp  := _ctr + Vector2(cos(_ta), sin(_ta)) * _r
						if (_tp - _ctr).length() > _max_r:
							continue
						var _tfa : float = _alpha * (0.28 - float(_tr) * 0.10)
						if _tfa > 0.0:
							_pbadge.draw_circle(_tp, _sz * (0.55 - float(_tr) * 0.15),
								Color(_cap_cb.r, _cap_cb.g, _cap_cb.b, _tfa))

				# ── Imagem do badge (sobre os fragmentos) ─────────────────────
				if _cap_tx != null:
					_pbadge.draw_texture_rect(_cap_tx, Rect2(Vector2.ZERO, Vector2(BADGE_SZ2, BADGE_SZ2)), false)
				else:
					_pbadge.draw_circle(_ctr, BADGE_SZ2 * 0.40, Color(0.08, 0.06, 0.14, 0.92))

				# ── Numero no centro ──────────────────────────────────────────
				var _font := ThemeDB.fallback_font
				if _font:
					var _txt := str(_cap_asc)
					var _fs  : int = 13 if _cap_asc >= 100 else 15
					var _tw  : float = _font.get_string_size(_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs).x
					var _px  : float = _ctr.x - _tw * 0.5
					var _py  : float = _ctr.y + _fs * 0.36
					_pbadge.draw_string(_font, Vector2(_px + 1.0, _py + 1.0), _txt,
						HORIZONTAL_ALIGNMENT_LEFT, -1, _fs, Color(0, 0, 0, 0.80))
					_pbadge.draw_string(_font, Vector2(_px, _py), _txt,
						HORIZONTAL_ALIGNMENT_LEFT, -1, _fs, _cap_ncor))

			var _tmr := Timer.new()
			_tmr.wait_time = 0.05
			_tmr.autostart = true
			_tmr.timeout.connect(func(): if is_instance_valid(_pbadge): _pbadge.queue_redraw())
			_pbadge.add_child(_tmr)
			row.add_child(_pbadge)

		if e_voce:
			var badge:= Label.new()
			badge.text = "VOCE *" if is_estimado else "VOCE"
			badge.position = Vector2(566, 6)
			badge.size = Vector2(110, 32)
			badge.add_theme_font_size_override("font_size", 15)
			badge.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0, 0.95))
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(badge)

		var lbl_wave:= Label.new()
		lbl_wave.text = "Wave  %d" % wave
		lbl_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_wave.position = Vector2(686, 0)
		lbl_wave.size = Vector2(240, 44)
		lbl_wave.add_theme_font_size_override("font_size", 20)
		lbl_wave.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 0.9))
		lbl_wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl_wave)

		var lbl_score:= Label.new()
		lbl_score.text = m._format_num(scr)
		lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_score.position = Vector2(940, 0)
		lbl_score.size = Vector2(_row_w - 952, 44)
		lbl_score.add_theme_font_size_override("font_size", 20)
		lbl_score.add_theme_color_override("font_color", 
			Color(0.25, 1.0, 0.62) if pos <= 3 else Color(0.62, 0.95, 1.0))
		lbl_score.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl_score)

		_ranking_lista.add_child(row)


func _draw_podio(ctrl: Control, entradas: Array) -> void :
	const COR_OURO:= Color(1.0, 0.82, 0.05)
	const COR_PRATA:= Color(0.78, 0.82, 0.9)
	const COR_BRONZE:= Color(0.85, 0.52, 0.22)

	var CW: float = ctrl.get_meta("ctrl_w", 1000.0)
	var BASE_Y: float = ctrl.size.y - 8.0
	var cx: float = CW * 0.5


	var podio_dados:= [
		{"idx": 1, "x": cx - 255.0, "h": 68.0, "dw": 200.0, "cor": COR_PRATA, "label": "2º"}, 
		{"idx": 0, "x": cx, "h": 100.0, "dw": 230.0, "cor": COR_OURO, "label": "1º"}, 
		{"idx": 2, "x": cx + 255.0, "h": 50.0, "dw": 190.0, "cor": COR_BRONZE, "label": "3º"}, 
	]


	var palco_x: float = cx - 460.0
	ctrl.draw_rect(Rect2(palco_x, BASE_Y, 920, 8), Color(1.0, 0.78, 0.1, 0.18))
	ctrl.draw_rect(Rect2(palco_x, BASE_Y + 8, 920, 4), Color(1.0, 0.78, 0.1, 0.07))

	for pd in podio_dados:
		var idx: int = pd["idx"] as int
		var px: float = pd["x"] as float
		var ph: float = pd["h"] as float
		var dw: float = pd["dw"] as float
		var pcor: Color = pd["cor"] as Color
		var plbl: String = pd["label"] as String
		var dx: float = px - dw * 0.5

		if idx >= entradas.size():
			ctrl.draw_rect(Rect2(dx, BASE_Y - ph, dw, ph), 
				Color(pcor.r * 0.05, pcor.g * 0.05, pcor.b * 0.05, 0.65))
			ctrl.draw_rect(Rect2(dx, BASE_Y - ph, dw, ph), 
				Color(pcor.r * 0.2, pcor.g * 0.2, pcor.b * 0.2, 0.3), false, 1.5)
			m._draw_text_centered(ctrl, "—", Vector2(px, BASE_Y - ph * 0.5 + 6.0), 
				14, Color(pcor.r * 0.4, pcor.g * 0.4, pcor.b * 0.4, 0.4))
			continue

		var e: Dictionary = entradas[idx] as Dictionary
		var nome: String = (e.get("nome", "???") as String).left(14)
		var scr: int = int(e.get("score", 0))
		var wave: int = int(e.get("wave", 0))


		var glow_steps: int = 7 if idx == 0 else 4
		var glow_alpha: float = 0.038 if idx == 0 else 0.022
		for gi in range(glow_steps, 0, -1):
			var spread: float = float(gi) * 2.2
			ctrl.draw_rect(
				Rect2(dx - spread, BASE_Y - ph - spread, dw + spread * 2.0, ph + spread), 
				Color(pcor.r, pcor.g, pcor.b, glow_alpha / float(gi)))


		var stripes: int = 12
		for si in range(stripes):
			var sy: float = BASE_Y - ph + float(si) * ph / float(stripes)
			var sh: float = ph / float(stripes) + 1.0
			var t: float = float(si) / float(stripes - 1)
			var bright: float
			if t < 0.25:
				bright = lerp(0.5, 0.12, t / 0.25)
			elif t < 0.75:
				bright = lerp(0.12, 0.07, (t - 0.25) / 0.5)
			else:
				bright = lerp(0.07, 0.16, (t - 0.75) / 0.25)
			ctrl.draw_rect(Rect2(dx, sy, dw, sh), 
				Color(pcor.r * bright, pcor.g * bright, pcor.b * bright, 0.97))


		ctrl.draw_line(Vector2(dx + 5, BASE_Y - ph + 6), 
			Vector2(dx + 5, BASE_Y - 6), 
			Color(pcor.r, pcor.g, pcor.b, 0.26), 2.5)
		ctrl.draw_line(Vector2(dx + 13, BASE_Y - ph + 10), 
			Vector2(dx + 13, BASE_Y - ph + ph * 0.38), 
			Color(1.0, 1.0, 1.0, 0.1), 1.5)


		ctrl.draw_rect(Rect2(dx, BASE_Y - ph, dw, ph), 
			Color(pcor.r, pcor.g, pcor.b, 0.92), false, 2.0)

		ctrl.draw_rect(Rect2(dx + 2, BASE_Y - ph + 2, dw - 4, ph - 4), 
			Color(pcor.r, pcor.g, pcor.b, 0.2), false, 1.0)


		m._draw_text_centered(ctrl, plbl, Vector2(px, BASE_Y - 10.0), 
			16, Color(pcor.r, pcor.g, pcor.b, 0.82))


		var ty: float = BASE_Y - ph - 8.0

		m._draw_text_centered(ctrl, "Wave %d" % wave, Vector2(px, ty), 
			12, Color(1.0, 0.85, 0.3, 0.8))
		ty -= 18.0

		m._draw_text_centered(ctrl, "%s pts" % m._format_num(scr), Vector2(px, ty),
			13, Color(pcor.r + 0.15, pcor.g + 0.15, pcor.b + 0.15, 0.95))
		ty -= 20.0

		var _asc_p: int = int(e.get("ascensoes", 0))
		var _nivel_p: int = m._nivel_prestigio(_asc_p)

		# ── Nome + badge ao lado (mesmo nivel) ───────────────────────────
		m._draw_text_centered(ctrl, nome, Vector2(px, ty), 15, Color(1.0, 0.97, 0.88, 0.98))
		if _nivel_p > 0:
			var _font_p  : Font      = ThemeDB.fallback_font
			var _ptex_p  : Texture2D = m._carregar_simbolo_prestigio(_nivel_p)
			const BADGE_SZ_P := 40.0
			var _ncor_p : Color
			match _nivel_p:
				1, 2: _ncor_p = Color(0.72, 0.92, 1.0)
				3, 4: _ncor_p = Color(0.40, 0.95, 1.0)
				5, 6: _ncor_p = Color(1.0,  0.45, 1.0)
				_:    _ncor_p = Color(1.0,  0.92, 0.35)
			# posicao: logo a direita do nome centrado, badge centralizado na linha do texto
			var _nw_p  : float = _font_p.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x if _font_p else 80.0
			var _bx_p  : float = px + _nw_p * 0.5 + 4.0
			var _by_p  : float = ty - BADGE_SZ_P * 0.5 - 8.0
			var _bcx_p : float = _bx_p + BADGE_SZ_P * 0.5
			var _bcy_p : float = _by_p + BADGE_SZ_P * 0.5
			if _ptex_p != null:
				ctrl.draw_texture_rect(_ptex_p, Rect2(_bx_p, _by_p, BADGE_SZ_P, BADGE_SZ_P), false)
			else:
				ctrl.draw_circle(Vector2(_bcx_p, _bcy_p), BADGE_SZ_P * 0.44, Color(0.08, 0.06, 0.14, 0.9))
			if _font_p != null:
				var _txt_p : String = str(_asc_p)
				var _fs_p  : int    = 9 if _asc_p >= 100 else 11
				var _tw_p  : float  = _font_p.get_string_size(_txt_p, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs_p).x
				ctrl.draw_string(_font_p, Vector2(_bcx_p - _tw_p * 0.5 + 1.0, _bcy_p + _fs_p * 0.36 + 1.0),
					_txt_p, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs_p, Color(0, 0, 0, 0.75))
				ctrl.draw_string(_font_p, Vector2(_bcx_p - _tw_p * 0.5, _bcy_p + _fs_p * 0.36),
					_txt_p, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs_p, _ncor_p)
		ty -= 22.0


		var av_r: float = 21.0 if idx == 0 else 17.0
		var av_cx: float = px
		var av_cy: float = ty - av_r


		if idx == 0:
			for ag in range(5, 0, -1):
				ctrl.draw_circle(Vector2(av_cx, av_cy), av_r + float(ag) * 2.8, 
					Color(pcor.r, pcor.g, pcor.b, 0.05 / float(ag)))


		ctrl.draw_circle(Vector2(av_cx, av_cy), av_r,
			Color(pcor.r * 0.16, pcor.g * 0.16, pcor.b * 0.16, 0.95))
		var _arc_cor_p : Color = Color(pcor.r, pcor.g, pcor.b, 0.95)
		if _nivel_p > 0:
			# Anel colorido por nivel de prestigio (avatar pequeno demais pra imagem)
			match _nivel_p:
				1, 2: _arc_cor_p = Color(0.72, 0.92, 1.0, 1.0)
				3, 4: _arc_cor_p = Color(0.40, 0.95, 1.0, 1.0)
				5, 6: _arc_cor_p = Color(1.0,  0.45, 1.0, 1.0)
				_:    _arc_cor_p = Color(1.0,  0.92, 0.35, 1.0)
		ctrl.draw_arc(Vector2(av_cx, av_cy), av_r, 0.0, TAU, 40, _arc_cor_p, 2.0)

		ctrl.draw_arc(Vector2(av_cx, av_cy - av_r * 0.28), av_r * 0.52,
			PI + 0.5, TAU - 0.5, 10,
			Color(1.0, 1.0, 1.0, 0.28), 2.0)


		var av_icon_idx: int = 1
		var _raw_av = e.get("avatar_idx", null)
		if _raw_av != null:
			var _t:= typeof(_raw_av)
			if _t == TYPE_INT or _t == TYPE_FLOAT:
				var _av_i:= int(_raw_av)
				if _av_i >= 0 and _av_i < 5:
					av_icon_idx = _av_i
		m._draw_avatar_icone(ctrl, av_cx, av_cy, av_r * 0.82, av_icon_idx)


