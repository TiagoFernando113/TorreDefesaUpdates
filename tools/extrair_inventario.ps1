# Fase 3 da modularizacao: extrai INVENTARIO + BAUS do menu.gd para scripts/menu/inventario.gd
# Helpers de sprite/reward (usados por loja/perfil) FICAM no menu.
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)
$menuPath = "scripts\menu.gd"
$lines = [System.IO.File]::ReadAllLines($menuPath, $enc)
Write-Host "menu.gd linhas: $($lines.Count)"

function Slice($a, $start1, $end1) { return $a[($start1-1)..($end1-1)] }

# Ranges 1-based validados em 2026-06-12:
$vars1  = Slice $lines 84 97      # _inventario_* (estado/scroll/touch)
$vars2  = Slice $lines 102 103    # _inventario_overlay, _bau_abertura_overlay
$r1     = Slice $lines 282 364    # _handle_inventario_wheel/_aplicar_scroll_mochila/_limpar_scroll_mochila
$r2     = Slice $lines 2980 3682  # _abrir_baus, _abrir_bau_grande
$r3     = Slice $lines 6593 8437  # _abrir_inventario (1845 ln)

if ($vars1[0] -notmatch '_inventario_reselect_item') { throw "ancora vars1" }
if ($vars2[0] -notmatch '_inventario_overlay')       { throw "ancora vars2" }
if ($r1[0] -notmatch 'func _handle_inventario_wheel'){ throw "ancora r1" }
if ($r2[0] -notmatch 'func _abrir_baus')             { throw "ancora r2" }
if ($r3[0] -notmatch 'func _abrir_inventario')       { throw "ancora r3" }
foreach ($b in @($r1, $r2, $r3)) { if ($b[-1] -match '^func ') { throw "fim de bloco invadiu funcao" } }

# Consts/vars top-level alheias dentro dos blocos? (licao da fase 2)
foreach ($b in @($r2, $r3)) {
	foreach ($l in $b) {
		if ($l -match '^(const|var)\s+(\w+)' -and $l -notmatch '_inventario|_bau') {
			Write-Host "ATENCAO: decl top-level no bloco: $l"
		}
	}
}

$simbolos = @{}
foreach ($l in $lines) { if ($l -match '^(func|var|const)\s+([A-Za-z_]\w*)') { $simbolos[$Matches[2]] = $true } }
$movem = @{}
foreach ($l in ($vars1 + $vars2 + $r1 + $r2 + $r3)) {
	if ($l -match '^(func|var|const)\s+([A-Za-z_]\w*)') { $movem[$Matches[2]] = $true }
}

$corpo = ($r1 -join "`n") + "`n`n`n" + ($r2 -join "`n") + "`n`n`n" + ($r3 -join "`n")
$aplicados = @()
foreach ($s in $simbolos.Keys) {
	if ($movem.ContainsKey($s)) { continue }
	$rx = "(?<![\w.""'])" + [regex]::Escape($s) + "\b"
	if ([regex]::IsMatch($corpo, $rx)) {
		$corpo = [regex]::Replace($corpo, $rx, "m.$s")
		$aplicados += $s
	}
}
Write-Host "prefixados m.: $($aplicados.Count)"
$aplicados | Sort-Object | ForEach-Object { Write-Host "  m.$_" }
foreach ($met in @('get_viewport','get_tree','create_tween','set_meta','get_meta','has_meta','call_deferred','queue_redraw','is_inside_tree')) {
	$rx = "(?<![\w.])" + $met + "\("
	if ([regex]::IsMatch($corpo, $rx)) {
		$corpo = [regex]::Replace($corpo, $rx, "m.$met(")
		Write-Host "  m.$met() [Node]"
	}
}

$hdr = @"
extends RefCounted
## Modulo do menu - INVENTARIO + BAUS (Fase 3 da modularizacao).
## Helpers de sprite/reward compartilhados ficam no menu (acesso via m).
## Extraido de menu.gd em 2026-06-12 (tools/extrair_inventario.ps1).

var m  # menu principal (menu.gd)

func _init(menu) -> void:
	m = menu


func limpar_refs() -> void:
	# Resize recria a UI inteira: solta as referencias sem queue_free
	_inventario_overlay = null
	_bau_abertura_overlay = null
	_inventario_scroll_bar = null
	_inventario_scroll_content = null
	_inventario_scroll_tween = null
	_inventario_scroll_enabled = false


"@
$modulo = $hdr + ($vars1 -join "`n") + "`n" + ($vars2 -join "`n") + "`n`n`n" + $corpo + "`n"
[System.IO.File]::WriteAllText("scripts\menu\inventario.gd", $modulo, $enc)
Write-Host "modulo gravado: $((Get-Content scripts\menu\inventario.gd).Count) linhas"

# Reconstroi menu.gd (cortes de tras pra frente via fatias)
$novo = New-Object System.Collections.Generic.List[string]
$novo.AddRange([string[]](Slice $lines 1 83))
$novo.Add("var _mod_inv = null  # modulo scripts/menu/inventario.gd")
$novo.AddRange([string[]](Slice $lines 98 101))
$novo.AddRange([string[]](Slice $lines 104 281))
$novo.Add("func _handle_inventario_wheel(event: InputEvent) -> void:")
$novo.Add("`t_mod_inv._handle_inventario_wheel(event)")
$novo.Add("")
$novo.Add("")
$novo.Add("func _limpar_scroll_mochila() -> void:")
$novo.Add("`tif _mod_inv:")
$novo.Add("`t`t_mod_inv._limpar_scroll_mochila()")
$novo.Add("")
$novo.AddRange([string[]](Slice $lines 365 2979))
$novo.Add("func _abrir_bau_grande(ui: CanvasLayer, tier: String, ao_finalizar: Callable, preview: bool = false, recompensas_override: Array = [], titulo_override: String = `"`") -> void:")
$novo.Add("`t_mod_inv._abrir_bau_grande(ui, tier, ao_finalizar, preview, recompensas_override, titulo_override)")
$novo.Add("")
$novo.AddRange([string[]](Slice $lines 3683 6592))
$novo.Add("func _abrir_inventario(ui: CanvasLayer) -> void :")
$novo.Add("`t_mod_inv._abrir_inventario(ui)")
$novo.Add("")
$novo.AddRange([string[]](Slice $lines 8438 $lines.Count))
$texto = ($novo -join "`n") + "`n"

$texto = $texto.Replace('const MENU_LOJA_MOD = preload("res://scripts/menu/loja.gd")',
	'const MENU_LOJA_MOD = preload("res://scripts/menu/loja.gd")' + "`n" + 'const MENU_INV_MOD = preload("res://scripts/menu/inventario.gd")')
$texto = $texto.Replace("`t_mod_loja = MENU_LOJA_MOD.new(self)`n",
	"`t_mod_loja = MENU_LOJA_MOD.new(self)`n`t_mod_inv = MENU_INV_MOD.new(self)`n")

[System.IO.File]::WriteAllText($menuPath, $texto, $enc)
Write-Host "menu.gd reescrito: $((Get-Content $menuPath).Count) linhas"
