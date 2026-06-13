extends Node
## Persistência de ouro, cristais, melhorias da loja, talentos e high score.

const SAVE_PATH_GUEST    := "user://save.json"
const CHECKPOINT_PATH    := "user://run_checkpoint.json"

func _save_path_for(nome: String) -> String:
	if nome == "":
		return SAVE_PATH_GUEST
	return "user://save_%s.json" % nome.to_lower().replace(" ", "_")

func _save_path() -> String:
	return _save_path_for(nome_jogador)

# ── Contas conhecidas deste aparelho (login de 1 clique) ─────────────────────
const CONTAS_PATH := "user://contas_conhecidas.json"

func contas_conhecidas() -> Array:
	if not FileAccess.file_exists(CONTAS_PATH):
		return []
	var f := FileAccess.open(CONTAS_PATH, FileAccess.READ)
	if f == null:
		return []
	var data = JSON.parse_string(f.get_as_text())
	if data is Array:
		var lista : Array = data
		lista.sort_custom(func(a, b):
			return int((a as Dictionary).get("ultima", 0)) > int((b as Dictionary).get("ultima", 0)))
		return lista
	return []

func lembrar_conta(nome: String, email: String, senha_hash: String) -> void:
	if nome.strip_edges() == "" or senha_hash == "":
		return
	var lista := contas_conhecidas()
	lista = lista.filter(func(c): return str((c as Dictionary).get("nome", "")) != nome)
	lista.append({
		"nome": nome, "email": email, "senha": senha_hash,
		"avatar_idx": avatar_idx, "ultima": int(Time.get_unix_time_from_system()),
	})
	var f := FileAccess.open(CONTAS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(lista))

func esquecer_conta(nome: String) -> void:
	var lista := contas_conhecidas().filter(func(c): return str((c as Dictionary).get("nome", "")) != nome)
	var f := FileAccess.open(CONTAS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(lista))

const MAX_LVL   := 3
const ASCENSAO_DANO_VIDA_POR_NIVEL := 0.01
const ASCENSAO_CADENCIA_POR_NIVEL := 0.005
const ASCENSAO_OURO_CRISTAIS_POR_NIVEL := 0.02
const ASCENSAO_DESCONTO_TALENTOS_POR_NIVEL := 0.02
const ASCENSAO_MAX_DANO_VIDA := 0.50
const ASCENSAO_MAX_CADENCIA := 0.25
const ASCENSAO_MAX_OURO_CRISTAIS := 0.50
const ASCENSAO_MAX_DESCONTO_TALENTOS := 0.35
const ASCENSAO_CUSTO_MOEDA_BASE := 30000
const ASCENSAO_CUSTO_MOEDA_POR_NIVEL := 15000
const ASCENSAO_CUSTO_CRISTAIS_BASE := 20
const ASCENSAO_CUSTO_CRISTAIS_POR_NIVEL := 10
const DEBUG_LIBERAR_TALENTOS_LEGADO := false

const LOJA_INFO : Dictionary = {
	"forca": {
		"nome": "FORÇA",
		"desc": "Aumenta o dano\ninicial da torre\nem +8 por nível.",
		"cor": Color(1.0, 0.42, 0.1),
		"custos": [600, 1680, 4500],
	},
	"resistencia": {
		"nome": "RESISTÊNCIA",
		"desc": "Aumenta o HP\ninicial da torre\nem +40 por nível.",
		"cor": Color(0.12, 1.0, 0.45),
		"custos": [480, 1320, 3600],
	},
	"visao": {
		"nome": "VISÃO",
		"desc": "Aumenta o alcance\ninicial da torre\nem +25 por nível.",
		"cor": Color(0.12, 0.62, 1.0),
		"custos": [450, 1200, 3300],
	},
	"cadencia": {
		"nome": "CADÊNCIA",
		"desc": "Aumenta a cadência\ninicial da torre\nem +0.2/s por nível.",
		"cor": Color(0.75, 0.2, 1.0),
		"custos": [780, 2280, 6000],
	},
	"fortuna": {
		"nome": "FORTUNA",
		"desc": "Cada kill concede\n+15% de ouro\npor nível.",
		"cor": Color(1.0, 0.88, 0.12),
		"custos": [660, 1920, 5100],
	},
}

const TALENTOS_INFO : Dictionary = {
	"raiz": {
		"nome": "Nucleo\nTecnologico",
		"desc": "Centro de pesquisa\norbital. Sempre ativo.",
		"efeito": "Nucleo do centro de tecnologia. Libera os ramos iniciais e serve como ponto de fusao.",
		"custo": 0, "req": [],
		"cor": Color(0.5, 0.8, 1.0),
	},
	"p1": {
		"nome": "Fogo\nInterior",
		"desc": "+30 de dano\nbase permanente.",
		"efeito": "Bônus de +30 dano aplicado ao início\nde cada partida. Equivale a 3× Força.",
		"custo": 9, "req": ["raiz"],
		"cor": Color(1.0, 0.42, 0.1),
	},
	"p2": {
		"nome": "Disparo\nRápido",
		"desc": "+0.5 de cadência\npermanente.",
		"efeito": "Torre dispara 0.5 tiros/s a mais\ndesde o início de cada partida.",
		"custo": 21, "req": ["p1"],
		"cor": Color(1.0, 0.60, 0.12),
	},
	"p3": {
		"nome": "Canhão\nDuplo",
		"desc": "Sempre atira\nem 2 alvos.",
		"efeito": "A torre mira e dispara em 2 inimigos\nsimultaneamente. Dobra o dano efetivo.",
		"custo": 45, "req": ["p2"],
		"cor": Color(1.0, 0.75, 0.18),
	},
	"r1": {
		"nome": "Escamas\nde Aço",
		"desc": "Reduz 25% do\ndano recebido.",
		"efeito": "Cada ataque na torre causa 25% menos\ndano. Sobrevive muito mais nas waves tardias.",
		"custo": 9, "req": ["raiz"],
		"cor": Color(0.12, 0.62, 1.0),
	},
	"r2": {
		"nome": "Coração\nArcano",
		"desc": "+4 HP/s de\nregeneração.",
		"efeito": "A torre regenera 4 HP por segundo\nautomaticamente durante toda a partida.",
		"custo": 21, "req": ["r1"],
		"cor": Color(0.25, 0.75, 1.0),
	},
	"r3": {
		"nome": "Fênix",
		"desc": "1x por partida\nsobrevive com\n1 HP.",
		"efeito": "Uma vez por partida, ao chegar em 0 HP,\na torre sobrevive com exatamente 1 HP.",
		"custo": 45, "req": ["r2"],
		"cor": Color(0.5, 0.88, 1.0),
	},
	"f1": {
		"nome": "Coletor\nde Cytron",
		"desc": "+30% de Cytron\nem cada kill.",
		"efeito": "Cada inimigo abatido concede +30% a mais de Cytron. Acumula com bonus de economia.",
		"custo": 9, "req": ["raiz"],
		"cor": Color(1.0, 0.88, 0.12),
	},
	"f2": {
		"nome": "Credito\nde Campo",
		"desc": "Comeca com credito\ntecnico escalavel.",
		"efeito": "Inicia cada partida com +2% do banco em Cytron, com minimo de 500. Continua util no late game.",
		"custo": 21, "req": ["f1"],
		"cor": Color(1.0, 0.76, 0.08),
	},
	"f3": {
		"nome": "Conversor\nDourado",
		"desc": "10% de chance\nde ganhar 4x\nCytron por kill.",
		"efeito": "A cada kill, 10% de chance de multiplicar o Cytron ganho por 4. Explode a economia quando ativa.",
		"custo": 45, "req": ["f2"],
		"cor": Color(1.0, 0.62, 0.05),
	},
	# ── Tier 4 dos ramos existentes ───────────────────────────────────────────
	"p4": {
		"nome": "Arsenal\nPesado",
		"desc": "+80 de dano\nbase permanente.",
		"efeito": "Torre começa com +80 dano extra.\nCombinado com p1 (+30) = +110 de poder total.",
		"custo": 90, "req": ["p3"],
		"cor": Color(1.0, 0.22, 0.02),
	},
	"r4": {
		"nome": "Muralha\nViva",
		"desc": "+100 HP máximo\npermanente.",
		"efeito": "Torre inicia com 100 HP a mais.\nCombina com Fortaleza e cartas de vida.",
		"custo": 90, "req": ["r3"],
		"cor": Color(0.18, 0.45, 1.0),
	},
	"token": {
		"nome": "Protocolo\nGuardiao",
		"desc": "35% apos boss:\nbloqueia 1 ataque\ndo proximo boss.",
		"efeito": "Ao abater um boss, 35% de chance de preparar um token defensivo. O proximo golpe de boss e anulado.",
		"custo": 90, "req": ["r4"],
		"cor": Color(1.0, 0.88, 0.12),
	},
	"f4": {
		"nome": "Mineracao\nCristalina",
		"desc": "+5 cristais\nao fim de cada partida.",
		"efeito": "Ao terminar a partida, ganha 5 cristais extras automaticamente. Funciona em vitoria ou derrota.",
		"custo": 90, "req": ["f3"],
		"cor": Color(1.0, 0.55, 0.02),
	},
	# ── Ramo E — Energia (relâmpago) ──────────────────────────────────────────
	"e1": {
		"nome": "Condutor\nArcano",
		"desc": "Raio Arcano disponível\ndesde a wave 1.",
		"efeito": "Remove a restrição de wave do Raio Arcano.\nTambém concede +30 de dano base ao raio.",
		"custo": 9, "req": ["raiz"],
		"cor": Color(0.38, 0.82, 1.0),
	},
	"e2": {
		"nome": "Sobrecarga",
		"desc": "Raio acerta\n2 alvos simultâneos.",
		"efeito": "Cada descarga do Raio Arcano golpeia\n2 inimigos aleatórios ao mesmo tempo.",
		"custo": 21, "req": ["e1"],
		"cor": Color(0.22, 0.92, 1.0),
	},
	"e3": {
		"nome": "Tempestade\nInterior",
		"desc": "Raio carrega\n40% mais rápido.",
		"efeito": "O cooldown do Raio Arcano é reduzido\nem 40% (×0.6). Muito mais disparos por onda.",
		"custo": 45, "req": ["e2"],
		"cor": Color(0.08, 0.98, 1.0),
	},
	"e4": {
		"nome": "Olho da\nTormenta",
		"desc": "Corrente Elétrica\nsem requisito de fusão.",
		"efeito": "Corrente Elétrica aparece no pool de cartas\nnormalmente, sem precisar de pierce+raio nv5.",
		"custo": 90, "req": ["e3"],
		"cor": Color(0.0, 1.0, 0.92),
	},
	# ── Ramo S — Sombra (veneno) ──────────────────────────────────────────────
	"s1": {
		"nome": "Toque das\nSombras",
		"desc": "Projéteis têm\nveneno base +5 dps.",
		"efeito": "Todos os projéteis envenenam inimigos\ncom 5 dano/s por 4s desde o início da partida.",
		"custo": 9, "req": ["raiz"],
		"cor": Color(0.62, 0.12, 0.88),
	},
	"s2": {
		"nome": "Corrosão\nArcana",
		"desc": "Mobs envenenados\nrecebem +20% dano.",
		"efeito": "Qualquer dano sofrido por mobs com veneno ativo\né amplificado em 20%. Sinergia com veneno arcano.",
		"custo": 21, "req": ["s1"],
		"cor": Color(0.52, 0.08, 0.75),
	},
	"s3": {
		"nome": "Praga\nSombria",
		"desc": "Morte envenena\nmobs em 100px.",
		"efeito": "Ao matar um mob envenenado, o veneno\nse espalha para todos aliados em 100px.",
		"custo": 45, "req": ["s2"],
		"cor": Color(0.42, 0.04, 0.62),
	},
	"s4": {
		"nome": "Veneno\nEterno",
		"desc": "Veneno nunca\nexpira sozinho.",
		"efeito": "O veneno dura até o mob morrer.\nNão há mais timer — contaminação permanente.",
		"custo": 90, "req": ["s3"],
		"cor": Color(0.32, 0.01, 0.50),
	},
	# ── Ramo M — Maestria (cartas) ────────────────────────────────────────────
	"m1": {
		"nome": "Scanner\nde Cartas",
		"desc": "+1 carta para\nescolher por wave.",
		"efeito": "A cada escolha de carta, aparecem 4 opcoes em vez das 3 normais.",
		"custo": 9, "req": ["raiz"],
		"cor": Color(0.88, 0.45, 0.95),
	},
	"m2": {
		"nome": "Refino\nde Dados",
		"desc": "Cartas comuns têm\n30% chance de\nvirar incomum.",
		"efeito": "Cada carta comum no sorteio tem 30% de chance de ser promovida para raridade incomum.",
		"custo": 21, "req": ["m1"],
		"cor": Color(0.75, 0.28, 0.95),
	},
	"m3": {
		"nome": "Reroll\nOtimizado",
		"desc": "Reroll custa\n5 ouro a menos\n(mínimo 5).",
		"efeito": "Cada reroll fica 5 Cytron mais barato. Minimo de 5 Cytron por reroll.",
		"custo": 45, "req": ["m2"],
		"cor": Color(0.60, 0.12, 0.90),
	},
	"m4": {
		"nome": "Escolha\nDupla",
		"desc": "1× por partida:\npegue 2 cartas\nna mesma wave.",
		"efeito": "Uma vez por partida, voce pode escolher 2 cartas em vez de 1 na mesma wave.",
		"custo": 90, "req": ["m3"],
		"cor": Color(0.45, 0.02, 0.88),
	},
	# ── Ramo G — Glacial ──────────────────────────────────────────────────────
	"g1": {
		"nome": "Vantagem\nGlacial",
		"desc": "Mobs lentos recebem\n+15% de dano.",
		"efeito": "Qualquer inimigo afetado por gelo recebe\n15% a mais de dano de todos os projéteis.",
		"custo": 9, "req": ["raiz"],
		"cor": Color(0.35, 0.85, 1.0),
	},
	"g2": {
		"nome": "Tundra\nProlongada",
		"desc": "Campo de Gelo\ndura 2× mais.",
		"efeito": "O efeito de lentidão do Campo de Gelo\ndecai na metade da velocidade normal.",
		"custo": 21, "req": ["g1"],
		"cor": Color(0.18, 0.68, 1.0),
	},
	"g3": {
		"nome": "Avalanche",
		"desc": "Mobs congelados\nespalham gelo em\n60px ao morrer.",
		"efeito": "Ao morrer com gelo ativo, o mob congela\ntodos os aliados em 60px ao redor.",
		"custo": 45, "req": ["g2"],
		"cor": Color(0.08, 0.52, 1.0),
	},
	"g4": {
		"nome": "Criotranse",
		"desc": "Gelo suprime\n80% da regen\ndo Regenerador.",
		"efeito": "Regeneradores afetados por gelo regeneram\napenas 20% do valor normal.",
		"custo": 90, "req": ["g3"],
		"cor": Color(0.04, 0.38, 1.0),
	},
	# ── Tier 5 ────────────────────────────────────────────────────────────────
	"p5": {
		"nome": "Lenda do\nCanhão",
		"desc": "Acertos aplicam\nqueimadura:\n10/s por 2s.",
		"efeito": "Cada acerto aplica queimadura de 10 dano/s\npor 2 segundos no alvo atingido.",
		"custo": 180, "req": ["p4"],
		"cor": Color(1.0, 0.10, 0.02),
	},
	"r5": {
		"nome": "Imortal",
		"desc": "Torre não morre\nnas waves 1–5.",
		"efeito": "Nas primeiras 5 waves, qualquer golpe que\nreduziria a torre a 0 HP deixa-a em 1 HP.",
		"custo": 180, "req": ["r4"],
		"cor": Color(0.12, 0.30, 1.0),
	},
	"e5": {
		"nome": "Fúria\nElétrica",
		"desc": "Raio recarrega\n60% mais rápido.",
		"efeito": "O cooldown do Raio Arcano é reduzido em\nadicionais 60% (acumula com Tempestade Interior).",
		"custo": 180, "req": ["e4"],
		"cor": Color(0.0, 0.98, 0.80),
	},
	"f5": {
		"nome": "Banco\nCristalino",
		"desc": "+50% de cristais\nem cada partida.",
		"efeito": "Todos os cristais ganhos durante a partida sao multiplicados por 1.5 ao depositar.",
		"custo": 180, "req": ["f4"],
		"cor": Color(1.0, 0.45, 0.01),
	},
	"s5": {
		"nome": "Metamorfose",
		"desc": "Matar 50 mobs\nenvenenados: +1\ncarta bônus.",
		"efeito": "Ao abater 50 mobs envenenados em uma partida,\nganha 1 carta extra na próxima escolha de wave.",
		"custo": 180, "req": ["s4"],
		"cor": Color(0.22, 0.0, 0.40),
	},
	# ── Nó Cross-ramo — Colosso ───────────────────────────────────────────────
	"colosso": {
		"nome": "Chassi\nColosso",
		"desc": "Requer P+R+F nv1:\n+50 dano, +50 HP\n+0.3 cadência.",
		"efeito": "Fusao de Arsenal, Defesa e Recompensas. Bonus: +50 dano, +50 HP e +0.3 cadencia.",
		"custo": 60, "req": ["p1", "r1", "f1"],
		"cor": Color(0.88, 0.88, 0.88),
	},
	# ── Ramo B — Berserker ────────────────────────────────────────────────────
	"b1": {
		"nome": "Fúria de\nSangue",
		"desc": "+5% dano por cada\n10% HP perdido\n(máx +50%).",
		"efeito": "O dano da torre escala com o HP perdido.\n+5% por cada 10% de HP faltante, até +50%.",
		"custo": 9, "req": ["raiz"], "cor": Color(0.95, 0.12, 0.12),
	},
	"b2": {
		"nome": "Trance\nBerserker",
		"desc": "Abaixo de 50% HP:\ncadência ×2 por 8s\n(CD: 60s).",
		"efeito": "Ao cair abaixo de 50% HP, a cadência dobra\npor 8 segundos. Recarrega em 60 segundos.",
		"custo": 21, "req": ["b1"], "cor": Color(0.88, 0.08, 0.08),
	},
	"b3": {
		"nome": "Pilhagem\nBárbara",
		"desc": "Kills abaixo de\n30% HP valem\n2x Cytron.",
		"efeito": "Enquanto a torre estiver abaixo de 30% HP, cada kill concede o dobro de Cytron.",
		"custo": 45, "req": ["b2"], "cor": Color(0.82, 0.04, 0.04),
	},
	"b4": {
		"nome": "Fúria\nFinal",
		"desc": "Ao atingir 5% HP:\nexplosão 300 dano\nem 200px (1×/wave).",
		"efeito": "Uma vez por wave, ao cair a 5% HP, a torre\ndispara uma explosão de 300 dano em 200px.",
		"custo": 90, "req": ["b3"], "cor": Color(0.72, 0.01, 0.01),
	},
	# ── Ramo T — Temporal ─────────────────────────────────────────────────────
	"t1": {
		"nome": "Fluxo\nLento",
		"desc": "Mobs entram\n15% mais devagar.",
		"efeito": "O intervalo entre spawns aumenta 15%.\nMenos pressão simultânea de inimigos.",
		"custo": 9, "req": ["raiz"], "cor": Color(0.62, 0.35, 1.0),
	},
	"t2": {
		"nome": "Pulso\nCongelante",
		"desc": "8% de chance por\nkill: gela todos\nos mobs por 0.5s.",
		"efeito": "A cada inimigo morto, 8% de chance de paralisar\ntodos os mobs em campo por 0.5 segundos.",
		"custo": 21, "req": ["t1"], "cor": Color(0.52, 0.28, 1.0),
	},
	"t3": {
		"nome": "Protocolo\nde Boss",
		"desc": "Boss +20% HP\ne recompensa\nCytron extra.",
		"efeito": "Chefes finais ficam 20% mais fortes, mas concedem Cytron extra ao cair.",
		"custo": 45, "req": ["t2"], "cor": Color(0.42, 0.22, 1.0),
	},
	"t4": {
		"nome": "Retrocesso\nTemporal",
		"desc": "1× por partida:\nrestaura HP ao\ninício da wave.",
		"efeito": "Uma vez por partida, ao cair a 20% HP,\na torre é restaurada ao HP do início da wave.",
		"custo": 90, "req": ["t3"], "cor": Color(0.32, 0.16, 1.0),
	},
	# ── Ramo X — Caos ─────────────────────────────────────────────────────────
	"x1": {
		"nome": "Dados\ndo Caos",
		"desc": "20% dos tiros\nfazem 0 dano;\n80% fazem +25%.",
		"efeito": "Cada projétil tem 20% de chance de falhar\ne 80% de chance de causar +25% dano.",
		"custo": 9, "req": ["raiz"], "cor": Color(1.0, 0.65, 0.0),
	},
	"x2": {
		"nome": "Bênção\nAleatória",
		"desc": "Início de cada\nwave: bônus\naleatório.",
		"efeito": "Ao iniciar cada wave, recebe um bonus aleatorio: +8 Cytron, +0.15 cadencia ou +12 dano nesta wave.",
		"custo": 21, "req": ["x1"], "cor": Color(0.95, 0.55, 0.0),
	},
	"x3": {
		"nome": "Reroll\nGratuito",
		"desc": "15% de chance\nde reroll grátis.",
		"efeito": "Cada reroll tem 15% de chance de ser gratuito, sem consumir Cytron.",
		"custo": 45, "req": ["x2"], "cor": Color(0.88, 0.42, 0.0),
	},
	"x4": {
		"nome": "Carta\ndo Acaso",
		"desc": "3% de chance\npor kill: abre\nescolha de carta\n(1× por wave).",
		"efeito": "A cada kill, 3% de chance de abrir a tela\nde escolha de carta imediatamente.\nAcontece no máximo 1 vez por wave.",
		"custo": 90, "req": ["x3"], "cor": Color(0.82, 0.30, 0.0),
	},
	# ── Talentos Situacionais (req: raiz) ─────────────────────────────────────
	"cazador": {
		"nome": "Caçador\nde Bosses",
		"desc": "+40% dano\nem bosses e chefes.",
		"efeito": "Todos os projéteis causam 40% a mais de dano\nem inimigos do tipo boss ou chefe dimensional.",
		"custo": 15, "req": ["raiz"], "cor": Color(1.0, 0.30, 0.0),
	},
	"exter": {
		"nome": "Exterminador",
		"desc": "3+ kills em 1s:\nproximos 3 kills\nvalem 2x Cytron.",
		"efeito": "Ao matar 3+ inimigos em 1 segundo, os proximos 3 kills concedem Cytron dobrado.",
		"custo": 15, "req": ["raiz"], "cor": Color(0.9, 0.82, 0.08),
	},
	"anti_t": {
		"nome": "Anti-Tanque",
		"desc": "+30% dano em\nmobs com mais\nde 300 HP atual.",
		"efeito": "Projéteis causam 30% a mais de dano\nem qualquer inimigo com HP atual acima de 300.",
		"custo": 15, "req": ["raiz"], "cor": Color(0.75, 0.48, 0.08),
	},
	"purif": {
		"nome": "Purificador",
		"desc": "Curandeiros e\ninvocadores têm\n25% menos HP.",
		"efeito": "Curandeiros e invocadores nascem com\n25% menos HP máximo.",
		"custo": 15, "req": ["raiz"], "cor": Color(0.08, 0.82, 0.62),
	},
	# ── Talentos de Legado (desbloqueados por conquistas globais) ─────────────
	"veteran": {
		"nome": "Veterano",
		"desc": "100 partidas:\n+5 cristais ao\nfim de cada run.",
		"efeito": "Requer: 100 partidas jogadas.\nAo fim de cada partida, ganha 5 cristais extras.",
		"custo": 30, "req": ["raiz"], "cor": Color(0.70, 0.70, 0.70),
	},
	"genoci": {
		"nome": "Genocida",
		"desc": "10.000 kills:\n+2 dano por 1k\nkills acima de 10k.",
		"efeito": "Requer: 10.000 kills totais.\nA torre começa com +2 dano por 1000 kills acima de 10k.",
		"custo": 45, "req": ["raiz"], "cor": Color(0.62, 0.08, 0.08),
	},
	"sobrev": {
		"nome": "Sobrevivente",
		"desc": "Wave 30 atingida:\n+1 HP/s de\nregen permanente.",
		"efeito": "Requer: atingir a wave 30.\nA torre regenera +1 HP por segundo permanentemente.",
		"custo": 30, "req": ["raiz"], "cor": Color(0.08, 0.72, 0.38),
	},
	# ── Cross-ramo ────────────────────────────────────────────────────────────
	"predador": {
		"nome": "Predador\nCriotoxico",
		"desc": "Veneno+Gelo:\n+35% dano\n(substitui s2).",
		"efeito": "Fusao de Sombra e Crio. Mobs afetados por veneno e gelo recebem +35% de dano.",
		"custo": 45, "req": ["s2", "g1"], "cor": Color(0.48, 0.82, 0.28),
	},
	"alquim": {
		"nome": "Alquimia\nde Campo",
		"desc": "25% de chance\nde +1 cristal\nao comprar carta.",
		"efeito": "Fusao de Comando e Recompensas. Cada escolha de carta tem 25% de chance de gerar 1 cristal.",
		"custo": 45, "req": ["m2", "f2"], "cor": Color(0.80, 0.58, 0.92),
	},
	"tita": {
		"nome": "Projeto\nTita",
		"desc": "Requer P4+R4:\n+150 dano\n+200 HP.",
		"efeito": "Fusao avancada de Arsenal e Defesa. +150 dano base e +200 HP maximo.",
		"custo": 150, "req": ["p4", "r4"], "cor": Color(0.84, 0.84, 0.84),
	},
	"relamp": {
		"nome": "Raio\nSombrio",
		"desc": "Raio Arcano\naplica veneno\nao acertar.",
		"efeito": "Fusao de Energia e Sombra. Cada descarga do Raio Arcano envenena o alvo por 4 segundos.",
		"custo": 60, "req": ["e3", "s3"], "cor": Color(0.28, 0.88, 0.50),
	},
	"canhao_g": {
		"nome": "Canhao\nGlacial",
		"desc": "20% de chance\nde congelar o\nalvo ao acertar.",
		"efeito": "Fusao de Arsenal e Crio. Cada projetil tem 20% de chance de aplicar paralisia glacial no alvo.",
		"custo": 60, "req": ["p3", "g3"], "cor": Color(0.18, 0.72, 1.0),
	},
}

