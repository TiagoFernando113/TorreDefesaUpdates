# Fase 4 da modularizacao: CONFIG + MAPAS -> scripts/menu/config_mapas.gd
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)
$menuPath = "scripts\menu.gd"
$lines = [System.IO.File]::ReadAllLines($menuPath, $enc)
Write-Host "menu.gd linhas: $($lines.Count)"
function Slice($a, $start1, $end1) { return $a[($start1-1)..($end1-1)] }

# Ranges 1-based validados:
$vMapas  = @(Slice $lines 90 90)      # var _mapas_overlay
$vConfig = @(Slice $lines 97 99)      # _config_overlay/_config_panel/_config_confirm
$rMapas  = @(Slice $lines 2895 3088)  # _abrir_mapas
$rConfig = @(Slice $lines 4792 5141)  # _abrir_config
$rReset  = @(Slice $lines 5315 5345)  # _on_reset_press (botao do config)
$rFechar = @(Slice $lines 5346 5361)  # _fechar_config

if ($vMapas[0]  -notmatch '_mapas_overlay')      { throw "ancora vMapas" }
if ($vConfig[0] -notmatch '_config_overlay')     { throw "ancora vConfig" }
if ($rMapas[0]  -notmatch 'func _abrir_mapas')   { throw "ancora rMapas" }
if ($rConfig[0] -notmatch 'func _abrir_config')  { throw "ancora rConfig" }
if ($rReset[0]  -notmatch 'func _on_reset_press'){ throw "ancora rReset" }
if ($rFechar[0] -notmatch 'func _fechar_config') { throw "ancora rFechar" }
foreach ($b in @($rMapas, $rConfig, $rReset, $rFechar)) { if ($b[-1] -match '^func ') { throw "fim invadiu funcao" } }
foreach ($b in @($rMapas, $rConfig)) {
	foreach ($l in $b) {
		if ($l -match '^(const|var)\s+(\w+)' -and $l -notmatch '_config|_mapas') { Write-Host "ATENCAO decl alheia: $l" }
	}
}

$simbolos = @{}
foreach ($l in $lines) { if ($l -match '^(func|var|const)\s+([A-Za-z_]\w*)') { $simbolos[$Matches[2]] = $true } }
$movem = @{}
foreach ($l in ($vMapas + $vConfig + $rMapas + $rConfig + $rReset + $rFechar)) {
	if ($l -match '^(func|var|const)\s+([A-Za-z_]\w*)') { $movem[$Matches[2]] = $true }
}

$corpo = ($rMapas -join "`n") + "`n`n`n" + ($rConfig -join "`n") + "`n`n`n" + ($rReset -join "`n") + "`n`n`n" + ($rFechar -join "`n")
$aplicados = @()
foreach ($s in $simbolos.Keys) {
	if ($movem.ContainsKey($s)) { continue }
	$rx = "(?<![\w.""'])" + [regex]::Escape($s) + "\b"
	if ([regex]::IsMatch($corpo, $rx)) { $corpo = [regex]::Replace($corpo, $rx, "m.$s"); $aplicados += $s }
}
Write-Host "prefixados m.: $($aplicados.Count)"
$aplicados | Sort-Object | ForEach-Object { Write-Host "  m.$_" }
foreach ($met in @('get_viewport','get_tree','create_tween','set_meta','get_meta','has_meta','call_deferred','queue_redraw','is_inside_tree')) {
	$rx = "(?<![\w.])" + $met + "\("
	if ([regex]::IsMatch($corpo, $rx)) { $corpo = [regex]::Replace($corpo, $rx, "m.$met("); Write-Host "  m.$met() [Node]" }
}

# Shadowing de 'm' local? (licao fase 3)
if ([regex]::IsMatch($corpo, '(?m)^\s*var m\s|for m in ')) { Write-Host "ATENCAO: possivel shadowing de m" }

$hdr = @"
extends RefCounted
## Modulo do menu - CONFIG + MAPAS (Fase 4 da modularizacao).
## Extraido de menu.gd em 2026-06-12 (tools/extrair_fase4.ps1).

var m  # menu principal (menu.gd)

func _init(menu) -> void:
	m = menu


func limpar_refs() -> void:
	_mapas_overlay = null
	_config_overlay = null
	_config_panel = null
	_config_confirm = null


"@
$modulo = $hdr + ($vMapas -join "`n") + "`n" + ($vConfig -join "`n") + "`n`n`n" + $corpo + "`n"
[System.IO.File]::WriteAllText("scripts\menu\config_mapas.gd", $modulo, $enc)
Write-Host "modulo gravado: $((Get-Content scripts\menu\config_mapas.gd).Count) linhas"

# Reconstroi menu.gd (cortes: 90; 97-99; 2895-3088; 4792-5141; 5315-5345; 5346-5361 => 5315-5361 contiguos)
$novo = New-Object System.Collections.Generic.List[string]
$novo.AddRange([string[]](Slice $lines 1 89))
$novo.Add("var _mod_cfg = null  # modulo scripts/menu/config_mapas.gd")
$novo.AddRange([string[]](Slice $lines 91 96))
$novo.AddRange([string[]](Slice $lines 100 2894))
$novo.Add("func _abrir_mapas(ui: CanvasLayer) -> void:")
$novo.Add("`t_mod_cfg._abrir_mapas(ui)")
$novo.Add("")
$novo.AddRange([string[]](Slice $lines 3089 4791))
$novo.Add("func _abrir_config(ui: CanvasLayer) -> void :")
$novo.Add("`t_mod_cfg._abrir_config(ui)")
$novo.Add("")
$novo.AddRange([string[]](Slice $lines 5142 5314))
$novo.AddRange([string[]](Slice $lines 5362 $lines.Count))
$texto = ($novo -join "`n") + "`n"

$texto = $texto.Replace('const MENU_INV_MOD = preload("res://scripts/menu/inventario.gd")',
	'const MENU_INV_MOD = preload("res://scripts/menu/inventario.gd")' + "`n" + 'const MENU_CFG_MOD = preload("res://scripts/menu/config_mapas.gd")')
$texto = $texto.Replace("`t_mod_inv = MENU_INV_MOD.new(self)`n",
	"`t_mod_inv = MENU_INV_MOD.new(self)`n`t_mod_cfg = MENU_CFG_MOD.new(self)`n")

[System.IO.File]::WriteAllText($menuPath, $texto, $enc)
Write-Host "menu.gd reescrito: $((Get-Content $menuPath).Count) linhas"
