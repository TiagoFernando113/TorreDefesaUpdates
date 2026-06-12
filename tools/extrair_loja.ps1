# Fase 2 da modularizacao: extrai o dominio LOJA do menu.gd para scripts/menu/loja.gd
# Replaces derivados automaticamente: todo simbolo top-level do menu que NAO move vira m.<simbolo>
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)
$menuPath = "scripts\menu.gd"
$lines = [System.IO.File]::ReadAllLines($menuPath, $enc)
Write-Host "menu.gd linhas: $($lines.Count)"

# Ranges 1-based inclusivos:
#   vars _loja_* : 100-104
#   bloco loja   : 8442-10364 (_abrir_loja ... _fechar_loja)
function Slice($a, $start1, $end1) { return $a[($start1-1)..($end1-1)] }
$varsBloco = Slice $lines 100 104
$bloco     = Slice $lines 8442 10364

if ($varsBloco[0] -notmatch '_loja_overlay') { throw "ancora vars falhou: $($varsBloco[0])" }
if ($bloco[0] -notmatch 'func _abrir_loja')  { throw "ancora inicio falhou: $($bloco[0])" }
if ($bloco[-1] -match '^func ')              { throw "fim do bloco invadiu outra funcao" }
$tem_fechar = ($bloco | Select-String -Pattern '^func _fechar_loja').Count
if ($tem_fechar -ne 1) { throw "_fechar_loja nao esta no bloco" }

# Simbolos top-level do menu (func/var/const) ANTES da extracao
$simbolos = @{}
foreach ($l in $lines) {
	if ($l -match '^(func|var|const)\s+([A-Za-z_]\w*)') { $simbolos[$Matches[2]] = $true }
}
# Simbolos que MOVEM (definidos dentro do bloco/vars) — nao prefixar
$movem = @{}
foreach ($l in ($bloco + $varsBloco)) {
	if ($l -match '^(func|var|const)\s+([A-Za-z_]\w*)') { $movem[$Matches[2]] = $true }
}

$corpo = $bloco -join "`n"

# Conta e aplica m. nos simbolos do menu usados pelo bloco
$aplicados = @()
foreach ($s in $simbolos.Keys) {
	if ($movem.ContainsKey($s)) { continue }
	$rx = "(?<![\w.""'])" + [regex]::Escape($s) + "\b"
	if ([regex]::IsMatch($corpo, $rx)) {
		$corpo = [regex]::Replace($corpo, $rx, "m.$s")
		$aplicados += $s
	}
}
Write-Host "prefixados com m.: $($aplicados.Count) simbolos"
$aplicados | Sort-Object | ForEach-Object { Write-Host "  m.$_" }

# Metodos de Node que RefCounted nao tem
foreach ($met in @('get_viewport','get_tree','create_tween','set_meta','get_meta','has_meta','call_deferred','queue_redraw','is_inside_tree')) {
	$rx = "(?<![\w.])" + $met + "\("
	if ([regex]::IsMatch($corpo, $rx)) {
		$corpo = [regex]::Replace($corpo, $rx, "m.$met(")
		Write-Host "  m.$met() [metodo Node]"
	}
}

$hdr = @"
extends RefCounted
## Modulo do menu - tela de LOJA (Fase 2 da modularizacao).
## Estado da tela vive aqui; helpers compartilhados ficam no menu (acesso via m).
## Extraido de menu.gd em 2026-06-12 (tools/extrair_loja.ps1).

var m  # menu principal (menu.gd)

func _init(menu) -> void:
	m = menu


func limpar_refs() -> void:
	# Resize recria a UI inteira: solta as referencias sem queue_free
	_loja_overlay = null
	_loja_panel = null
	_loja_scroll_cont = null
	_loja_scroll_node = null


"@
$modulo = $hdr + ($varsBloco -join "`n") + "`n`n`n" + $corpo + "`n"
[System.IO.File]::WriteAllText("scripts\menu\loja.gd", $modulo, $enc)
Write-Host "modulo gravado: $((Get-Content scripts\menu\loja.gd).Count) linhas"

# Reconstroi menu.gd sem os blocos
$novo = New-Object System.Collections.Generic.List[string]
$novo.AddRange([string[]](Slice $lines 1 99))
$novo.Add("var _mod_loja = null  # modulo scripts/menu/loja.gd")
$novo.AddRange([string[]](Slice $lines 105 8441))
$novo.Add("func _abrir_loja(ui: CanvasLayer) -> void :")
$novo.Add("`t_mod_loja._abrir_loja(ui)")
$novo.Add("")
$novo.AddRange([string[]](Slice $lines 10365 $lines.Count))
$texto = ($novo -join "`n") + "`n"

$texto = $texto.Replace('const MENU_RANKING_MOD = preload("res://scripts/menu/ranking.gd")',
	'const MENU_RANKING_MOD = preload("res://scripts/menu/ranking.gd")' + "`n" + 'const MENU_LOJA_MOD = preload("res://scripts/menu/loja.gd")')
$texto = $texto.Replace("`t_mod_ranking = MENU_RANKING_MOD.new(self)`n",
	"`t_mod_ranking = MENU_RANKING_MOD.new(self)`n`t_mod_loja = MENU_LOJA_MOD.new(self)`n")

[System.IO.File]::WriteAllText($menuPath, $texto, $enc)
Write-Host "menu.gd reescrito: $((Get-Content $menuPath).Count) linhas"