# ── Proteção anti-downgrade ──────────────────────────────────────────────────
# Atualize este número a cada versão que torna save incompatível com versões anteriores
const TALENTOS_REQ_EXTRA : Dictionary = {
	"f3": ["m2"],
	"p3": ["f2"],
	"t2": ["p2"],
	"e3": ["t2"],
	"s3": ["e3"],
	"x3": ["s3"],
	"b2": ["r3"],
	"g2": ["x2", "b2"],
	"r5": ["token"],
	"colosso": ["p3"],
	"predador": ["e2"],
	"alquim": ["m2", "f2"],
	"tita": ["p4", "r4"],
	"relamp": ["e3", "s3"],
	"canhao_g": ["p3", "g3"],
}

const VERSAO_SAVE : int = 8
const ATRIBUTOS_CONTA_IDS : Array[String] = [
	"vida", "dano", "defesa", "agilidade", "alcance", "fortuna", "critico", "tecnologia"
]
const ATRIBUTOS_CONTA_INFO : Dictionary = {
	"vida":       {"nome":"Vida",       "max":60, "desc":"+8 HP maximo por ponto"},
	"dano":       {"nome":"Dano",       "max":60, "desc":"+1% dano por ponto"},
	"defesa":     {"nome":"Defesa",     "max":45, "desc":"-0.3% dano recebido por ponto"},
	"agilidade":  {"nome":"Agilidade",  "max":45, "desc":"+0.6% cadencia por ponto"},
	"alcance":    {"nome":"Alcance",    "max":40, "desc":"+3 alcance por ponto"},
	"fortuna":    {"nome":"Fortuna",    "max":40, "desc":"+1% ouro por kill por ponto"},
	"critico":    {"nome":"Critico",    "max":35, "desc":"+0.25% critico por ponto"},
	"tecnologia": {"nome":"Tecnologia", "max":35, "desc":"-0.4% cooldown por ponto"},
}
const PATENTES_CONTA : Array[Dictionary] = [
	{"nivel":1, "nome":"Recruta Orbital"},
	{"nivel":5, "nome":"Cadete Lunar"},
	{"nivel":10, "nome":"Sentinela Espacial"},
	{"nivel":20, "nome":"Cabo Orbital"},
	{"nivel":35, "nome":"Sargento Estelar"},
	{"nivel":50, "nome":"Tenente Cosmico"},
	{"nivel":70, "nome":"Capitao Solar"},
	{"nivel":90, "nome":"Major Nebular"},
	{"nivel":120, "nome":"Comandante Astral"},
	{"nivel":150, "nome":"Almirante Cyron"},
]
const MAPAS_TORRE : Array[Dictionary] = [
	{"id":"setor_inicial", "nome":"MAPA 1", "faixa":"Wave 1-50", "tema":"Setor Inicial", "desc":"Primeiro setor da rota orbital.", "cor":Color(0.0, 0.72, 1.0), "bg":"", "wave_ini":1, "wave_fim":50, "mob_mult":1.00, "hp_mult":1.00, "speed_mult":1.00, "bau_bonus":"comum"},
	{"id":"nebulosa_fraturada", "nome":"MAPA 2", "faixa":"Wave 51-100", "tema":"Céu Cyron", "desc":"Segundo setor em céu orbital aberto.", "cor":Color(0.0, 0.72, 1.0), "bg":"res://assets/mapas/open_world_sky/ceu_cyron_orbital.png", "wave_ini":51, "wave_fim":100, "mob_mult":1.32, "hp_mult":1.08, "speed_mult":1.00, "bau_bonus":"raro"},
	{"id":"orbita_glacial", "nome":"MAPA 3", "faixa":"Wave 101-150", "tema":"Céu Glacial", "desc":"Terceiro setor em vazio azul profundo.", "cor":Color(0.42, 0.86, 1.0), "bg":"res://assets/mapas/open_world_sky/ceu_glacial_silencioso.png", "wave_ini":101, "wave_fim":150, "mob_mult":1.55, "hp_mult":1.17, "speed_mult":1.00, "bau_bonus":"epico"},
	{"id":"nucleo_abissal", "nome":"MAPA 4", "faixa":"Wave 151-200", "tema":"Céu Rubro", "desc":"Quarto setor marcado por guerra distante.", "cor":Color(0.95, 0.10, 0.32), "bg":"res://assets/mapas/open_world_sky/ceu_rubro_de_guerra.png", "wave_ini":151, "wave_fim":200, "mob_mult":1.82, "hp_mult":1.28, "speed_mult":1.00, "bau_bonus":"epico"},
	{"id":"coroa_void", "nome":"MAPA 5", "faixa":"Wave 201-250", "tema":"Céu Phantom", "desc":"Quinto setor envolto em névoa violeta.", "cor":Color(0.58, 0.25, 1.0), "bg":"res://assets/mapas/open_world_sky/ceu_phantom_violeta.png", "wave_ini":201, "wave_fim":250, "mob_mult":2.00, "hp_mult":1.38, "speed_mult":1.00, "bau_bonus":"lendario"},
	{"id":"fronteira_cosmica", "nome":"MAPA 6", "faixa":"Wave 251+", "tema":"Céu Profundo", "desc":"Sexto setor para waves extremas.", "cor":Color(0.0, 0.62, 1.0), "bg":"res://assets/mapas/open_world_sky/ceu_profundo_sem_planeta.png", "wave_ini":251, "wave_fim":9999, "mob_mult":2.18, "hp_mult":1.48, "speed_mult":1.00, "bau_bonus":"lendario"},
]
var versao_max_jogada : int = 0   # maior versão que já usou este save
var save_bloqueado    : bool = false  # true se save é de versão superior à atual
var tutorial_concluido   : bool = false  # in-game (wave 2 completa)
var tutorial_menu_visto  : bool = false  # menu overlay fechado
var tutorial_jogo_visto  : bool = false  # dicas in-game exibidas

var ouro_banco          : int = 0
var cristais            : int = 0
var high_score          : int = 0   # Melhor de Normal ou Difícil (retro-compat)
var high_score_facil    : int = 0   # Fácil (separado)
var high_score_normal   : int = 0   # Apenas Normal
var high_score_dificil  : int = 0   # Apenas Difícil
var melhorias  : Dictionary = {
	"forca": 0, "resistencia": 0, "visao": 0, "cadencia": 0, "fortuna": 0,
}
var talentos   : Dictionary = {}  # id -> true (apenas os desbloqueados)
var ascensoes  : int = 0          # Número de prestígios realizados

# ── Checkpoint de run (save-and-resume) ──────────────────────────────────────
var run_checkpoint : Dictionary = {}

func tem_checkpoint() -> bool:
	# Preenche RAM a partir do arquivo dedicado se estiver vazio (sobrevive hot-reload)
	if run_checkpoint.is_empty() and FileAccess.file_exists(CHECKPOINT_PATH):
		var _f := FileAccess.open(CHECKPOINT_PATH, FileAccess.READ)
		if _f != null:
			var _p = JSON.parse_string(_f.get_as_text())
			_f.close()
			if _p is Dictionary and not (_p as Dictionary).is_empty():
				run_checkpoint = _p as Dictionary
	if run_checkpoint.is_empty(): return false
	# Invalida se ascensao mudou desde que o checkpoint foi criado
	return run_checkpoint.get("ascensoes", -1) as int == ascensoes

func salvar_checkpoint(dados: Dictionary) -> void:
	run_checkpoint = dados
	# Grava em arquivo dedicado (independente do save principal)
	var _cf := FileAccess.open(CHECKPOINT_PATH, FileAccess.WRITE)
	if _cf != null:
		_cf.store_string(JSON.stringify(dados))
		_cf.close()
	_salvar_disco()

func limpar_checkpoint() -> void:
	run_checkpoint = {}
	# Remove arquivo dedicado
	if FileAccess.file_exists(CHECKPOINT_PATH):
		DirAccess.remove_absolute(CHECKPOINT_PATH)
	_salvar_disco()

# ── Estatísticas globais acumuladas (todas as partidas) ───────────────────────
var nivel_conta : int = 1
var xp_conta : int = 0
var pontos_atributo : int = 0
var atributos_conta : Dictionary = {
	"vida": 0, "dano": 0, "defesa": 0, "agilidade": 0,
	"alcance": 0, "fortuna": 0, "critico": 0, "tecnologia": 0,
}

var total_partidas          : int        = 0
var partidas_facil          : int        = 0
var partidas_normal         : int        = 0
var partidas_dificil        : int        = 0
var total_mobs_mortos       : int        = 0
var total_boss_mortos       : int        = 0
var total_waves_completadas : int        = 0
var total_ouro_ganho        : int        = 0
var total_score             : int        = 0
var melhor_wave             : int        = 0   # global (retro-compat)
var melhor_wave_facil       : int        = 0
var melhor_wave_normal      : int        = 0
var melhor_wave_dificil     : int        = 0
var melhor_wave_abismo      : int        = 0
var total_cartas            : Dictionary = {}  # {card_id: contagem_total}

# Histórico das últimas 10 partidas ordenado por score (maior primeiro)
# Cada entrada: {wave, score, mobs, bosses, dificuldade (0-3), timestamp}
var historico_partidas      : Array      = []

# ── Configurações do jogador ───────────────────────────────────────────────────
var pausa_auto_wave    : bool  = false   # Pausa antes de iniciar cada wave
var volume_sfx         : float = 1.0    # Volume dos efeitos sonoros (0.0–1.0)
var volume_musica      : float = 0.55   # Volume da música de fundo (0.0–1.0)
var dificuldade        : int   = 1      # 0=Fácil  1=Normal  2=Difícil
var mapa_teste_id      : String = "setor_inicial"
var acessibilidade_ativo : bool = false  # Modo acessibilidade (glaucoma): triplo-clique + TTS
var tts_api_key          : String = ""   # Google Cloud TTS API key (grátis: console.cloud.google.com)
var nome_jogador              : String = ""
var email_jogador             : String = ""
var senha_jogador             : String = ""
var player_id                 : String = ""      # UUID único permanente (nunca muda)
var id_sequencial             : int    = 0       # Número sequencial exibido no perfil (#1, #2...)
var nome_ja_renomeado         : bool   = false   # 1 rename por conta
var credenciais_versao        : int    = 0    # 0=sem email (legado) → força recadastro
var ultimo_check_ranking      : int    = 0
var ranking_temporada_premiada : int   = -1
var discord_reward_claimed     : bool  = false
var avatar_idx                : int    = 0
var tts_voz              : String = "pt-BR-Neural2-A"

