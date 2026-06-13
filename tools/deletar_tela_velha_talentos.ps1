# Fase 5: deleta a tela CLASSICA de talentos do menu.gd (Nexo e a unica tela).
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)
$p = "scripts\menu.gd"
$lines = [System.IO.File]::ReadAllLines($p, $enc)
Write-Host "antes: $($lines.Count) linhas"

function Slice($a, $s, $e) { return @($a[($s-1)..($e-1)]) }
# Ancoras (indexacao direta 0-based: linha N = [N-1])
if ($lines[5643] -notmatch 'func _abrir_talentos_classico') { throw "ancora 5644: $($lines[5643])" }
if ($lines[5681] -notmatch 'func _abrir_nexo')              { throw "ancora 5682: $($lines[5681])" }
if ($lines[5713] -notmatch 'func _rebuild_talentos')        { throw "ancora 5714: $($lines[5713])" }
if ($lines[7797] -notmatch 'func _comprar_talento_no')      { throw "ancora 7798: $($lines[7797])" }
if ($lines[7803] -notmatch 'func _fechar_talentos')         { throw "ancora 7804: $($lines[7803])" }

# Mantem: 1..5643, 5682..5713 (_abrir_nexo + _debug_garantir), 7828..fim
$novo = New-Object System.Collections.Generic.List[string]
$novo.AddRange([string[]](Slice $lines 1 5643))
$novo.AddRange([string[]](Slice $lines 5682 5713))
$novo.AddRange([string[]](Slice $lines 7828 $lines.Count))
$t = ($novo -join "`n") + "`n"

# Preloads e const da tela velha
$t = $t.Replace('const TALENTO_NO = preload("res://scripts/talento_no.gd")' + "`n", '')
$t = $t.Replace('const ARVORE_FUNDO = preload("res://scripts/arvore_fundo.gd")' + "`n", '')
$t = $t.Replace('const CONSTELLATION_FUNDO = preload("res://scripts/talent_constellation_fundo.gd")' + "`n", '')

# _ready / _input: hooks da tela velha
$t = $t.Replace("`t_load_talent_calibration()`n", "")
$t = $t.Replace("`tif _handle_talent_calibration_input(event):`n`t`treturn`n", "")
$t = $t.Replace("`tif _handle_talent_map_navigation_input(event):`n`t`treturn`n", "")

# _abrir_nexo: restos da convivencia com a tela velha
$t = $t.Replace("`t_talent_map_dragging = false`n`tif _talentos_panel != null and is_instance_valid(_talentos_panel):`n`t`t_talentos_panel.visible = false`n", "")
$t = $t.Replace("`t_nexo_overlay.connect(""fechado"", func():`n`t`t_nexo_overlay = null`n`t`tif _talentos_overlay != null:`n`t`t`t_rebuild_talentos()`n`t`telif _menu_contents:`n`t`t`t_menu_contents.show())", "`t_nexo_overlay.connect(""fechado"", func():`n`t`t_nexo_overlay = null`n`t`tif _menu_contents:`n`t`t`t_menu_contents.show())")

[System.IO.File]::WriteAllText($p, $t, $enc)
Write-Host "depois: $((Get-Content $p).Count) linhas"
