# Fase 1 da modularizacao: extrai o dominio RANKING do menu.gd para scripts/menu/ranking.gd
# Mecanico e auditavel — ranges fixos verificados manualmente em 2026-06-12.
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)
$menuPath = "scripts\menu.gd"
$lines = [System.IO.File]::ReadAllLines($menuPath, $enc)
Write-Host "menu.gd linhas: $($lines.Count)"

# Ranges 1-based inclusivos (validados por leitura):
#   vars _ranking_*           : 131-137
#   _on_premio_temporada_aplicado : 246-329
#   _abrir_ranking + _fechar_ranking : 4914-5234
#   _carregar_ranking/_atualizar_timestamp/_ranking_tempo_temporada_texto : 5602-5645
#   _on_ranking_carregado ... _draw_podio : 5687-6260
function Slice($a, $start1, $end1) { return $a[($start1-1)..($end1-1)] }

$varsBloco = Slice $lines 131 137
$blocoA = Slice $lines 246 329
$blocoB = Slice $lines 4914 5234
$blocoC = Slice $lines 5602 5645
$blocoD = Slice $lines 5687 6260

# Sanity checks: ancoras esperadas
if ($varsBloco[0] -notmatch '_ranking_overlay') { throw "ancora vars falhou: $($varsBloco[0])" }
if ($blocoA[0] -notmatch 'func _on_premio_temporada_aplicado') { throw "ancora A falhou: $($blocoA[0])" }
if ($blocoB[0] -notmatch 'func _abrir_ranking') { throw "ancora B falhou: $($blocoB[0])" }
if ($blocoC[0] -notmatch 'func _carregar_ranking') { throw "ancora C falhou: $($blocoC[0])" }
if ($blocoD[0] -notmatch 'func _on_ranking_carregado') { throw "ancora D falhou: $($blocoD[0])" }
if ($blocoD[-1] -match '^func ') { throw "fim de D invadiu outra funcao: $($blocoD[-1])" }

$corpo = ($blocoA -join "`n") + "`n`n`n" + ($blocoB -join "`n") + "`n`n`n" + ($blocoC -join "`n") + "`n`n`n" + ($blocoD -join "`n")

# Helpers compartilhados que FICAM no menu -> prefixo m.
$reps = @(
	@('(?<![\w.])_menu_contents\b',              'm._menu_contents'),
	@('(?<![\w.])_ui_title_label\(',             'm._ui_title_label('),
	@('(?<![\w.])_abrir_perfil\(',               'm._abrir_perfil('),
	@('(?<![\w.])_ui_main\b',                    'm._ui_main'),
	@('(?<![\w.])_format_num\(',                 'm._format_num('),
	@('(?<![\w.])_nivel_prestigio\(',            'm._nivel_prestigio('),
	@('(?<![\w.])_carregar_simbolo_prestigio\(', 'm._carregar_simbolo_prestigio('),
	@('(?<![\w.])_AVATAR_CORES\b',               'm._AVATAR_CORES'),
	@('(?<![\w.])_draw_avatar_icone\(',          'm._draw_avatar_icone('),
	@('(?<![\w.])_draw_text_centered\(',         'm._draw_text_centered('),
	@('(?<![\w.])get_viewport\(\)',              'm.get_viewport()'),
	@('(?<![\w.])get_tree\(\)',                  'm.get_tree()')
)
foreach ($r in $reps) { $corpo = [regex]::Replace($corpo, $r[0], $r[1]) }

$hdr = @"
extends RefCounted
## Modulo do menu — tela de RANKING GLOBAL (Fase 1 da modularizacao).
## Estado da tela vive aqui; helpers compartilhados ficam no menu (acesso via m).
## Extraido de menu.gd em 2026-06-12 (tools/extrair_ranking.ps1).

var m  # menu principal (menu.gd)

func _init(menu) -> void:
	m = menu


"@
$modulo = $hdr + ($varsBloco -join "`n") + "`n`n`n" + $corpo + "`n"
New-Item -ItemType Directory -Force scripts\menu | Out-Null
[System.IO.File]::WriteAllText("scripts\menu\ranking.gd", $modulo, $enc)
Write-Host "modulo gravado: $((Get-Content scripts\menu\ranking.gd).Count) linhas"

# Reconstroi menu.gd sem os blocos (indices 0-based)
$novo = New-Object System.Collections.Generic.List[string]
$novo.AddRange([string[]](Slice $lines 1 130))            # ate antes das vars
$novo.Add("var _mod_ranking = null  # modulo scripts/menu/ranking.gd")
$novo.AddRange([string[]](Slice $lines 138 245))          # depois das vars ate antes de A
$novo.AddRange([string[]](Slice $lines 330 4913))         # depois de A ate antes de B
$novo.Add("func _abrir_ranking(ui: CanvasLayer) -> void :")
$novo.Add("`t_mod_ranking._abrir_ranking(ui)")
$novo.Add("")
$novo.AddRange([string[]](Slice $lines 5235 5601))        # depois de B ate antes de C
$novo.AddRange([string[]](Slice $lines 5646 5686))        # depois de C ate antes de D
$novo.AddRange([string[]](Slice $lines 6261 $lines.Count))# depois de D
$texto = ($novo -join "`n") + "`n"

# Const do preload + init no _ready + connect apontando pro modulo
$texto = $texto.Replace('const TALENTOS_V2 = preload("res://scripts/talentos_v2.gd")',
	'const TALENTOS_V2 = preload("res://scripts/talentos_v2.gd")' + "`n" + 'const MENU_RANKING_MOD = preload("res://scripts/menu/ranking.gd")')
$texto = $texto.Replace("`t_configurar_discord_link()`n",
	"`t_configurar_discord_link()`n`t_mod_ranking = MENU_RANKING_MOD.new(self)`n")
$texto = $texto.Replace("premio_temporada_aplicado.is_connected(_on_premio_temporada_aplicado)",
	"premio_temporada_aplicado.is_connected(_mod_ranking._on_premio_temporada_aplicado)")
$texto = $texto.Replace("premio_temporada_aplicado.connect(_on_premio_temporada_aplicado)",
	"premio_temporada_aplicado.connect(_mod_ranking._on_premio_temporada_aplicado)")

[System.IO.File]::WriteAllText($menuPath, $texto, $enc)
Write-Host "menu.gd reescrito: $((Get-Content $menuPath).Count) linhas"