# ── Modo Abismo ───────────────────────────────────────────────────────────────
var abismo_modo_ativo : bool = false  # Flag temporária: lida ao iniciar Main
var high_score_abismo : int  = 0      # Recorde no Modo Abismo
var baus_estoque : Dictionary = {"comum": 0, "raro": 0, "epico": 0, "lendario": 0}

const ARSENAL_SLOTS : Array = ["canhao", "nucleo", "blindagem", "reliquia"]
const ARSENAL_INFO : Dictionary = {
	"canhao_plasma": {"nome":"Canhão de Plasma", "slot":"canhao", "raridade":"comum", "desc":"Emissor básico de plasma lunar.\nBônus: +5% dano da torre.", "bonus":{"dano_mult":0.05}, "cor":Color(1.0,0.46,0.16), "icone":"res://assets/arsenal/canhao_plasma.png"},
	"disparador_ionico": {"nome":"Disparador Iônico", "slot":"canhao", "raridade":"raro", "desc":"Arma leve com anéis elétricos.\nBônus: +6% cadência.", "bonus":{"cadencia_mult":0.06}, "cor":Color(0.22,0.92,1.0), "icone":"res://assets/arsenal/disparador_ionico.png"},
	"lente_orbital": {"nome":"Lente Orbital", "slot":"canhao", "raridade":"epico", "desc":"Lente de mira para disparos longos.\nBônus: +8% alcance e +4% dano.", "bonus":{"alcance_mult":0.08, "dano_mult":0.04}, "cor":Color(0.66,0.28,1.0), "icone":"res://assets/arsenal/lente_orbital.png"},
	"devastador_eclipse": {"nome":"Devastador Eclipse", "slot":"canhao", "raridade":"lendario", "desc":"Canhão imperial de energia negra.\nEfeito: +10% dano contra boss.", "bonus":{"dano_mult":0.12, "boss_dano_mult":0.10}, "cor":Color(1.0,0.72,0.12), "icone":"res://assets/arsenal/devastador_eclipse.png"},
	"nucleo_vital": {"nome":"Núcleo Vital", "slot":"nucleo", "raridade":"comum", "desc":"Reator estável de sobrevivência.\nBônus: +8% vida máxima.", "bonus":{"vida_mult":0.08}, "cor":Color(0.20,0.90,1.0), "icone":"res://assets/arsenal/nucleo_vital.png"},
	"reator_lunar": {"nome":"Reator Lunar", "slot":"nucleo", "raridade":"raro", "desc":"Reator frio de pulso constante.\nBônus: +2 HP/s regeneração.", "bonus":{"regen_flat":2.0}, "cor":Color(0.55,0.88,1.0), "icone":"res://assets/arsenal/reator_lunar.png"},
	"bateria_cristal": {"nome":"Bateria de Cristal", "slot":"nucleo", "raridade":"epico", "desc":"Fonte de energia para habilidades.\nBônus: -8% cooldown das habilidades.", "bonus":{"cooldown_mult":-0.08}, "cor":Color(0.42,0.62,1.0), "icone":"res://assets/arsenal/bateria_cristal.png"},
	"coracao_estelar": {"nome":"Coração Estelar", "slot":"nucleo", "raridade":"lendario", "desc":"Núcleo vivo criado em uma estrela antiga.\nEfeito: escudo ao iniciar boss.", "bonus":{"vida_mult":0.12, "boss_escudo":1.0}, "cor":Color(1.0,0.78,0.22), "icone":"res://assets/arsenal/coracao_estelar.png"},
	"placa_lunar": {"nome":"Placa Lunar", "slot":"blindagem", "raridade":"comum", "desc":"Blindagem simples de liga lunar.\nBônus: +5% redução de dano.", "bonus":{"reducao_dano":0.05}, "cor":Color(0.35,1.0,0.55), "icone":"res://assets/arsenal/placa_lunar.png"},
	"casco_meteoro": {"nome":"Casco de Meteoro", "slot":"blindagem", "raridade":"raro", "desc":"Casco pesado feito de rocha espacial.\nBônus: +6% vida e +3% redução de dano.", "bonus":{"vida_mult":0.06, "reducao_dano":0.03}, "cor":Color(0.72,0.78,0.70), "icone":"res://assets/arsenal/casco_meteoro.png"},
	"campo_defletor": {"nome":"Campo Defletor", "slot":"blindagem", "raridade":"epico", "desc":"Campo hexagonal de proteção orbital.\nEfeito: 8% chance de bloquear impacto.", "bonus":{"bloqueio_chance":0.08}, "cor":Color(0.24,0.95,0.78), "icone":"res://assets/arsenal/campo_defletor.png"},
	"armadura_imperial": {"nome":"Armadura Imperial", "slot":"blindagem", "raridade":"lendario", "desc":"Defesa usada pela guarda do Império Estelar.\nEfeito: barreira quando HP fica baixo.", "bonus":{"reducao_dano":0.12, "barreira_hp_baixo":1.0}, "cor":Color(1.0,0.64,0.16), "icone":"res://assets/arsenal/armadura_imperial.png"},
	"fragmento_lunar": {"nome":"Fragmento Lunar", "slot":"reliquia", "raridade":"comum", "desc":"Pedaço de cristal recolhido pelo exército lunar.\nBônus: +4% ouro ganho.", "bonus":{"ouro_mult":0.04}, "cor":Color(0.92,0.92,1.0), "icone":"res://assets/arsenal/fragmento_lunar.png"},
	"orbe_abissal": {"nome":"Orbe Abissal", "slot":"reliquia", "raridade":"raro", "desc":"Orbe roxo com energia instável.\nBônus: +5% efeitos especiais.", "bonus":{"efeito_mult":0.05}, "cor":Color(0.68,0.12,1.0), "icone":"res://assets/arsenal/orbe_abissal.png"},
	"selo_dante": {"nome":"Selo de Dante", "slot":"reliquia", "raridade":"epico", "desc":"Selo vermelho do príncipe do Império Estelar.\nBônus: +10% dano contra boss.", "bonus":{"boss_dano_mult":0.10}, "cor":Color(1.0,0.22,0.10), "icone":"res://assets/arsenal/selo_dante.png"},
	"reliquia_cyron": {"nome":"Relíquia de Cyron", "slot":"reliquia", "raridade":"lendario", "desc":"Artefato lunar ligado ao comandante Cyron.\nEfeito: chance de repetir habilidade do comandante.", "bonus":{"pet_poder_mult":0.10, "repetir_assistente":0.08}, "cor":Color(1.0,0.84,0.16), "icone":"res://assets/arsenal/reliquia_cyron.png"},
}
var arsenal_itens_desbloqueados : Array = []
var arsenal_equipado : Dictionary = {"canhao":"", "nucleo":"", "blindagem":"", "reliquia":""}
var arsenal_autoequip_migrado : bool = false

# ── Skins da Torre ─────────────────────────────────────────────────────────────
const SKINS_INFO : Dictionary = {
	"padrao":  {"nome": "Padrão",  "desc": "Torre original.\nSem bônus.",           "cor": Color(0.0,  0.72, 1.0),  "custo": 0,    "bonus_tipo": "",         "bonus_val": 0.0 },
	"chama":   {"nome": "Chama",   "desc": "+5% de dano base\nde todos os tiros.",  "cor": Color(1.0,  0.28, 0.08), "custo": 2500, "bonus_tipo": "dano",     "bonus_val": 0.05},
	"glacial": {"nome": "Glacial", "desc": "+5% de alcance\nde detecção.",          "cor": Color(0.45, 0.85, 1.0),  "custo": 2500, "bonus_tipo": "alcance",  "bonus_val": 0.05},
	"abissal": {"nome": "Abissal", "desc": "+5% de cadência\nde disparo.",          "cor": Color(0.68, 0.12, 1.0),  "custo": 2500, "bonus_tipo": "cadencia", "bonus_val": 0.05},
	"dourado":    {"nome": "Dourado",    "desc": "+5% de ouro\npor kill.",                      "cor": Color(1.0,  0.88, 0.08), "custo": 4500, "bonus_tipo": "ouro",  "bonus_val": 0.05},
	"saberpunk":  {"nome": "SaberPunk", "desc": "EXCLUSIVA BETA\n+4% dano, cadência e alcance.\n+1 HP/s de regeneração.\n+1% de score por kill.", "cor": Color(0.0,  1.0,  0.88), "custo": 0,    "bonus_tipo": "beta",  "bonus_val": 0.04},
	"nebula_prime": {"nome": "Nebula Prime", "desc": "Skin premium.\n+4% dano e alcance.\nVisual de nebulosa.", "cor": Color(0.95, 0.22, 1.0), "custo": 0, "bonus_tipo": "premium_dano_alc", "bonus_val": 0.04, "premium": true},
	"orbital_gold": {"nome": "Orbital Gold", "desc": "Skin premium.\n+6% ouro por kill.\nNúcleo orbital dourado.", "cor": Color(1.0, 0.72, 0.10), "custo": 0, "bonus_tipo": "ouro", "bonus_val": 0.06, "premium": true},
	"void_core": {"nome": "Void Core", "desc": "Skin premium.\n+3% cadência e score.\nEnergia de vácuo.", "cor": Color(0.35, 0.08, 1.0), "custo": 0, "bonus_tipo": "premium_cad_score", "bonus_val": 0.03, "score_mult": 0.03, "premium": true},
}
var skin_ativa           : String = "padrao"
var skins_desbloqueadas  : Array  = ["padrao"]
var premium_comprados    : Array  = []

# ── Habilidades Ativas ──────────────────────────────────────────────────────────
const HABIL_INFO : Dictionary = {
	"eletrico":   {"nome": "Pulso Elétrico", "desc": "Para todos os mobs\npor 1.8s",          "custo_cristal": 3, "cor": Color(0.25, 0.95, 1.0)},
	"gelo":       {"nome": "Bomba de Gelo",  "desc": "Congela mobs em\n80% por 2.5s",         "custo_cristal": 3, "cor": Color(0.55, 0.88, 1.0)},
	"devastador": {"nome": "Pulso Final",    "desc": "Remove 35% do HP\natual de todos os mobs","custo_cristal": 4, "cor": Color(1.0, 0.42, 0.08)},
}
var habil_cargas : Dictionary = {"eletrico": 0, "gelo": 0, "devastador": 0}

const REVIVE_LOJA_MAX   : int = 5
const REVIVE_LOJA_CUSTO : int = 20000
var revive_loja_estoque : int  = 0

const ORBE_CURA_MAX   : int = 5
const ORBE_CURA_CUSTO : int = 8000
var orbe_cura_estoque : int = 0

const CRISTAL_BARREIRA_MAX   : int = 3
const CRISTAL_BARREIRA_CUSTO : int = 15000
var cristal_barreira_estoque : int = 0

const RUNA_FURIA_MAX   : int = 3
const RUNA_FURIA_CUSTO : int = 12000
var runa_furia_estoque : int = 0
var cons_equipados : Array = []
var pet_ia_comprado     : bool = false


func _cons_ids_disponiveis() -> Array:
	var ids : Array = []
	if revive_loja_estoque > 0:
		ids.append("revive")
	if orbe_cura_estoque > 0:
		ids.append("orbe")
	if cristal_barreira_estoque > 0:
		ids.append("cristal")
	if runa_furia_estoque > 0:
		ids.append("runa")
	return ids


func normalizar_cons_equipados() -> void:
	var validos : Array = _cons_ids_disponiveis()
	var novos : Array = []
	for cid in cons_equipados:
		var sid : String = str(cid)
		if sid in validos and not sid in novos:
			novos.append(sid)
		if novos.size() >= 3:
			break
	cons_equipados = novos


func normalizar_arsenal() -> void:
	var novos : Array = []
	for iid in arsenal_itens_desbloqueados:
		var sid : String = str(iid)
		if ARSENAL_INFO.has(sid) and not sid in novos:
			novos.append(sid)
	arsenal_itens_desbloqueados = novos
	for slot in ARSENAL_SLOTS:
		var s : String = str(slot)
		var eq : String = str(arsenal_equipado.get(s, ""))
		if eq == "":
			arsenal_equipado[s] = ""
		elif not ARSENAL_INFO.has(eq) or not eq in arsenal_itens_desbloqueados or str((ARSENAL_INFO[eq] as Dictionary).get("slot", "")) != s:
			arsenal_equipado[s] = ""


func migrar_arsenal_autoequip_antigo() -> void:
	if arsenal_autoequip_migrado:
		return
	var antigos : Dictionary = {
		"canhao":"canhao_plasma",
		"nucleo":"nucleo_vital",
		"blindagem":"placa_lunar",
		"reliquia":"fragmento_lunar",
	}
	for slot in antigos.keys():
		var s : String = str(slot)
		if str(arsenal_equipado.get(s, "")) == str(antigos[s]):
			arsenal_equipado[s] = ""
	arsenal_autoequip_migrado = true


func arsenal_raridade_cor(raridade: String) -> Color:
	match raridade:
		"comum": return Color(0.68, 0.76, 0.84)
		"raro": return Color(0.22, 0.95, 0.70)
		"epico": return Color(0.72, 0.24, 1.0)
		"lendario": return Color(1.0, 0.78, 0.16)
	return Color(0.6, 0.6, 0.65)


func arsenal_slot_nome(slot_id: String) -> String:
	match slot_id:
		"canhao": return "Módulo Ofensivo"
		"nucleo": return "Núcleo Tático"
		"blindagem": return "Defesa Orbital"
		"reliquia": return "Artefato"
	return slot_id.capitalize()


func arsenal_bonus_texto(iid: String) -> String:
	var info : Dictionary = ARSENAL_INFO.get(iid, {}) as Dictionary
	if info.is_empty():
		return ""
	var bonus : Dictionary = info.get("bonus", {}) as Dictionary
	var partes : Array = []
	for k in bonus.keys():
		var v : float = float(bonus[k])
		var label : String = str(k)
		match str(k):
			"dano_mult": label = "Dano"
			"cadencia_mult": label = "Cadência"
			"alcance_mult": label = "Alcance"
			"vida_mult": label = "Vida máxima"
			"regen_flat": label = "Regeneração"
			"reducao_dano": label = "Redução de dano"
			"cooldown_mult": label = "Cooldown"
			"boss_dano_mult": label = "Dano contra boss"
			"ouro_mult": label = "Ouro"
			"efeito_mult": label = "Efeitos especiais"
			"pet_poder_mult": label = "Poder comandante"
			"bloqueio_chance": label = "Bloqueio"
			"boss_escudo", "barreira_hp_baixo": label = "Efeito especial"
			"repetir_assistente": label = "Repetir comandante"
		if absf(v) >= 1.0 and str(k).ends_with("_flat"):
			partes.append("%s +%.0f" % [label, v])
		elif v == 1.0:
			partes.append(label)
		else:
			partes.append("%s %+.0f%%" % [label, v * 100.0])
	return "\n".join(partes)


func equipamentos_bonus_stats() -> Dictionary:
	normalizar_arsenal()
	var out : Dictionary = {
		"dano_mult": 1.0,
		"cadencia_mult": 1.0,
		"alcance_mult": 1.0,
		"vida_mult": 1.0,
		"regen_flat": 0.0,
		"reducao_dano": 0.0,
		"cooldown_mult": 0.0,
		"boss_dano_mult": 0.0,
		"ouro_mult": 0.0,
		"efeito_mult": 0.0,
		"pet_poder_mult": 0.0,
		"bloqueio_chance": 0.0,
		"boss_escudo": false,
		"barreira_hp_baixo": false,
		"repetir_assistente": 0.0,
	}
	for slot_key in ARSENAL_SLOTS:
		var slot_id : String = str(slot_key)
		var iid : String = str(arsenal_equipado.get(slot_id, ""))
		if iid == "" or not ARSENAL_INFO.has(iid):
			continue
		var info : Dictionary = ARSENAL_INFO[iid] as Dictionary
		if str(info.get("slot", "")) != slot_id:
			continue
		var bonus : Dictionary = info.get("bonus", {}) as Dictionary
		for key in bonus.keys():
			var k : String = str(key)
			var v : float = float(bonus[key])
			match k:
				"dano_mult", "cadencia_mult", "alcance_mult", "vida_mult":
					out[k] = float(out.get(k, 1.0)) * (1.0 + v)
				"regen_flat", "reducao_dano", "cooldown_mult", "boss_dano_mult", "ouro_mult", "efeito_mult", "pet_poder_mult", "bloqueio_chance", "repetir_assistente":
					out[k] = float(out.get(k, 0.0)) + v
				"boss_escudo", "barreira_hp_baixo":
					out[k] = true
	return out


func ganhar_item_arsenal(iid: String) -> bool:
	if not ARSENAL_INFO.has(iid):
		return false
	if iid in arsenal_itens_desbloqueados:
		return false
	arsenal_itens_desbloqueados.append(iid)
	normalizar_arsenal()
	salvar()
	return true


func equipar_item_arsenal(iid: String) -> bool:
	if not ARSENAL_INFO.has(iid):
		return false
	if not iid in arsenal_itens_desbloqueados:
		return false
	var slot_id : String = str((ARSENAL_INFO[iid] as Dictionary).get("slot", ""))
	if not slot_id in ARSENAL_SLOTS:
		return false
	arsenal_equipado[slot_id] = iid
	salvar()
	return true


func desequipar_slot_arsenal(slot_id: String) -> bool:
	if not slot_id in ARSENAL_SLOTS:
		return false
	arsenal_equipado[slot_id] = ""
	salvar()
	return true

const PETS_INFO : Dictionary = {
	"cyron":   {"nome":"Cyron",   "desc":"Comandante de suporte.\nHacker Sistêmico: 2x cadência por 15s.\nCooldown: 35s.", "cor":Color(0.25,0.75,1.0), "custo":20000, "dano":22.0,"cd_ataque":1.8,"alcance":130.0,"vel":72.0, "hab_cd":35.0,"hab_dur":15.0,"hab_tipo":"hacker",       "hab_nome":"Hacker Sistêmico"},
	"nexus":   {"nome":"Dante",   "desc":"Comandante ofensivo.\nCorte Dimensional: +60% dano por 12s.\nCooldown: 40s.",       "cor":Color(1.0,0.12,0.08),  "custo":35000, "dano":38.0,"cd_ataque":2.0,"alcance":110.0,"vel":65.0, "hab_cd":40.0,"hab_dur":12.0,"hab_tipo":"sobrecarga",    "hab_nome":"Corte Dimensional"},
	"phantom": {"nome":"Eira", "desc":"Comandante furtiva da Coligação Phantom.\nInterferência: paralisa todos mobs por 3s.\nCooldown: 50s.","cor":Color(0.7,0.2,1.0),  "custo":30000, "dano":16.0,"cd_ataque":1.0,"alcance":150.0,"vel":95.0, "hab_cd":50.0,"hab_dur":3.0, "hab_tipo":"interferencia", "hab_nome":"Interferência"},
	"aurora":  {"nome":"Aurora", "desc":"Comandante premium.\nPulso Aurora: cura e acelera a torre por 10s.\nCooldown: 45s.", "cor":Color(0.25,1.0,0.78), "custo":0, "dano":28.0,"cd_ataque":1.5,"alcance":145.0,"vel":88.0, "hab_cd":45.0,"hab_dur":10.0,"hab_tipo":"aurora", "hab_nome":"Pulso Aurora", "premium":true},
	"eclipse": {"nome":"Eclipse", "desc":"Comandante premium.\nSombra Orbital: enfraquece mobs por 8s.\nCooldown: 48s.", "cor":Color(0.85,0.18,1.0), "custo":0, "dano":34.0,"cd_ataque":1.7,"alcance":155.0,"vel":78.0, "hab_cd":48.0,"hab_dur":8.0,"hab_tipo":"eclipse", "hab_nome":"Sombra Orbital", "premium":true},
}
var pet_ativo            : String = ""
var pets_desbloqueados   : Array  = []
var pet_cartas           : Dictionary = {}
var pet_niveis           : Dictionary = {}

const PREMIUM_INFO : Dictionary = {
	"skin_nebula_prime": {"nome":"Nebula Prime", "tipo":"skin", "unlock":"nebula_prime", "produto":"cyron_skin_nebula_prime", "preco":"R$ 7,90", "desc":"Skin de nebulosa com bônus leve de dano e alcance.", "cor":Color(0.95,0.22,1.0)},
	"skin_orbital_gold": {"nome":"Orbital Gold", "tipo":"skin", "unlock":"orbital_gold", "produto":"cyron_skin_orbital_gold", "preco":"R$ 9,90", "desc":"Skin dourada premium com bônus de ouro.", "cor":Color(1.0,0.72,0.10)},
	"skin_void_core": {"nome":"Void Core", "tipo":"skin", "unlock":"void_core", "produto":"cyron_skin_void_core", "preco":"R$ 9,90", "desc":"Skin de vácuo com cadência e score bônus.", "cor":Color(0.35,0.08,1.0)},
	"pet_aurora": {"nome":"Aurora", "tipo":"pet", "unlock":"aurora", "produto":"cyron_pet_aurora", "preco":"R$ 12,90", "desc":"Comandante premium de suporte e cura.", "cor":Color(0.25,1.0,0.78)},
	"pet_eclipse": {"nome":"Eclipse", "tipo":"pet", "unlock":"eclipse", "produto":"cyron_pet_eclipse", "preco":"R$ 12,90", "desc":"Comandante premium de enfraquecimento orbital.", "cor":Color(0.85,0.18,1.0)},
	"pack_starter": {"nome":"Pacote Inicial", "tipo":"pack", "produto":"cyron_pack_starter", "preco":"R$ 4,90", "desc":"25000 ouro, 25 cristais e 1 Orbe de Cura.", "cor":Color(0.55,0.95,0.35), "ouro":25000, "cristais":25, "orbe":1},
	"pack_cosmic": {"nome":"Pacote Cosmico", "tipo":"pack", "produto":"cyron_pack_cosmic", "preco":"R$ 19,90", "desc":"120000 ouro, 120 cristais, 2 Orbes, 1 Cristal e 1 Runa.", "cor":Color(0.35,0.75,1.0), "ouro":120000, "cristais":120, "orbe":2, "cristal":1, "runa":1},
}

const PET_CARTAS_NIVEIS_PADRAO : Array = [0, 12, 30, 75, 170]
# Multiplicador de stats por nível
const PET_CARTAS_NIVEIS : Dictionary = {
	"cyron":   [0, 10, 25, 60, 140],
	"nexus":   [0, 12, 32, 80, 180],
	"phantom": [0, 12, 30, 75, 170],
	"aurora":  [0, 18, 45, 110, 250],
	"eclipse": [0, 18, 45, 110, 250],
}
# Redução de cooldown da habilidade por nível
const PET_EVOLUCOES : Dictionary = {
	"cyron": {
		2: {"nome":"Firmware Afiado", "desc":"+18% dano do comandante.", "bonus":{"dano_mult":1.18}},
		3: {"nome":"Rede Amplificada", "desc":"+14% alcance e +2s no Hacker Sistêmico.", "bonus":{"alcance_mult":1.14, "hab_dur_add":2.0}},
		4: {"nome":"Overclock Estável", "desc":"Ataques 12% mais rápidos.", "bonus":{"cd_ataque_mult":0.88}},
		5: {"nome":"Hacker Mestre", "desc":"Habilidade recarrega 18% mais rápido e dura +4s.", "bonus":{"hab_cd_mult":0.82, "hab_dur_add":4.0}},
	},
	"nexus": {
		2: {"nome":"Canhão Pesado", "desc":"+22% dano do comandante.", "bonus":{"dano_mult":1.22}},
		3: {"nome":"Gatilho Duplo", "desc":"Ataques 15% mais rápidos.", "bonus":{"cd_ataque_mult":0.85}},
		4: {"nome":"Mira Térmica", "desc":"+18% alcance e +10% dano.", "bonus":{"alcance_mult":1.18, "dano_mult":1.10}},
		5: {"nome":"Sobrecarga Brutal", "desc":"Sobrecarga dura +4s e recarrega 15% mais rápido.", "bonus":{"hab_dur_add":4.0, "hab_cd_mult":0.85}},
	},
	"phantom": {
		2: {"nome":"Disparo Fantasma", "desc":"Ataques 15% mais rápidos.", "bonus":{"cd_ataque_mult":0.85}},
		3: {"nome":"Sinal Distante", "desc":"+20% alcance.", "bonus":{"alcance_mult":1.20}},
		4: {"nome":"Pulso Fantasma", "desc":"Interferência dura +1.5s.", "bonus":{"hab_dur_add":1.5}},
		5: {"nome":"Apagão Total", "desc":"+20% dano e habilidade recarrega 20% mais rápido.", "bonus":{"dano_mult":1.20, "hab_cd_mult":0.80}},
	},
	"aurora": {
		2: {"nome":"Cristal Vital", "desc":"+15% dano e alcance.", "bonus":{"dano_mult":1.15, "alcance_mult":1.15}},
		3: {"nome":"Cura Aprimorada", "desc":"Pulso Aurora cura +10% da vida máxima.", "bonus":{"aurora_heal_add":0.10}},
		4: {"nome":"Aceleração Suave", "desc":"Pulso Aurora dura +3s.", "bonus":{"hab_dur_add":3.0}},
		5: {"nome":"Pulso Milagroso", "desc":"Cura +12% extra e recarrega 20% mais rápido.", "bonus":{"aurora_heal_add":0.12, "hab_cd_mult":0.80}},
	},
	"eclipse": {
		2: {"nome":"Lâmina Sombria", "desc":"+18% dano.", "bonus":{"dano_mult":1.18}},
		3: {"nome":"Órbita Longa", "desc":"+20% alcance.", "bonus":{"alcance_mult":1.20}},
		4: {"nome":"Veneno Profundo", "desc":"Sombra Orbital dura +2s e aplica lentidão mais forte.", "bonus":{"hab_dur_add":2.0, "eclipse_slow_add":0.10}},
		5: {"nome":"Eclipse Total", "desc":"+20% dano e habilidade recarrega 20% mais rápido.", "bonus":{"dano_mult":1.20, "hab_cd_mult":0.80}},
	},
}


func _pet_desbloqueado(pid: String) -> bool:
	return pid in pets_desbloqueados or (pid == "cyron" and pet_ia_comprado)


func pet_desbloqueado(pid: String) -> bool:
	return PETS_INFO.has(pid) and _pet_desbloqueado(pid)


func pet_ativo_jogavel() -> bool:
	return pet_desbloqueado(pet_ativo)


func normalizar_pet_ativo() -> void:
	if pet_ativo_jogavel():
		return
	for raw_pid in pets_desbloqueados:
		var pid : String = str(raw_pid)
		if pet_desbloqueado(pid):
			pet_ativo = pid
			return
	if pet_ia_comprado and PETS_INFO.has("cyron"):
		pet_ativo = "cyron"
		return
	pet_ativo = ""


func _normalizar_pet_progressao() -> void:
	for pid_key in PETS_INFO.keys():
		var pid : String = str(pid_key)
		if not pet_niveis.has(pid):
			pet_niveis[pid] = 1
		pet_niveis[pid] = clampi(int(pet_niveis.get(pid, 1)), 1, 5)
		pet_cartas[pid] = maxi(0, int(pet_cartas.get(pid, 0)))


func pet_nivel(pid: String) -> int:
	return clampi(int(pet_niveis.get(pid, 1)), 1, 5)


func pet_cartas_necessarias(pid: String, nivel: int = -1) -> int:
	var n : int = pet_nivel(pid) if nivel < 0 else clampi(nivel, 1, 5)
	if n >= 5:
		return 0
	var custos : Array = PET_CARTAS_NIVEIS.get(pid, PET_CARTAS_NIVEIS_PADRAO) as Array
	return int(custos[n])


func pet_cartas_info(pid: String) -> Dictionary:
	var nivel : int = pet_nivel(pid)
	var cartas : int = int(pet_cartas.get(pid, 0))
	if nivel >= 5:
		return {"nivel":5,"cartas":cartas,"necessario":0,"prog":1.0}
	var necessario : int = pet_cartas_necessarias(pid, nivel)
	return {"nivel":nivel,"cartas":cartas,"necessario":necessario,"prog":clampf(float(cartas) / float(maxi(1, necessario)), 0.0, 1.0)}


func pet_bonus(pid: String) -> Dictionary:
	var out : Dictionary = {
		"dano_mult": 1.0,
		"cd_ataque_mult": 1.0,
		"alcance_mult": 1.0,
		"vel_mult": 1.0,
		"hab_cd_mult": 1.0,
		"hab_dur_add": 0.0,
		"aurora_heal_add": 0.0,
		"eclipse_slow_add": 0.0,
	}
	if not _pet_desbloqueado(pid):
		return out
	var evols : Dictionary = PET_EVOLUCOES.get(pid, {}) as Dictionary
	for lv in range(2, pet_nivel(pid) + 1):
		var etapa : Dictionary = evols.get(lv, {}) as Dictionary
		var bonus : Dictionary = etapa.get("bonus", {}) as Dictionary
		for k in bonus.keys():
			var ks : String = str(k)
			if ks.ends_with("_mult"):
				out[ks] = float(out.get(ks, 1.0)) * float(bonus[k])
			else:
				out[ks] = float(out.get(ks, 0.0)) + float(bonus[k])
	return out


func pet_stats(pid: String) -> Dictionary:
	var info : Dictionary = PETS_INFO.get(pid, {}) as Dictionary
	var desbloqueado : bool = _pet_desbloqueado(pid)
	var bonus : Dictionary = pet_bonus(pid)
	var equip_bonus : Dictionary = {}
	if desbloqueado:
		equip_bonus = equipamentos_bonus_stats()
	var pet_mult : float = 1.0 + float(equip_bonus.get("pet_poder_mult", 0.0))
	var hab_cd_mult_equip : float = maxf(0.10, 1.0 + float(equip_bonus.get("cooldown_mult", 0.0)))
	return {
		"dano": float(info.get("dano", 0.0)) * float(bonus.get("dano_mult", 1.0)) * pet_mult,
		"cd_ataque": float(info.get("cd_ataque", 1.8)) * float(bonus.get("cd_ataque_mult", 1.0)),
		"alcance": float(info.get("alcance", 0.0)) * float(bonus.get("alcance_mult", 1.0)),
		"vel": float(info.get("vel", 0.0)) * float(bonus.get("vel_mult", 1.0)),
		"hab_cd": float(info.get("hab_cd", 35.0)) * float(bonus.get("hab_cd_mult", 1.0)) * hab_cd_mult_equip,
		"hab_dur": float(info.get("hab_dur", 0.0)) + float(bonus.get("hab_dur_add", 0.0)),
		"aurora_heal": 0.18 + float(bonus.get("aurora_heal_add", 0.0)),
		"eclipse_slow": clampf(0.65 + float(bonus.get("eclipse_slow_add", 0.0)), 0.0, 0.9),
	}


func pet_evolucao_linha(pid: String, nivel: int) -> String:
	var evols : Dictionary = PET_EVOLUCOES.get(pid, {}) as Dictionary
	var etapa : Dictionary = evols.get(nivel, {}) as Dictionary
	if etapa.is_empty():
		return ""
	return "Nv.%d - %s: %s" % [nivel, str(etapa.get("nome", "")), str(etapa.get("desc", ""))]


func pet_proxima_evolucao_texto(pid: String) -> String:
	var prox : int = pet_nivel(pid) + 1
	if prox > 5:
		return "Nível máximo alcançado."
	return pet_evolucao_linha(pid, prox)


func pet_evolucoes_texto(pid: String) -> String:
	var linhas : Array = []
	for lv in range(2, 6):
		var linha : String = pet_evolucao_linha(pid, lv)
		if linha != "":
			linhas.append(linha)
	return "\n".join(linhas)


func pet_evolucoes_status_texto(pid: String) -> String:
	var info : Dictionary = PETS_INFO.get(pid, {}) as Dictionary
	var nivel_atual : int = pet_nivel(pid)
	var adquirido : bool = _pet_desbloqueado(pid)
	var linhas : Array = []
	var hab_nome : String = str(info.get("hab_nome", "Habilidade"))
	var lv1_marca : String = "OK" if adquirido else "BLOQ"
	linhas.append("%s LV1 - Núcleo inicial: %s liberado." % [lv1_marca, hab_nome])
	var evols : Dictionary = PET_EVOLUCOES.get(pid, {}) as Dictionary
	for lv in range(2, 6):
		var etapa : Dictionary = evols.get(lv, {}) as Dictionary
		if etapa.is_empty():
			continue
		var liberado : bool = adquirido and nivel_atual >= lv
		var marca : String = "OK" if liberado else "BLOQ"
		var custo : int = pet_cartas_necessarias(pid, lv - 1)
		var custo_txt : String = "" if liberado else "  [%d cartas]" % custo
		linhas.append("%s LV%d - %s: %s%s" % [
			marca,
			lv,
			str(etapa.get("nome", "")),
			str(etapa.get("desc", "")),
			custo_txt,
		])
	return "\n".join(linhas)


func ganhar_cartas_pet(pid: String, qtd: int) -> void:
	if not PETS_INFO.has(pid) or qtd <= 0:
		return
	pet_cartas[pid] = maxi(0, int(pet_cartas.get(pid, 0)) + qtd)


func pode_evoluir_pet(pid: String) -> bool:
	if not PETS_INFO.has(pid) or not _pet_desbloqueado(pid):
		return false
	var nivel : int = pet_nivel(pid)
	if nivel >= 5:
		return false
	var necessario : int = pet_cartas_necessarias(pid, nivel)
	return int(pet_cartas.get(pid, 0)) >= necessario


func evoluir_pet(pid: String) -> bool:
	if not pode_evoluir_pet(pid):
		return false
	var nivel : int = pet_nivel(pid)
	var necessario : int = pet_cartas_necessarias(pid, nivel)
	pet_cartas[pid] = maxi(0, int(pet_cartas.get(pid, 0)) - necessario)
	pet_niveis[pid] = clampi(nivel + 1, 1, 5)
	salvar()
	return true

func _upload_nuvem() -> void:
	if nome_jogador != "" and senha_jogador != "" and not save_bloqueado and not _rename_em_curso:
		RankingOnline.upload_save(nome_jogador, exportar_cloud())


## Apaga o arquivo local. Chamado após upload cloud bem-sucedido.
## Só apaga se o jogador tem credenciais (pode buscar save da nuvem na próxima abertura).
func apagar_save_local() -> void:
	if nome_jogador == "" or senha_jogador == "":
		return
	var path := _save_path()
	if FileAccess.file_exists(path):
		var dir := DirAccess.open("user://")
		if dir:
			dir.remove(path.get_file())


func _agendar_upload() -> void:
	_cloud_timer   = 5.0   # sobe na nuvem 5s após o último salvar()
	_cloud_pendente = true


func comprar_revive_loja() -> bool:
	if revive_loja_estoque >= REVIVE_LOJA_MAX: return false
	if ouro_banco < REVIVE_LOJA_CUSTO: return false
	ouro_banco -= REVIVE_LOJA_CUSTO
	revive_loja_estoque += 1
	salvar()
	return true


func usar_revive_loja() -> bool:
	if revive_loja_estoque <= 0: return false
	revive_loja_estoque -= 1
	normalizar_cons_equipados()
	salvar()
	return true


func comprar_orbe_cura() -> bool:
	if orbe_cura_estoque >= ORBE_CURA_MAX: return false
	if ouro_banco < ORBE_CURA_CUSTO: return false
	ouro_banco -= ORBE_CURA_CUSTO
	orbe_cura_estoque += 1
	salvar()
	return true

func usar_orbe_cura() -> bool:
	if orbe_cura_estoque <= 0: return false
	orbe_cura_estoque -= 1
	normalizar_cons_equipados()
	salvar()
	return true


func comprar_cristal_barreira() -> bool:
	if cristal_barreira_estoque >= CRISTAL_BARREIRA_MAX: return false
	if ouro_banco < CRISTAL_BARREIRA_CUSTO: return false
	ouro_banco -= CRISTAL_BARREIRA_CUSTO
	cristal_barreira_estoque += 1
	salvar()
	return true

func usar_cristal_barreira() -> bool:
	if cristal_barreira_estoque <= 0: return false
	cristal_barreira_estoque -= 1
	normalizar_cons_equipados()
	salvar()
	return true


func comprar_runa_furia() -> bool:
	if runa_furia_estoque >= RUNA_FURIA_MAX: return false
	if ouro_banco < RUNA_FURIA_CUSTO: return false
	ouro_banco -= RUNA_FURIA_CUSTO
	runa_furia_estoque += 1
	salvar()
	return true

func usar_runa_furia() -> bool:
	if runa_furia_estoque <= 0: return false
	runa_furia_estoque -= 1
	normalizar_cons_equipados()
	salvar()
	return true


func comprar_pet(pid: String) -> bool:
	if pid in pets_desbloqueados: return false
	var info : Dictionary = PETS_INFO.get(pid, {}) as Dictionary
	if info.is_empty(): return false
	if info.get("premium", false) == true: return false
	var custo : int = int(info.get("custo", 0))
	if ouro_banco < custo: return false
	ouro_banco -= custo
	pets_desbloqueados.append(pid)
	pet_niveis[pid] = int(pet_niveis.get(pid, 1))
	pet_cartas[pid] = int(pet_cartas.get(pid, 0))
	if pets_desbloqueados.size() == 1:
		pet_ativo = pid
	salvar()
	return true


func equipar_pet(pid: String) -> void:
	if pet_desbloqueado(pid):
		pet_ativo = pid
		salvar()


func comprar_carga_habil(id: String) -> bool:
	if not HABIL_INFO.has(id): return false
	var custo : int = (HABIL_INFO[id] as Dictionary)["custo_cristal"] as int
	if cristais < custo: return false
	var atual : int = habil_cargas.get(id, 0) as int
	if atual >= 3: return false
	cristais -= custo
	habil_cargas[id] = atual + 1
	salvar()
	return true


func usar_habil(id: String) -> bool:
	var atual : int = habil_cargas.get(id, 0) as int
	if atual <= 0: return false
	habil_cargas[id] = atual - 1
	salvar()
	return true


var _cloud_timer     : float = 0.0
var _cloud_pendente  : bool  = false
var _rename_em_curso : bool  = false   # bloqueia uploads durante rename


func _ready() -> void:
	carregar()
	if credenciais_versao < 1 and senha_jogador != "":
		credenciais_versao = 1   # marca migrado sem apagar credenciais
		salvar()


func _process(delta: float) -> void:
	if _cloud_pendente:
		_cloud_timer -= delta
		if _cloud_timer <= 0.0:
			_cloud_pendente = false
			_upload_nuvem()


func carregar() -> void:
	# Bootstrap: lê save.json para descobrir qual conta está ativa
	var path := SAVE_PATH_GUEST
	if FileAccess.file_exists(SAVE_PATH_GUEST):
		var pf := FileAccess.open(SAVE_PATH_GUEST, FileAccess.READ)
		var peek = JSON.parse_string(pf.get_as_text())
		pf.close()
		if peek is Dictionary:
			var pnome : String = (peek as Dictionary).get("nome_jogador", "") as String
			if pnome != "":
				var acc := _save_path_for(pnome)
				if FileAccess.file_exists(acc):
					path = acc
	if not FileAccess.file_exists(path):
		return
	var f    := FileAccess.open(path, FileAccess.READ)
	var data  = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary:
		return
	ouro_banco       = int(data.get("ouro_banco",       0))
	cristais         = int(data.get("cristais",         0))
	high_score       = int(data.get("high_score",       0))
	high_score_facil = int(data.get("high_score_facil", 0))
	for k in melhorias.keys():
		melhorias[k] = int(data.get(k, 0))
	var t = data.get("talentos", {})
	if t is Dictionary:
		for k in t.keys():
			talentos[k as String] = true
	# Stats globais
	total_partidas          = int(data.get("total_partidas",          0))
	partidas_facil          = int(data.get("partidas_facil",          0))
	partidas_normal         = int(data.get("partidas_normal",         0))
	partidas_dificil        = int(data.get("partidas_dificil",        0))
	total_mobs_mortos       = int(data.get("total_mobs_mortos",       0))
	total_boss_mortos       = int(data.get("total_boss_mortos",       0))
	total_waves_completadas = int(data.get("total_waves_completadas", 0))
	total_ouro_ganho        = int(data.get("total_ouro_ganho",        0))
	total_score             = int(data.get("total_score",             0))
	melhor_wave             = int(data.get("melhor_wave",             0))
	melhor_wave_facil       = int(data.get("melhor_wave_facil",       0))
	melhor_wave_normal      = int(data.get("melhor_wave_normal",      0))
	melhor_wave_dificil     = int(data.get("melhor_wave_dificil",     0))
	melhor_wave_abismo      = int(data.get("melhor_wave_abismo",      0))
	# Retrocompat: preenche wave apenas nas dificuldades que têm score mas não têm wave.
	# Usa melhor_wave como estimativa — impreciso mas melhor que apagar tudo do ranking.
	if melhor_wave > 0:
		if melhor_wave_facil   == 0 and high_score_facil   > 0: melhor_wave_facil   = melhor_wave
		if melhor_wave_normal  == 0 and high_score_normal  > 0: melhor_wave_normal  = melhor_wave
		if melhor_wave_dificil == 0 and high_score_dificil > 0: melhor_wave_dificil = melhor_wave
		if melhor_wave_abismo  == 0 and high_score_abismo  > 0: melhor_wave_abismo  = melhor_wave
	var tc = data.get("total_cartas", {})
	if tc is Dictionary:
		for k in (tc as Dictionary).keys():
			total_cartas[k as String] = int((tc as Dictionary)[k])
	pausa_auto_wave      = data.get("pausa_auto_wave",      false) == true
	volume_sfx           = clampf(float(data.get("volume_sfx",    1.0)),  0.0, 1.0)
	volume_musica        = clampf(float(data.get("volume_musica", 0.55)), 0.0, 1.0)
	dificuldade          = clampi(int(data.get("dificuldade", 1)), 0, 2)
	mapa_teste_id        = str(data.get("mapa_teste_id", "setor_inicial"))
	if mapa_info(mapa_teste_id).is_empty():
		mapa_teste_id = "setor_inicial"
	acessibilidade_ativo = data.get("acessibilidade_ativo", false) == true
	tts_api_key          = data.get("tts_api_key", "") as String
	tts_voz              = data.get("tts_voz", "pt-BR-Neural2-A") as String
	nome_jogador          = data.get("nome_jogador",    "") as String
	email_jogador         = data.get("email_jogador",   "") as String
	senha_jogador         = data.get("senha_jogador",   "") as String
	player_id             = data.get("player_id",       "") as String
	id_sequencial         = int(data.get("id_sequencial",  0))
	nome_ja_renomeado     = data.get("nome_ja_renomeado", false) == true
	credenciais_versao    = int(data.get("credenciais_versao", 0))
	ultimo_check_ranking  = int(data.get("ultimo_check_ranking", 0))
	ranking_temporada_premiada = int(data.get("ranking_temporada_premiada", -1))
	discord_reward_claimed = data.get("discord_reward_claimed", false) == true
	avatar_idx            = clampi(int(data.get("avatar_idx", 0)), 0, 4)
	ascensoes         = int(data.get("ascensoes", 0))
	nivel_conta       = maxi(1, int(data.get("nivel_conta", 1)))
	xp_conta          = maxi(0, int(data.get("xp_conta", 0)))
	pontos_atributo   = maxi(0, int(data.get("pontos_atributo", 0)))
	var ac_data = data.get("atributos_conta", {})
	if ac_data is Dictionary:
		for aid_conta in ATRIBUTOS_CONTA_IDS:
			atributos_conta[aid_conta] = int((ac_data as Dictionary).get(aid_conta, atributos_conta.get(aid_conta, 0)))
	normalizar_progressao_conta()
	high_score_abismo = int(data.get("high_score_abismo", 0))
	var bd = data.get("baus_estoque", {"comum": 0, "raro": 0, "epico": 0, "lendario": 0})
	if bd is Dictionary:
		for bk in baus_estoque.keys():
			baus_estoque[bk] = int((bd as Dictionary).get(bk, 0))
	elif bd is int:
		baus_estoque["comum"] = int(bd)
	var aid = data.get("arsenal_itens_desbloqueados", arsenal_itens_desbloqueados)
	if aid is Array:
		arsenal_itens_desbloqueados = aid as Array
	var aeq = data.get("arsenal_equipado", {"canhao":"", "nucleo":"", "blindagem":"", "reliquia":""})
	if aeq is Dictionary:
		arsenal_equipado = aeq as Dictionary
	arsenal_autoequip_migrado = data.get("arsenal_autoequip_migrado", false) == true
	if arsenal_equipado == {"canhao":"canhao_plasma", "nucleo":"nucleo_vital", "blindagem":"placa_lunar", "reliquia":"fragmento_lunar"}:
		arsenal_equipado = {"canhao":"", "nucleo":"", "blindagem":"", "reliquia":""}
	migrar_arsenal_autoequip_antigo()
	normalizar_arsenal()
	high_score_normal  = int(data.get("high_score_normal",  0))
	high_score_dificil = int(data.get("high_score_dificil", 0))
	# Retrocompatibilidade: popula normal/dificil a partir do high_score antigo se zerados
	if high_score_normal == 0 and high_score_dificil == 0 and high_score > 0:
		high_score_normal  = high_score
		high_score_dificil = high_score
	var hp_arr = data.get("historico_partidas", [])
	if hp_arr is Array:
		historico_partidas = hp_arr as Array
	skin_ativa = data.get("skin_ativa", "padrao") as String
	var sd = data.get("skins_desbloqueadas", ["padrao"])
	if sd is Array:
		skins_desbloqueadas = sd as Array
	if not "padrao" in skins_desbloqueadas:
		skins_desbloqueadas.append("padrao")
	var pc = data.get("premium_comprados", [])
	if pc is Array:
		premium_comprados = pc as Array
	var hc = data.get("habil_cargas", {})
	if hc is Dictionary:
		for k in habil_cargas.keys():
			habil_cargas[k] = clampi(int((hc as Dictionary).get(k, 0)), 0, 3)
	revive_loja_estoque     = clampi(int(data.get("revive_loja_estoque",     0)), 0, REVIVE_LOJA_MAX)
	orbe_cura_estoque       = clampi(int(data.get("orbe_cura_estoque",       0)), 0, ORBE_CURA_MAX)
	cristal_barreira_estoque= clampi(int(data.get("cristal_barreira_estoque",0)), 0, CRISTAL_BARREIRA_MAX)
	runa_furia_estoque      = clampi(int(data.get("runa_furia_estoque",      0)), 0, RUNA_FURIA_MAX)
	var _ce = data.get("cons_equipados", [])
	if _ce is Array: cons_equipados = (_ce as Array).slice(0, 3)
	normalizar_cons_equipados()
	pet_ia_comprado     = data.get("pet_ia_comprado", false) == true
	var pd = data.get("pets_desbloqueados", [])
	if pd is Array: pets_desbloqueados = pd as Array
	if pet_ia_comprado and not ("cyron" in pets_desbloqueados):
		pets_desbloqueados.append("cyron")
	pet_ativo = str(data.get("pet_ativo", ""))
	if not (pet_ativo in pets_desbloqueados) and not pets_desbloqueados.is_empty():
		pet_ativo = pets_desbloqueados[0] as String
	var pcd = data.get("pet_cartas", {})
	if pcd is Dictionary: pet_cartas = pcd as Dictionary
	var pnd = data.get("pet_niveis", {})
	if pnd is Dictionary: pet_niveis = pnd as Dictionary
	_normalizar_pet_progressao()
	normalizar_pet_ativo()
	versao_max_jogada    = int(data.get("versao_max_jogada", 0))
	tutorial_concluido   = data.get("tutorial_concluido", false) == true
	tutorial_menu_visto  = data.get("tutorial_menu_visto", false) == true
	tutorial_jogo_visto  = data.get("tutorial_jogo_visto", false) == true
	if versao_max_jogada > VERSAO_SAVE:
		save_bloqueado = true
	var rcp = data.get("run_checkpoint", {})
	run_checkpoint = rcp if rcp is Dictionary else {}
	# Arquivo dedicado tem precedência (mais recente, sobrevive hot-reload)
	if FileAccess.file_exists(CHECKPOINT_PATH):
		var _cf2 := FileAccess.open(CHECKPOINT_PATH, FileAccess.READ)
		if _cf2 != null:
			var _p2 = JSON.parse_string(_cf2.get_as_text())
			_cf2.close()
			if _p2 is Dictionary and not (_p2 as Dictionary).is_empty():
				run_checkpoint = _p2 as Dictionary


func salvar(nuvem: bool = true) -> void:
	if nuvem: _agendar_upload()
	_salvar_disco()


func _salvar_disco() -> void:
	var data : Dictionary = {
		"ouro_banco":       ouro_banco,
		"cristais":         cristais,
		"high_score":       high_score,
		"high_score_facil": high_score_facil,
		"talentos":   talentos,
		# Stats globais
		"total_partidas":          total_partidas,
		"partidas_facil":          partidas_facil,
		"partidas_normal":         partidas_normal,
		"partidas_dificil":        partidas_dificil,
		"total_mobs_mortos":       total_mobs_mortos,
		"total_boss_mortos":       total_boss_mortos,
		"total_waves_completadas": total_waves_completadas,
		"total_ouro_ganho":        total_ouro_ganho,
		"total_score":             total_score,
		"melhor_wave":             melhor_wave,
		"melhor_wave_facil":       melhor_wave_facil,
		"melhor_wave_normal":      melhor_wave_normal,
		"melhor_wave_dificil":     melhor_wave_dificil,
		"melhor_wave_abismo":      melhor_wave_abismo,
		"total_cartas":            total_cartas,
		"pausa_auto_wave":      pausa_auto_wave,
		"volume_sfx":           volume_sfx,
		"volume_musica":        volume_musica,
		"dificuldade":          dificuldade,
		"mapa_teste_id":        mapa_teste_id,
		"acessibilidade_ativo": acessibilidade_ativo,
		"tts_api_key":          tts_api_key,
		"tts_voz":              tts_voz,
		"nome_jogador":         nome_jogador,
		"email_jogador":        email_jogador,
		"senha_jogador":        senha_jogador,
		"player_id":            player_id,
		"id_sequencial":        id_sequencial,
		"nome_ja_renomeado":    nome_ja_renomeado,
		"credenciais_versao":   credenciais_versao,
		"ultimo_check_ranking": ultimo_check_ranking,
		"ranking_temporada_premiada": ranking_temporada_premiada,
		"discord_reward_claimed": discord_reward_claimed,
		"avatar_idx":           avatar_idx,
		"ascensoes":           ascensoes,
		"nivel_conta":         nivel_conta,
		"xp_conta":            xp_conta,
		"pontos_atributo":     pontos_atributo,
		"atributos_conta":     atributos_conta,
		"baus_estoque":        baus_estoque,
		"arsenal_itens_desbloqueados": arsenal_itens_desbloqueados,
		"arsenal_equipado":    arsenal_equipado,
		"arsenal_autoequip_migrado": arsenal_autoequip_migrado,
		"high_score_abismo":   high_score_abismo,
		"high_score_normal":   high_score_normal,
		"high_score_dificil":  high_score_dificil,
		"historico_partidas":  historico_partidas,
		"skin_ativa":          skin_ativa,
		"skins_desbloqueadas": skins_desbloqueadas,
		"premium_comprados":   premium_comprados,
		"habil_cargas":           habil_cargas,
		"revive_loja_estoque":     revive_loja_estoque,
		"orbe_cura_estoque":       orbe_cura_estoque,
		"cristal_barreira_estoque":cristal_barreira_estoque,
		"runa_furia_estoque":      runa_furia_estoque,
		"cons_equipados":          cons_equipados,
		"pet_ia_comprado":         pet_ia_comprado,
		"pets_desbloqueados":     pets_desbloqueados,
		"pet_ativo":              pet_ativo,
		"pet_cartas":             pet_cartas,
		"pet_niveis":             pet_niveis,
		"tutorial_concluido":     tutorial_concluido,
		"tutorial_menu_visto":    tutorial_menu_visto,
		"tutorial_jogo_visto":    tutorial_jogo_visto,
		"versao_max_jogada":      max(versao_max_jogada, VERSAO_SAVE),
		"run_checkpoint":         run_checkpoint,
	}
	for k in melhorias.keys():
		data[k] = melhorias[k]
	var f := FileAccess.open(_save_path(), FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	# Mantém save.json como ponteiro de conta (bootstrap na próxima abertura)
	if nome_jogador != "" and _save_path() != SAVE_PATH_GUEST:
		var stub := FileAccess.open(SAVE_PATH_GUEST, FileAccess.WRITE)
		stub.store_string(JSON.stringify({"nome_jogador": nome_jogador}))
		stub.close()


func registrar_fim_partida(wave: int, score_val: int, ouro: int,
		mobs: int, bosses: int, cartas: Dictionary, abismo: bool = false) -> void:
	total_partidas          += 1
	if not abismo:
		match dificuldade:
			0: partidas_facil   += 1
			1: partidas_normal  += 1
			2: partidas_dificil += 1
	total_mobs_mortos       += mobs
	total_boss_mortos       += bosses
	total_waves_completadas += wave
	total_ouro_ganho        += ouro
	total_score             += score_val
	if wave > melhor_wave:
		melhor_wave = wave
	var diff_idx_wave : int = 3 if abismo else dificuldade
	match diff_idx_wave:
		0:
			if wave > melhor_wave_facil:   melhor_wave_facil   = wave
		1:
			if wave > melhor_wave_normal:  melhor_wave_normal  = wave
		2:
			if wave > melhor_wave_dificil: melhor_wave_dificil = wave
		3:
			if wave > melhor_wave_abismo:  melhor_wave_abismo  = wave
	for cid in cartas.keys():
		var qtd : int = cartas[cid] as int
		total_cartas[cid] = (total_cartas.get(cid, 0) as int) + qtd
	# Histórico: guarda as últimas 5 partidas
	var diff_idx : int = 3 if abismo else dificuldade  # 0=Fácil 1=Normal 2=Difícil 3=Abismo
	var entrada := {
		"wave": wave, "score": score_val, "mobs": mobs, "bosses": bosses,
		"dificuldade": diff_idx,
		"timestamp": int(Time.get_unix_time_from_system()),
	}
	historico_partidas.append(entrada)
	historico_partidas.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if historico_partidas.size() > 10:
		historico_partidas.resize(10)
	ganhar_xp_conta(calcular_xp_partida_conta(wave, score_val, mobs, abismo), false)
	salvar()


func normalizar_progressao_conta() -> void:
	nivel_conta = maxi(1, nivel_conta)
	xp_conta = maxi(0, xp_conta)
	pontos_atributo = maxi(0, pontos_atributo)
	for id in ATRIBUTOS_CONTA_IDS:
		var info : Dictionary = ATRIBUTOS_CONTA_INFO[id] as Dictionary
		atributos_conta[id] = clampi(int(atributos_conta.get(id, 0)), 0, int(info.get("max", 0)))


func xp_para_proximo_nivel(nivel: int = -1) -> int:
	var n : int = nivel_conta if nivel <= 0 else nivel
	return 180 + n * 70 + n * n * 3


func patente_conta() -> String:
	var atual : String = "Recruta Orbital"
	for p in PATENTES_CONTA:
		var pd : Dictionary = p as Dictionary
		if nivel_conta >= int(pd.get("nivel", 1)):
			atual = str(pd.get("nome", atual))
	return atual


func proxima_patente_conta() -> Dictionary:
	for p in PATENTES_CONTA:
		var pd : Dictionary = p as Dictionary
		if nivel_conta < int(pd.get("nivel", 1)):
			return pd
	return {}


func calcular_xp_partida_conta(wave: int, score_val: int, mobs: int, abismo: bool = false) -> int:
	var base : int = max(0, wave) * 18 + max(0, mobs) * 2 + int(max(0, score_val) / 140)
	if abismo:
		base = int(float(base) * 1.25) + 80
	return clampi(base, 25, 6500)


func ganhar_xp_conta(qtd: int, salvar_agora: bool = true) -> Dictionary:
	normalizar_progressao_conta()
	var ganho : int = maxi(0, qtd)
	if ganho <= 0:
		return {"xp": 0, "levels": 0}
	var nivel_antes : int = nivel_conta
	xp_conta += ganho
	while xp_conta >= xp_para_proximo_nivel():
		xp_conta -= xp_para_proximo_nivel()
		nivel_conta += 1
		pontos_atributo += 1
	var levels : int = nivel_conta - nivel_antes
	if salvar_agora:
		salvar()
	return {"xp": ganho, "levels": levels}


func gastar_ponto_atributo(id: String) -> bool:
	normalizar_progressao_conta()
	if pontos_atributo <= 0 or not ATRIBUTOS_CONTA_INFO.has(id):
		return false
	var info : Dictionary = ATRIBUTOS_CONTA_INFO[id] as Dictionary
	var atual : int = int(atributos_conta.get(id, 0))
	if atual >= int(info.get("max", 0)):
		return false
	atributos_conta[id] = atual + 1
	pontos_atributo -= 1
	salvar()
	return true


func total_pontos_atributos() -> int:
	var total : int = 0
	for id in ATRIBUTOS_CONTA_IDS:
		total += int(atributos_conta.get(id, 0))
	return total


func bonus_atributos_conta() -> Dictionary:
	normalizar_progressao_conta()
	return {
		"vida_flat": float(int(atributos_conta.get("vida", 0))) * 8.0,
		"dano_mult": 1.0 + float(int(atributos_conta.get("dano", 0))) * 0.01,
		"reducao_dano": float(int(atributos_conta.get("defesa", 0))) * 0.003,
		"cadencia_mult": 1.0 + float(int(atributos_conta.get("agilidade", 0))) * 0.006,
		"alcance_flat": float(int(atributos_conta.get("alcance", 0))) * 3.0,
		"ouro_mult": float(int(atributos_conta.get("fortuna", 0))) * 0.01,
		"crit_chance": float(int(atributos_conta.get("critico", 0))) * 0.0025,
		"cooldown_mult": -float(int(atributos_conta.get("tecnologia", 0))) * 0.004,
	}


func depositar_ouro(qtd: int) -> void:
	ouro_banco += qtd
	salvar()


# ── Soft-cap de renda ─────────────────────────────────────────────────────────
# Diminishing returns sobre o GANHO de ouro de uma partida quando o banco ja esta
# alto. Jogador novo (saldo < THRESHOLD) nunca e afetado: recebe 100%.
const RENDA_SOFTCAP_THRESHOLD : int   = 200000   # acima disso o ganho comeca a cair
const RENDA_SOFTCAP_FATOR_MIN : float = 0.25     # piso: nunca converte menos que 25%

func fator_renda(saldo_atual: int) -> float:
	if saldo_atual <= RENDA_SOFTCAP_THRESHOLD:
		return 1.0
	return clampf(float(RENDA_SOFTCAP_THRESHOLD) / float(saldo_atual), RENDA_SOFTCAP_FATOR_MIN, 1.0)

func ajustar_ganho_ouro(saldo_inicio: int, ganho: int) -> int:
	# Soft-cap so se aplica a ganho positivo (gastos na partida nao sao penalizados).
	if ganho <= 0:
		return ganho
	return int(round(float(ganho) * fator_renda(saldo_inicio)))


func aplicar_premio_bot(tipo: String, qtd: int) -> bool:
	if qtd <= 0:
		return false
	match tipo:
		"ouro":
			ouro_banco += qtd
		"cristais":
			cristais += qtd
		"orbe":
			orbe_cura_estoque = clampi(orbe_cura_estoque + qtd, 0, ORBE_CURA_MAX)
		"barreira":
			cristal_barreira_estoque = clampi(cristal_barreira_estoque + qtd, 0, CRISTAL_BARREIRA_MAX)
		"runa":
			runa_furia_estoque = clampi(runa_furia_estoque + qtd, 0, RUNA_FURIA_MAX)
		"bau_lendario":
			baus_estoque["lendario"] = int(baus_estoque.get("lendario", 0)) + qtd
		_:
			return false
	salvar()
	return true


func aplicar_premio_temporada(posicao: int, temporada: int, baus_lendarios: int, cristais_bonus: int) -> bool:
	if temporada < 0 or posicao < 1 or posicao > 3:
		return false
	if ranking_temporada_premiada >= temporada:
		return false
	baus_estoque["lendario"] = int(baus_estoque.get("lendario", 0)) + max(0, baus_lendarios)
	cristais += max(0, cristais_bonus)
	ranking_temporada_premiada = temporada
	salvar()
	return true


func depositar_cristais(qtd: int) -> void:
	cristais += qtd
	salvar()


func total_baus() -> int:
	var total : int = 0
	for k in baus_estoque.keys():
		total += int(baus_estoque[k])
	return total


func mapa_info(id: String) -> Dictionary:
	for mapa in MAPAS_TORRE:
		var md : Dictionary = mapa as Dictionary
		if str(md.get("id", "")) == id:
			return md
	return MAPAS_TORRE[0] as Dictionary


func mapa_por_wave(w: int) -> Dictionary:
	if w <= 0:
		return MAPAS_TORRE[0] as Dictionary
	for mapa in MAPAS_TORRE:
		var md : Dictionary = mapa as Dictionary
		if w >= int(md.get("wave_ini", 1)) and w <= int(md.get("wave_fim", 9999)):
			return md
	return MAPAS_TORRE[MAPAS_TORRE.size() - 1] as Dictionary


func mapa_final_ativo(w: int) -> bool:
	if w <= 0:
		return false
	var mapa : Dictionary = mapa_por_wave(w)
	var fim : int = int(mapa.get("wave_fim", 9999))
	if fim >= 9999:
		return w >= int(mapa.get("wave_ini", 1)) and w % 50 == 0
	return w == fim


func mapa_teste_info() -> Dictionary:
	return mapa_info(mapa_teste_id)


func bau_por_wave(w: int) -> String:
	if w >= 100 and w % 100 == 0:
		return "lendario"
	if w >= 50 and w % 50 == 0:
		return "epico"
	if w >= 20 and w % 20 == 0:
		return "raro"
	return "comum"


func ganhar_bau(qtd: int = 1, nivel: String = "comum") -> void:
	if not baus_estoque.has(nivel):
		nivel = "comum"
	baus_estoque[nivel] = max(0, int(baus_estoque.get(nivel, 0)) + qtd)
	salvar()


func _raridade_bau(nivel: String) -> String:
	var chances : Dictionary = {
		"comum": {"comum": 72, "raro": 23, "epico": 5, "lendario": 0},
		"raro": {"comum": 42, "raro": 42, "epico": 14, "lendario": 2},
		"epico": {"comum": 18, "raro": 42, "epico": 32, "lendario": 8},
		"lendario": {"comum": 0, "raro": 28, "epico": 45, "lendario": 27},
	}
	var tab : Dictionary = chances.get(nivel, chances["comum"]) as Dictionary
	var r : int = randi_range(1, 100)
	var acc : int = 0
	for rar in ["comum", "raro", "epico", "lendario"]:
		acc += int(tab.get(rar, 0))
		if r <= acc:
			return rar
	return "comum"


func _bau_mult(nivel: String, raridade: String) -> int:
	var base : int = {"comum": 1, "raro": 2, "epico": 4, "lendario": 8}.get(nivel, 1)
	var rar_mult : int = {"comum": 1, "raro": 2, "epico": 3, "lendario": 5}.get(raridade, 1)
	return maxi(1, base * rar_mult)


func _bau_slots(nivel: String) -> int:
	return {"comum": 3, "raro": 4, "epico": 5, "lendario": 6}.get(nivel, 3)


func _bau_raridade_peso(raridade: String) -> int:
	return {"comum": 0, "raro": 1, "epico": 2, "lendario": 3}.get(raridade, 0)


func _bau_add_recompensa(recompensas: Array, tipo: String, nome: String, qtd: int, raridade: String = "comum", extra: Dictionary = {}) -> void:
	if qtd <= 0:
		return
	var rar : String = raridade
	if not (rar in ["comum", "raro", "epico", "lendario"]):
		rar = "comum"
	for i in range(recompensas.size()):
		var r : Dictionary = recompensas[i] as Dictionary
		if str(r.get("tipo", "")) == tipo and str(r.get("nome", "")) == nome:
			r["qtd"] = int(r.get("qtd", 0)) + qtd
			var rar_atual : String = str(r.get("raridade", "comum"))
			if _bau_raridade_peso(rar) > _bau_raridade_peso(rar_atual):
				r["raridade"] = rar
			for extra_key in extra.keys():
				r[extra_key] = extra[extra_key]
			recompensas[i] = r
			return
	var nova : Dictionary = {"tipo": tipo, "nome": nome, "qtd": qtd, "raridade": rar}
	for extra_key in extra.keys():
		nova[extra_key] = extra[extra_key]
	recompensas.append(nova)


func _bau_reward_recurso(recompensas: Array, nivel: String, raridade: String) -> void:
	var mult : int = _bau_mult(nivel, raridade)
	var ouro_g : int = randi_range(900, 2500) * mult
	var cris_g : int = maxi(1, randi_range(1, 3) * maxi(1, mult / 2))
	ouro_banco += ouro_g
	cristais += cris_g
	_bau_add_recompensa(recompensas, "ouro", "Ouro", ouro_g, raridade)
	_bau_add_recompensa(recompensas, "cristais", "Cristais", cris_g, raridade)


func _bau_reward_arsenal(recompensas: Array, raridade: String) -> bool:
	var candidatos_por_raridade : Dictionary = {}
	for iid in ARSENAL_INFO.keys():
		var sid : String = str(iid)
		if sid in arsenal_itens_desbloqueados:
			continue
		var info : Dictionary = ARSENAL_INFO[sid] as Dictionary
		var rar_item : String = str(info.get("raridade", "comum"))
		if not candidatos_por_raridade.has(rar_item):
			candidatos_por_raridade[rar_item] = []
		(candidatos_por_raridade[rar_item] as Array).append(sid)
	if candidatos_por_raridade.is_empty():
		return false

	var peso_raridade : Dictionary = {}
	match raridade:
		"lendario":
			peso_raridade = {"epico": 55, "lendario": 45}
		"epico":
			peso_raridade = {"raro": 42, "epico": 42, "lendario": 16}
		"raro":
			peso_raridade = {"comum": 50, "raro": 40, "epico": 10}
		_:
			peso_raridade = {"comum": 86, "raro": 14}

	var raridades_validas : Array = []
	var total_peso : int = 0
	for rar in peso_raridade.keys():
		var sr : String = str(rar)
		if candidatos_por_raridade.has(sr) and not (candidatos_por_raridade[sr] as Array).is_empty():
			raridades_validas.append(sr)
			total_peso += int(peso_raridade[sr])

	var pool : Array = []
	if total_peso > 0:
		var roll : int = randi_range(1, total_peso)
		var acc : int = 0
		for rar in raridades_validas:
			acc += int(peso_raridade[rar])
			if roll <= acc:
				pool = candidatos_por_raridade[rar] as Array
				break
	else:
		for lista in candidatos_por_raridade.values():
			for iid2 in (lista as Array):
				pool.append(iid2)

	if pool.is_empty():
		return false
	var novo_id : String = str(pool[randi() % pool.size()])
	arsenal_itens_desbloqueados.append(novo_id)
	normalizar_arsenal()
	var info_novo : Dictionary = ARSENAL_INFO[novo_id] as Dictionary
	_bau_add_recompensa(recompensas, "arsenal", str(info_novo.get("nome", novo_id)), 1, str(info_novo.get("raridade", raridade)), {"arsenal_id": novo_id})
	return true


func _bau_reward_especial(recompensas: Array, nivel: String, raridade: String) -> bool:
	var peso : Dictionary = {}
	match raridade:
		"lendario":
			peso = {"arsenal": 22, "skin": 22, "pet": 18, "habil": 14, "pet_card": 14, "cons": 6, "bau": 4}
		"epico":
			peso = {"arsenal": 18, "skin": 14, "pet": 12, "habil": 20, "pet_card": 18, "cons": 14, "bau": 4}
		"raro":
			peso = {"arsenal": 12, "skin": 8, "pet": 6, "habil": 24, "pet_card": 22, "cons": 23, "bau": 5}
		_:
			peso = {"habil": 18, "pet_card": 24, "cons": 34, "arsenal": 8, "bau": 3, "recurso": 13}
	var total : int = 0
	for k in peso.keys():
		total += int(peso[k])
	var roll : int = randi_range(1, maxi(1, total))
	var acc : int = 0
	var escolha : String = "recurso"
	for k in peso.keys():
		acc += int(peso[k])
		if roll <= acc:
			escolha = str(k)
			break

	match escolha:
		"skin":
			var skins : Array = []
			for sid in SKINS_INFO.keys():
				var ss : String = sid as String
				var info_s : Dictionary = SKINS_INFO[ss] as Dictionary
				if ss != "padrao" and ss != "saberpunk" and not (info_s.get("premium", false) == true) and not (ss in skins_desbloqueadas):
					skins.append(ss)
			if not skins.is_empty():
				var sid_new : String = skins[randi() % skins.size()] as String
				skins_desbloqueadas.append(sid_new)
				_bau_add_recompensa(recompensas, "skin", str((SKINS_INFO[sid_new] as Dictionary).get("nome", sid_new)), 1, raridade, {"sid": sid_new})
				return true
		"arsenal":
			if _bau_reward_arsenal(recompensas, raridade):
				return true
		"pet":
			var pets : Array = []
			for pid in PETS_INFO.keys():
				var ps : String = pid as String
				var info_p : Dictionary = PETS_INFO[ps] as Dictionary
				if not (info_p.get("premium", false) == true) and not (ps in pets_desbloqueados):
					pets.append(ps)
			if not pets.is_empty():
				var pid_new : String = pets[randi() % pets.size()] as String
				pets_desbloqueados.append(pid_new)
				pet_niveis[pid_new] = int(pet_niveis.get(pid_new, 1))
				pet_cartas[pid_new] = int(pet_cartas.get(pid_new, 0))
				if pets_desbloqueados.size() == 1:
					pet_ativo = pid_new
				_bau_add_recompensa(recompensas, "pet", str((PETS_INFO[pid_new] as Dictionary).get("nome", pid_new)), 1, raridade, {"pid": pid_new})
				return true
		"habil":
			var hids : Array = HABIL_INFO.keys()
			var hid : String = hids[randi() % hids.size()] as String
			var carga_g : int = 1 if raridade in ["comum", "raro"] else 2
			habil_cargas[hid] = clampi(int(habil_cargas.get(hid, 0)) + carga_g, 0, 3)
			_bau_add_recompensa(recompensas, "habil", str((HABIL_INFO[hid] as Dictionary).get("nome", hid)), carga_g, raridade, {"hid": hid})
			return true
		"pet_card":
			var pid_cards : String = pet_ativo
			if pid_cards == "" or not _pet_desbloqueado(pid_cards):
				if not pets_desbloqueados.is_empty():
					pid_cards = pets_desbloqueados[randi() % pets_desbloqueados.size()] as String
			if pid_cards != "" and _pet_desbloqueado(pid_cards):
				var cartas_g : int = {"comum": 3, "raro": 8, "epico": 18, "lendario": 42}.get(raridade, 3)
				ganhar_cartas_pet(pid_cards, cartas_g)
				var pn : String = str((PETS_INFO.get(pid_cards, {}) as Dictionary).get("nome", "Comandante"))
				_bau_add_recompensa(recompensas, "pet_card", "Cartas de %s" % pn, cartas_g, raridade, {"pid": pid_cards})
				return true
		"cons":
			var cons : Array = ["orbe", "barreira", "runa", "vela"]
			var cid : String = cons[randi() % cons.size()] as String
			var qtd_c : int = 1 if raridade in ["comum", "raro"] else 2
			match cid:
				"orbe":
					var antes_o := orbe_cura_estoque
					orbe_cura_estoque = clampi(orbe_cura_estoque + qtd_c, 0, ORBE_CURA_MAX)
					_bau_add_recompensa(recompensas, "cons", "Orbe de Cura", orbe_cura_estoque - antes_o, raridade, {"cons_id": "orbe"})
				"barreira":
					var antes_b := cristal_barreira_estoque
					cristal_barreira_estoque = clampi(cristal_barreira_estoque + qtd_c, 0, CRISTAL_BARREIRA_MAX)
					_bau_add_recompensa(recompensas, "cons", "Cristal Barreira", cristal_barreira_estoque - antes_b, raridade, {"cons_id": "barreira"})
				"runa":
					var antes_r := runa_furia_estoque
					runa_furia_estoque = clampi(runa_furia_estoque + qtd_c, 0, RUNA_FURIA_MAX)
					_bau_add_recompensa(recompensas, "cons", "Runa de Furia", runa_furia_estoque - antes_r, raridade, {"cons_id": "runa"})
				"vela":
					var antes_v := revive_loja_estoque
					revive_loja_estoque = clampi(revive_loja_estoque + 1, 0, REVIVE_LOJA_MAX)
					_bau_add_recompensa(recompensas, "cons", "Vela da Alma", revive_loja_estoque - antes_v, raridade, {"cons_id": "vela"})
			return true
		"bau":
			var next_bau : String = "comum"
			if raridade == "lendario":
				next_bau = "epico"
			elif raridade == "epico":
				next_bau = "raro"
			baus_estoque[next_bau] = int(baus_estoque.get(next_bau, 0)) + 1
			_bau_add_recompensa(recompensas, "bau", "Bau %s" % next_bau.capitalize(), 1, next_bau)
			return true
	_bau_reward_recurso(recompensas, nivel, raridade)
	return true


func _bau_preview_snapshot() -> Dictionary:
	return {
		"ouro_banco": ouro_banco,
		"cristais": cristais,
		"melhorias": melhorias.duplicate(true),
		"baus_estoque": baus_estoque.duplicate(true),
		"arsenal_itens_desbloqueados": arsenal_itens_desbloqueados.duplicate(true),
		"arsenal_equipado": arsenal_equipado.duplicate(true),
		"arsenal_autoequip_migrado": arsenal_autoequip_migrado,
		"skin_ativa": skin_ativa,
		"skins_desbloqueadas": skins_desbloqueadas.duplicate(true),
		"habil_cargas": habil_cargas.duplicate(true),
		"revive_loja_estoque": revive_loja_estoque,
		"orbe_cura_estoque": orbe_cura_estoque,
		"cristal_barreira_estoque": cristal_barreira_estoque,
		"runa_furia_estoque": runa_furia_estoque,
		"cons_equipados": cons_equipados.duplicate(true),
		"pet_ia_comprado": pet_ia_comprado,
		"pets_desbloqueados": pets_desbloqueados.duplicate(true),
		"pet_ativo": pet_ativo,
		"pet_cartas": pet_cartas.duplicate(true),
		"pet_niveis": pet_niveis.duplicate(true),
	}


func _bau_restore_preview_snapshot(snapshot: Dictionary) -> void:
	ouro_banco = int(snapshot.get("ouro_banco", ouro_banco))
	cristais = int(snapshot.get("cristais", cristais))
	melhorias = (snapshot.get("melhorias", melhorias) as Dictionary).duplicate(true)
	baus_estoque = (snapshot.get("baus_estoque", baus_estoque) as Dictionary).duplicate(true)
	arsenal_itens_desbloqueados = (snapshot.get("arsenal_itens_desbloqueados", arsenal_itens_desbloqueados) as Array).duplicate(true)
	arsenal_equipado = (snapshot.get("arsenal_equipado", arsenal_equipado) as Dictionary).duplicate(true)
	arsenal_autoequip_migrado = bool(snapshot.get("arsenal_autoequip_migrado", arsenal_autoequip_migrado))
	skin_ativa = str(snapshot.get("skin_ativa", skin_ativa))
	skins_desbloqueadas = (snapshot.get("skins_desbloqueadas", skins_desbloqueadas) as Array).duplicate(true)
	habil_cargas = (snapshot.get("habil_cargas", habil_cargas) as Dictionary).duplicate(true)
	revive_loja_estoque = int(snapshot.get("revive_loja_estoque", revive_loja_estoque))
	orbe_cura_estoque = int(snapshot.get("orbe_cura_estoque", orbe_cura_estoque))
	cristal_barreira_estoque = int(snapshot.get("cristal_barreira_estoque", cristal_barreira_estoque))
	runa_furia_estoque = int(snapshot.get("runa_furia_estoque", runa_furia_estoque))
	cons_equipados = (snapshot.get("cons_equipados", cons_equipados) as Array).duplicate(true)
	pet_ia_comprado = bool(snapshot.get("pet_ia_comprado", pet_ia_comprado))
	pets_desbloqueados = (snapshot.get("pets_desbloqueados", pets_desbloqueados) as Array).duplicate(true)
	pet_ativo = str(snapshot.get("pet_ativo", pet_ativo))
	pet_cartas = (snapshot.get("pet_cartas", pet_cartas) as Dictionary).duplicate(true)
	pet_niveis = (snapshot.get("pet_niveis", pet_niveis) as Dictionary).duplicate(true)


func abrir_bau(nivel: String = "comum", preview: bool = false) -> Dictionary:
	if not baus_estoque.has(nivel):
		nivel = "comum"
	var snapshot : Dictionary = {}
	if preview:
		snapshot = _bau_preview_snapshot()
		baus_estoque[nivel] = maxi(1, int(baus_estoque.get(nivel, 0)))
	elif int(baus_estoque.get(nivel, 0)) <= 0:
		return {}
	baus_estoque[nivel] = int(baus_estoque[nivel]) - 1
	var raridade : String = _raridade_bau(nivel)
	var recompensas : Array = []
	_bau_reward_recurso(recompensas, nivel, raridade)
	var slots : int = _bau_slots(nivel)
	for i in range(maxi(1, slots - 2)):
		var slot_rar : String = raridade if i == 0 else _raridade_bau(nivel)
		_bau_reward_especial(recompensas, nivel, slot_rar)
	normalizar_cons_equipados()
	if preview:
		_bau_restore_preview_snapshot(snapshot)
		return {"nivel": nivel, "raridade": raridade, "recompensas": recompensas, "preview": true}
	salvar()
	return {"nivel": nivel, "raridade": raridade, "recompensas": recompensas}


func atualizar_high_score(score: int) -> void:
	if dificuldade == 0:
		# Fácil: salva no ranking separado para não contaminar Normal/Difícil
		if score > high_score_facil:
			high_score_facil = score
			salvar()
	elif dificuldade == 1:
		if score > high_score_normal:
			high_score_normal = score
		if score > high_score:
			high_score = score
		salvar()
	else:  # Difícil
		if score > high_score_dificil:
			high_score_dificil = score
		if score > high_score:
			high_score = score
		salvar()


func talento_ativo(id: String) -> bool:
	if id == "raiz":
		return true
	return talentos.get(id, false) as bool


func requisitos_talento(id: String) -> Array:
	if not TALENTOS_INFO.has(id):
		return []
	var info: Dictionary = TALENTOS_INFO[id] as Dictionary
	var reqs: Array = []
	var base_reqs: Array = info.get("req", []) as Array
	for req_any in base_reqs:
		var req_id: String = req_any as String
		if req_id != "" and not reqs.has(req_id):
			reqs.append(req_id)
	var extra_reqs: Array = TALENTOS_REQ_EXTRA.get(id, []) as Array
	for req_any in extra_reqs:
		var extra_req_id: String = req_any as String
		if extra_req_id != "" and not reqs.has(extra_req_id):
			reqs.append(extra_req_id)
	return reqs


func legado_debug_liberado() -> bool:
	return DEBUG_LIBERAR_TALENTOS_LEGADO and OS.is_debug_build()


func custo_efetivo_talento(id: String) -> int:
	if not TALENTOS_INFO.has(id):
		return 0
	var info : Dictionary = TALENTOS_INFO[id] as Dictionary
	var base_cost : int = info["custo"] as int
	if base_cost == 0:
		return 0
	# Apenas nós de ramo escalam (+5 por talento já comprado no mesmo ramo)
	var br : String = id[0]
	var custo_final : int = base_cost
	if br not in ["p","r","f","e","s","m","g","b","t","x"]:
		return _custo_com_desconto_ascensao(custo_final)
	var count : int = 0
	for tid in talentos.keys():
		var ts : String = tid as String
		if ts.length() > 0 and ts[0] == br:
			count += 1
	custo_final += count * 5
	return _custo_com_desconto_ascensao(custo_final)


func _custo_com_desconto_ascensao(custo_base: int) -> int:
	if custo_base <= 0:
		return 0
	var desconto : float = float(bonus_ascensao_stats().get("talento_desconto", 0.0))
	if desconto <= 0.0:
		return custo_base
	return maxi(1, int(ceil(float(custo_base) * (1.0 - desconto))))


func pode_comprar_talento(id: String) -> bool:
	if id == "raiz" or talento_ativo(id):
		return false
	if not TALENTOS_INFO.has(id):
		return false
	var custo : int        = custo_efetivo_talento(id)
	if cristais < custo:
		return false
	var reqs : Array = requisitos_talento(id)
	for r in reqs:
		if not talento_ativo(r as String):
			return false
	# Verificação de conquistas para nós de Legado
	match id:
		"veteran": return legado_debug_liberado() or total_partidas >= 100
		"genoci":  return legado_debug_liberado() or total_mobs_mortos >= 10000
		"sobrev":  return legado_debug_liberado() or melhor_wave >= 30
	return true


func comprar_talento(id: String) -> bool:
	if not pode_comprar_talento(id):
		return false
	var custo : int = custo_efetivo_talento(id)
	cristais     -= custo
	talentos[id]  = true
	salvar()
	return true


func reembolso_talentos() -> int:
	var total := 0
	for tid in talentos.keys():
		var id := tid as String
		if not talento_ativo(id) or not TALENTOS_INFO.has(id):
			continue
		var info := TALENTOS_INFO[id] as Dictionary
		total += _custo_com_desconto_ascensao(info["custo"] as int)
	return total


func redefinir_talentos() -> int:
	var reembolso := reembolso_talentos()
	if talentos.is_empty():
		return 0
	talentos.clear()
	cristais += reembolso
	salvar()
	return reembolso


func pode_jogar_normal() -> bool:
	return partidas_facil >= 10

func pode_jogar_dificil() -> bool:
	return partidas_normal >= 15

func pode_acessar_abismo() -> bool:
	return melhor_wave_dificil >= 30

func requisito_normal() -> String:
	if pode_jogar_normal(): return ""
	return "Jogue 10 partidas no\nModo Fácil  (%d/10)" % partidas_facil

func requisito_dificil() -> String:
	if pode_jogar_dificil(): return ""
	if not pode_jogar_normal():
		return "Desbloqueie o Normal\nprimeiro"
	return "Jogue 15 partidas no\nModo Normal  (%d/15)" % partidas_normal

func requisito_abismo() -> String:
	if pode_acessar_abismo(): return ""
	return "Chegue na wave 30 no\nModo Difícil  (melhor: %d)" % melhor_wave_dificil


func atualizar_high_score_abismo(score: int) -> void:
	if score > high_score_abismo:
		high_score_abismo = score
		salvar()


func pode_comprar_skin(id: String) -> bool:
	if not SKINS_INFO.has(id): return false
	if id == "saberpunk": return false
	if id in skins_desbloqueadas:  return false   # já tem
	if (SKINS_INFO[id] as Dictionary).get("premium", false) == true: return false
	var custo : int = (SKINS_INFO[id] as Dictionary)["custo"] as int
	return ouro_banco >= custo


func comprar_skin(id: String) -> bool:
	if not pode_comprar_skin(id): return false
	var custo : int = (SKINS_INFO[id] as Dictionary)["custo"] as int
	ouro_banco -= custo
	skins_desbloqueadas.append(id)
	salvar()
	return true


func premium_ja_comprado(id: String) -> bool:
	return id in premium_comprados


func liberar_premium(id: String) -> bool:
	if not PREMIUM_INFO.has(id): return false
	var info : Dictionary = PREMIUM_INFO[id] as Dictionary
	var tipo : String = str(info.get("tipo", ""))
	var unlock : String = str(info.get("unlock", ""))
	if not (id in premium_comprados):
		premium_comprados.append(id)
	match tipo:
		"skin":
			if unlock != "" and not (unlock in skins_desbloqueadas):
				skins_desbloqueadas.append(unlock)
		"pet":
			if unlock != "" and not (unlock in pets_desbloqueados):
				pets_desbloqueados.append(unlock)
				pet_niveis[unlock] = int(pet_niveis.get(unlock, 1))
				pet_cartas[unlock] = int(pet_cartas.get(unlock, 0))
		"pack":
			ouro_banco += int(info.get("ouro", 0))
			cristais += int(info.get("cristais", 0))
			orbe_cura_estoque = clampi(orbe_cura_estoque + int(info.get("orbe", 0)), 0, ORBE_CURA_MAX)
			cristal_barreira_estoque = clampi(cristal_barreira_estoque + int(info.get("cristal", 0)), 0, CRISTAL_BARREIRA_MAX)
			runa_furia_estoque = clampi(runa_furia_estoque + int(info.get("runa", 0)), 0, RUNA_FURIA_MAX)
	normalizar_cons_equipados()
	salvar()
	return true


func equipar_skin(id: String) -> void:
	if id in skins_desbloqueadas:
		skin_ativa = id
		salvar()


func talentos_necessarios_ascensao() -> int:
	return maxi(0, TALENTOS_INFO.size() - 1)


func talentos_liberados_para_ascensao() -> int:
	var total : int = 0
	for tid in TALENTOS_INFO.keys():
		var ts : String = str(tid)
		if ts != "raiz" and talento_ativo(ts):
			total += 1
	return total


func todos_talentos_liberados() -> bool:
	return talentos_liberados_para_ascensao() >= talentos_necessarios_ascensao()


func ascensao_custo_moedas(nivel: int = -1) -> int:
	var n : int = ascensoes if nivel < 0 else maxi(0, nivel - 1)
	return ASCENSAO_CUSTO_MOEDA_BASE + (n * ASCENSAO_CUSTO_MOEDA_POR_NIVEL)


func ascensao_custo_cristais(nivel: int = -1) -> int:
	var n : int = ascensoes if nivel < 0 else maxi(0, nivel - 1)
	return ASCENSAO_CUSTO_CRISTAIS_BASE + (n * ASCENSAO_CUSTO_CRISTAIS_POR_NIVEL)


func ascensao_custo_texto(nivel: int = -1) -> String:
	var custo_cristais : int = ascensao_custo_cristais(nivel)
	return "%d cristais + arvore completa (ZERA ouro e melhorias)" % custo_cristais


func bonus_ascensao_stats(nivel: int = -1) -> Dictionary:
	var n : int = ascensoes if nivel < 0 else maxi(0, nivel)
	return {
		"dano_mult": 1.0 + minf(ASCENSAO_MAX_DANO_VIDA, float(n) * ASCENSAO_DANO_VIDA_POR_NIVEL),
		"vida_mult": 1.0 + minf(ASCENSAO_MAX_DANO_VIDA, float(n) * ASCENSAO_DANO_VIDA_POR_NIVEL),
		"cadencia_mult": 1.0 + minf(ASCENSAO_MAX_CADENCIA, float(n) * ASCENSAO_CADENCIA_POR_NIVEL),
		"ouro_mult": minf(ASCENSAO_MAX_OURO_CRISTAIS, float(n) * ASCENSAO_OURO_CRISTAIS_POR_NIVEL),
		"cristais_mult": 1.0 + minf(ASCENSAO_MAX_OURO_CRISTAIS, float(n) * ASCENSAO_OURO_CRISTAIS_POR_NIVEL),
		"talento_desconto": minf(ASCENSAO_MAX_DESCONTO_TALENTOS, float(n) * ASCENSAO_DESCONTO_TALENTOS_POR_NIVEL),
	}


func ascensao_bonus_texto(nivel: int = -1) -> String:
	var b : Dictionary = bonus_ascensao_stats(nivel)
	return "+%.1f%% dano/vida | +%.1f%% cad. | +%.0f%% ouro/cristais | -%.0f%% talentos" % [
		(float(b.get("dano_mult", 1.0)) - 1.0) * 100.0,
		(float(b.get("cadencia_mult", 1.0)) - 1.0) * 100.0,
		float(b.get("ouro_mult", 0.0)) * 100.0,
		float(b.get("talento_desconto", 0.0)) * 100.0,
	]


func ascensao_refund_preview() -> int:
	return 0


func pode_ascender() -> bool:
	# Ouro deixa de ser exigido: a ascensão ZERA o ouro de qualquer forma.
	# Gate = árvore completa + cristais suficientes (cristais é o custo premium).
	return todos_talentos_liberados() and cristais >= ascensao_custo_cristais()


func ascender() -> bool:
	if not pode_ascender():
		return false
	var custo_cristais : int = ascensao_custo_cristais()
	cristais -= custo_cristais
	# ── Prestígio: reset de progressão re-construível ─────────────────────────
	# ZERA: ouro do banco, árvore de talentos, melhorias de loja.
	# MANTÉM: cristais, skins, baús, consumíveis, atributos/nível de conta,
	#         estatísticas/recordes e o bônus permanente de ascensão.
	ouro_banco = 0
	talentos.clear()
	for k in melhorias.keys():
		melhorias[k] = 0
	ascensoes += 1
	salvar()
	return true


func pode_comprar(tipo: String) -> bool:
	var lvl   : int        = melhorias.get(tipo, 0) as int
	if lvl >= MAX_LVL:
		return false
	var info  : Dictionary = LOJA_INFO[tipo] as Dictionary
	var custos : Array     = info["custos"] as Array
	var custo  : int       = custos[lvl] as int
	return ouro_banco >= custo


func comprar(tipo: String) -> bool:
	if not pode_comprar(tipo):
		return false
	var lvl    : int        = melhorias.get(tipo, 0) as int
	var info   : Dictionary = LOJA_INFO[tipo] as Dictionary
	var custos : Array      = info["custos"] as Array
	var custo  : int        = custos[lvl] as int
	ouro_banco      -= custo
	melhorias[tipo]  = lvl + 1
	salvar()
	return true


func limpar_dados() -> void:
	ouro_banco              = 0
	cristais                = 0
	high_score              = 0
	high_score_facil        = 0
	high_score_normal       = 0
	high_score_dificil      = 0
	high_score_abismo       = 0
	ascensoes               = 0
	nivel_conta             = 1
	xp_conta                = 0
	pontos_atributo         = 0
	for aid_conta in ATRIBUTOS_CONTA_IDS:
		atributos_conta[aid_conta] = 0
	for k in melhorias.keys(): melhorias[k] = 0
	talentos                = {}
	total_partidas          = 0
	partidas_facil          = 0
	partidas_normal         = 0
	partidas_dificil        = 0
	total_mobs_mortos       = 0
	total_boss_mortos       = 0
	total_waves_completadas = 0
	total_ouro_ganho        = 0
	total_score             = 0
	melhor_wave             = 0
	melhor_wave_facil       = 0
	melhor_wave_normal      = 0
	melhor_wave_dificil     = 0
	melhor_wave_abismo      = 0
	total_cartas            = {}
	historico_partidas      = []
	ranking_temporada_premiada = -1
	dificuldade             = 1
	mapa_teste_id           = "setor_inicial"
	avatar_idx              = 0
	skin_ativa              = "padrao"
	skins_desbloqueadas     = ["padrao"]
	premium_comprados       = []
	baus_estoque            = {"comum": 0, "raro": 0, "epico": 0, "lendario": 0}
	arsenal_itens_desbloqueados = []
	arsenal_equipado        = {"canhao":"", "nucleo":"", "blindagem":"", "reliquia":""}
	arsenal_autoequip_migrado = true
	habil_cargas            = {"eletrico": 0, "gelo": 0, "devastador": 0}
	revive_loja_estoque      = 0
	orbe_cura_estoque        = 0
	cristal_barreira_estoque = 0
	runa_furia_estoque       = 0
	cons_equipados          = []
	pet_ia_comprado          = false
	pets_desbloqueados      = []
	pet_ativo               = ""
	pet_cartas              = {}
	pet_niveis              = {}
	versao_max_jogada       = 0
	save_bloqueado          = false
	abismo_modo_ativo       = false
	_cloud_pendente         = false
	_cloud_timer            = 0.0


func resetar() -> void:
	var path := _save_path()
	limpar_dados()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func exportar_cloud() -> Dictionary:
	var data : Dictionary = {
		"ouro_banco": ouro_banco, "cristais": cristais,
		"baus_estoque": baus_estoque,
		"arsenal_itens_desbloqueados": arsenal_itens_desbloqueados,
		"arsenal_equipado": arsenal_equipado,
		"arsenal_autoequip_migrado": arsenal_autoequip_migrado,
		"high_score": high_score, "high_score_facil": high_score_facil,
		"high_score_normal": high_score_normal, "high_score_dificil": high_score_dificil,
		"high_score_abismo": high_score_abismo,
		"melhorias": melhorias, "talentos": talentos, "ascensoes": ascensoes,
		"nivel_conta": nivel_conta, "xp_conta": xp_conta,
		"pontos_atributo": pontos_atributo, "atributos_conta": atributos_conta,
		"total_partidas": total_partidas, "total_mobs_mortos": total_mobs_mortos,
		"total_boss_mortos": total_boss_mortos,
		"total_waves_completadas": total_waves_completadas,
		"total_ouro_ganho": total_ouro_ganho, "total_score": total_score,
		"melhor_wave": melhor_wave,
		"melhor_wave_facil": melhor_wave_facil, "melhor_wave_normal": melhor_wave_normal,
		"melhor_wave_dificil": melhor_wave_dificil, "melhor_wave_abismo": melhor_wave_abismo,
		"total_cartas": total_cartas,
		"skin_ativa": skin_ativa, "skins_desbloqueadas": skins_desbloqueadas,
		"premium_comprados": premium_comprados,
		"habil_cargas": habil_cargas, "historico_partidas": historico_partidas,
		"avatar_idx": avatar_idx,
		"ranking_temporada_premiada": ranking_temporada_premiada,
		"discord_reward_claimed": discord_reward_claimed,
		"revive_loja_estoque": revive_loja_estoque,
		"orbe_cura_estoque": orbe_cura_estoque,
		"cristal_barreira_estoque": cristal_barreira_estoque,
		"runa_furia_estoque": runa_furia_estoque,
		"cons_equipados": cons_equipados,
		"pet_ia_comprado": pet_ia_comprado,
		"pets_desbloqueados": pets_desbloqueados,
		"pet_cartas": pet_cartas,
		"pet_niveis": pet_niveis,
		"dificuldade": dificuldade,
		"mapa_teste_id": mapa_teste_id,
		"versao_max_jogada": max(versao_max_jogada, VERSAO_SAVE),
		"run_checkpoint": run_checkpoint,
	}
	return data


func importar_cloud(dados: Dictionary) -> void:
	# Rejeita save da nuvem se veio de versão superior à atual
	var versao_nuvem : int = int(dados.get("versao_max_jogada", 0))
	if versao_nuvem > VERSAO_SAVE:
		push_warning("Cloud save requer v%d (atual: v%d) — import bloqueado." % [versao_nuvem, VERSAO_SAVE])
		return
	ouro_banco          = max(ouro_banco,          int(dados.get("ouro_banco",          0)))
	cristais            = max(cristais,             int(dados.get("cristais",            0)))
	var bd_imp = dados.get("baus_estoque", {})
	if bd_imp is Dictionary:
		for bk in baus_estoque.keys():
			baus_estoque[bk] = max(int(baus_estoque[bk]), int((bd_imp as Dictionary).get(bk, 0)))
	var aid_imp = dados.get("arsenal_itens_desbloqueados", [])
	if aid_imp is Array:
		for iid in (aid_imp as Array):
			var sid_i : String = str(iid)
			if ARSENAL_INFO.has(sid_i) and not sid_i in arsenal_itens_desbloqueados:
				arsenal_itens_desbloqueados.append(sid_i)
	var aeq_imp = dados.get("arsenal_equipado", {})
	if aeq_imp is Dictionary:
		for slot_i in ARSENAL_SLOTS:
			var slot_s : String = str(slot_i)
			var eq_i : String = str((aeq_imp as Dictionary).get(slot_s, ""))
			if ARSENAL_INFO.has(eq_i) and eq_i in arsenal_itens_desbloqueados:
				arsenal_equipado[slot_s] = eq_i
	if dados.get("arsenal_autoequip_migrado", false) == true:
		arsenal_autoequip_migrado = true
	if dados.get("discord_reward_claimed", false) == true:
		discord_reward_claimed = true
	migrar_arsenal_autoequip_antigo()
	normalizar_arsenal()
	high_score          = max(high_score,           int(dados.get("high_score",          0)))
	high_score_facil    = max(high_score_facil,     int(dados.get("high_score_facil",    0)))
	high_score_normal   = max(high_score_normal,    int(dados.get("high_score_normal",   0)))
	high_score_dificil  = max(high_score_dificil,   int(dados.get("high_score_dificil",  0)))
	high_score_abismo   = max(high_score_abismo,    int(dados.get("high_score_abismo",   0)))
	ascensoes           = max(ascensoes,            int(dados.get("ascensoes",           0)))
	nivel_conta         = max(nivel_conta,          int(dados.get("nivel_conta",         1)))
	xp_conta            = max(xp_conta,             int(dados.get("xp_conta",            0)))
	pontos_atributo     = max(pontos_atributo,      int(dados.get("pontos_atributo",     0)))
	var ac_imp = dados.get("atributos_conta", {})
	if ac_imp is Dictionary:
		for aid_conta in ATRIBUTOS_CONTA_IDS:
			atributos_conta[aid_conta] = max(int(atributos_conta.get(aid_conta, 0)), int((ac_imp as Dictionary).get(aid_conta, 0)))
	normalizar_progressao_conta()
	total_partidas          = max(total_partidas,          int(dados.get("total_partidas",          0)))
	total_mobs_mortos       = max(total_mobs_mortos,       int(dados.get("total_mobs_mortos",       0)))
	total_boss_mortos       = max(total_boss_mortos,       int(dados.get("total_boss_mortos",       0)))
	total_waves_completadas = max(total_waves_completadas, int(dados.get("total_waves_completadas", 0)))
	total_ouro_ganho        = max(total_ouro_ganho,        int(dados.get("total_ouro_ganho",        0)))
	total_score             = max(total_score,             int(dados.get("total_score",             0)))
	melhor_wave             = max(melhor_wave,             int(dados.get("melhor_wave",             0)))
	melhor_wave_facil       = max(melhor_wave_facil,       int(dados.get("melhor_wave_facil",       0)))
	melhor_wave_normal      = max(melhor_wave_normal,      int(dados.get("melhor_wave_normal",      0)))
	melhor_wave_dificil     = max(melhor_wave_dificil,     int(dados.get("melhor_wave_dificil",     0)))
	melhor_wave_abismo      = max(melhor_wave_abismo,      int(dados.get("melhor_wave_abismo",      0)))
	var m = dados.get("melhorias", {})
	if m is Dictionary:
		for k in melhorias.keys():
			melhorias[k] = max(melhorias[k] as int, int((m as Dictionary).get(k, 0)))
	var t = dados.get("talentos", {})
	if t is Dictionary:
		for k in (t as Dictionary).keys():
			talentos[k as String] = true
	var tc = dados.get("total_cartas", {})
	if tc is Dictionary:
		for k in (tc as Dictionary).keys():
			total_cartas[k as String] = max(total_cartas.get(k as String, 0) as int, int((tc as Dictionary)[k]))
	var sd = dados.get("skins_desbloqueadas", [])
	if sd is Array:
		for sid in (sd as Array):
			if not sid in skins_desbloqueadas:
				skins_desbloqueadas.append(sid)
	var pc = dados.get("premium_comprados", [])
	if pc is Array:
		for pid_p in (pc as Array):
			if not pid_p in premium_comprados:
				premium_comprados.append(pid_p)
	var sa = dados.get("skin_ativa", "")
	if sa is String and sa != "": skin_ativa = sa as String
	var hc = dados.get("habil_cargas", {})
	if hc is Dictionary:
		for k in habil_cargas.keys():
			habil_cargas[k] = clampi(max(habil_cargas[k] as int, int((hc as Dictionary).get(k, 0))), 0, 3)
	var hp = dados.get("historico_partidas", [])
	if hp is Array and (hp as Array).size() > historico_partidas.size():
		historico_partidas = hp as Array
	var ai = dados.get("avatar_idx", -1)
	if int(ai) >= 0: avatar_idx = clampi(int(ai), 0, 4)
	ranking_temporada_premiada = max(ranking_temporada_premiada, int(dados.get("ranking_temporada_premiada", -1)))
	revive_loja_estoque      = clampi(max(revive_loja_estoque,      int(dados.get("revive_loja_estoque",      0))), 0, REVIVE_LOJA_MAX)
	orbe_cura_estoque        = clampi(max(orbe_cura_estoque,        int(dados.get("orbe_cura_estoque",        0))), 0, ORBE_CURA_MAX)
	cristal_barreira_estoque = clampi(max(cristal_barreira_estoque, int(dados.get("cristal_barreira_estoque", 0))), 0, CRISTAL_BARREIRA_MAX)
	runa_furia_estoque       = clampi(max(runa_furia_estoque,       int(dados.get("runa_furia_estoque",       0))), 0, RUNA_FURIA_MAX)
	var ce = dados.get("cons_equipados", cons_equipados)
	if ce is Array:
		cons_equipados = (ce as Array).slice(0, 3)
	normalizar_cons_equipados()
	if dados.get("pet_ia_comprado", false) == true: pet_ia_comprado = true
	var pd = dados.get("pets_desbloqueados", [])
	if pd is Array:
		for pid in (pd as Array):
			if not pid in pets_desbloqueados: pets_desbloqueados.append(pid)
	var pcd_imp = dados.get("pet_cartas", {})
	if pcd_imp is Dictionary:
		for pid in (pcd_imp as Dictionary).keys():
			pet_cartas[pid as String] = max(int(pet_cartas.get(pid as String, 0)), int((pcd_imp as Dictionary)[pid]))
	var pnd_imp = dados.get("pet_niveis", {})
	if pnd_imp is Dictionary:
		for pid in (pnd_imp as Dictionary).keys():
			pet_niveis[pid as String] = max(int(pet_niveis.get(pid as String, 1)), int((pnd_imp as Dictionary)[pid]))
	_normalizar_pet_progressao()
	normalizar_pet_ativo()
	var dif_nuvem : int = int(dados.get("dificuldade", -1))
	if dif_nuvem >= 0: dificuldade = clampi(dif_nuvem, 0, 3)
	var mapa_nuvem : String = str(dados.get("mapa_teste_id", ""))
	if mapa_nuvem != "":
		mapa_teste_id = str(mapa_info(mapa_nuvem).get("id", "setor_inicial"))
	salvar()


func importar_cloud_forcado(dados: Dictionary) -> void:
	ouro_banco              = int(dados.get("ouro_banco",              0))
	cristais                = int(dados.get("cristais",                0))
	var bd_forcado = dados.get("baus_estoque", {"comum": 0, "raro": 0, "epico": 0, "lendario": 0})
	if bd_forcado is Dictionary:
		for bk in baus_estoque.keys():
			baus_estoque[bk] = int((bd_forcado as Dictionary).get(bk, 0))
	var aid_forcado = dados.get("arsenal_itens_desbloqueados", arsenal_itens_desbloqueados)
	if aid_forcado is Array:
		arsenal_itens_desbloqueados = aid_forcado as Array
	var aeq_forcado = dados.get("arsenal_equipado", {"canhao":"", "nucleo":"", "blindagem":"", "reliquia":""})
	if aeq_forcado is Dictionary:
		arsenal_equipado = aeq_forcado as Dictionary
	arsenal_autoequip_migrado = dados.get("arsenal_autoequip_migrado", false) == true
	if arsenal_equipado == {"canhao":"canhao_plasma", "nucleo":"nucleo_vital", "blindagem":"placa_lunar", "reliquia":"fragmento_lunar"}:
		arsenal_equipado = {"canhao":"", "nucleo":"", "blindagem":"", "reliquia":""}
	migrar_arsenal_autoequip_antigo()
	normalizar_arsenal()
	high_score              = int(dados.get("high_score",              0))
	high_score_facil        = int(dados.get("high_score_facil",        0))
	high_score_normal       = int(dados.get("high_score_normal",       0))
	high_score_dificil      = int(dados.get("high_score_dificil",      0))
	high_score_abismo       = int(dados.get("high_score_abismo",       0))
	ascensoes               = int(dados.get("ascensoes",               0))
	nivel_conta             = maxi(1, int(dados.get("nivel_conta",     1)))
	xp_conta                = maxi(0, int(dados.get("xp_conta",        0)))
	pontos_atributo         = maxi(0, int(dados.get("pontos_atributo", 0)))
	var ac_forcado = dados.get("atributos_conta", {})
	if ac_forcado is Dictionary:
		for aid_conta in ATRIBUTOS_CONTA_IDS:
			atributos_conta[aid_conta] = int((ac_forcado as Dictionary).get(aid_conta, 0))
	normalizar_progressao_conta()
	total_partidas          = int(dados.get("total_partidas",          0))
	total_mobs_mortos       = int(dados.get("total_mobs_mortos",       0))
	total_boss_mortos       = int(dados.get("total_boss_mortos",       0))
	total_waves_completadas = int(dados.get("total_waves_completadas", 0))
	total_ouro_ganho        = int(dados.get("total_ouro_ganho",        0))
	total_score             = int(dados.get("total_score",             0))
	melhor_wave             = int(dados.get("melhor_wave",             0))
	melhor_wave_facil       = int(dados.get("melhor_wave_facil",       0))
	melhor_wave_normal      = int(dados.get("melhor_wave_normal",      0))
	melhor_wave_dificil     = int(dados.get("melhor_wave_dificil",     0))
	melhor_wave_abismo      = int(dados.get("melhor_wave_abismo",      0))
	var m = dados.get("melhorias", {})
	if m is Dictionary:
		for k in melhorias.keys():
			melhorias[k] = int((m as Dictionary).get(k, 0))
	var t = dados.get("talentos", {})
	talentos = {}
	if t is Dictionary:
		for k in (t as Dictionary).keys():
			talentos[k as String] = true
	var tc = dados.get("total_cartas", {})
	if tc is Dictionary: total_cartas = tc as Dictionary
	var sk = dados.get("skins_desbloqueadas", [])
	if sk is Array: skins_desbloqueadas = sk as Array
	var pc2 = dados.get("premium_comprados", [])
	if pc2 is Array: premium_comprados = pc2 as Array
	var sa = dados.get("skin_ativa", "padrao")
	if sa is String and (sa as String) in skins_desbloqueadas:
		skin_ativa = sa as String
	var hc = dados.get("habil_cargas", {})
	if hc is Dictionary: habil_cargas = hc as Dictionary
	var hp = dados.get("historico_partidas", [])
	if hp is Array: historico_partidas = hp as Array
	var ai = dados.get("avatar_idx", -1)
	if int(ai) >= 0: avatar_idx = clampi(int(ai), 0, 4)
	ranking_temporada_premiada = int(dados.get("ranking_temporada_premiada", -1))
	mapa_teste_id = str(mapa_info(str(dados.get("mapa_teste_id", mapa_teste_id))).get("id", "setor_inicial"))
	revive_loja_estoque      = clampi(int(dados.get("revive_loja_estoque",      0)), 0, REVIVE_LOJA_MAX)
	orbe_cura_estoque        = clampi(int(dados.get("orbe_cura_estoque",        0)), 0, ORBE_CURA_MAX)
	cristal_barreira_estoque = clampi(int(dados.get("cristal_barreira_estoque", 0)), 0, CRISTAL_BARREIRA_MAX)
	runa_furia_estoque       = clampi(int(dados.get("runa_furia_estoque",       0)), 0, RUNA_FURIA_MAX)
	var ce2 = dados.get("cons_equipados", cons_equipados)
	if ce2 is Array:
		cons_equipados = (ce2 as Array).slice(0, 3)
	normalizar_cons_equipados()
	pet_ia_comprado = dados.get("pet_ia_comprado", false) == true
	var pd2 = dados.get("pets_desbloqueados", [])
	if pd2 is Array: pets_desbloqueados = pd2 as Array
	var pcd2 = dados.get("pet_cartas", {})
	if pcd2 is Dictionary: pet_cartas = pcd2 as Dictionary
	var pnd2 = dados.get("pet_niveis", {})
	if pnd2 is Dictionary: pet_niveis = pnd2 as Dictionary
	_normalizar_pet_progressao()
	normalizar_pet_ativo()
	dificuldade = clampi(int(dados.get("dificuldade", 1)), 0, 3)
	salvar()


func bonus_texto(tipo: String, lvl: int) -> String:
	if lvl == 0:
		return ""
	match tipo:
		"forca":       return "Atual: +%d dano" % (lvl * 8)
		"resistencia": return "Atual: +%d HP" % (lvl * 40)
		"visao":       return "Atual: +%d alcance" % (lvl * 25)
		"cadencia":    return "Atual: +%.1f tiros/s" % (lvl * 0.2)
		"fortuna":     return "Atual: +%d%% ouro" % (lvl * 15)
	return ""
