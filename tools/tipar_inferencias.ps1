# Corrige inferencia := quebrada por m.<helper>() em modulos extraidos.
# Le o tipo de retorno declarado da funcao no menu.gd e tipa a variavel.
param([string]$Alvo = "scripts\menu\inventario.gd")
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)

# Mapa nome -> tipo de retorno (menu.gd e o proprio modulo)
$tipos = @{}
foreach ($f in @("scripts\menu.gd", $Alvo)) {
	foreach ($l in [System.IO.File]::ReadAllLines($f, $enc)) {
		if ($l -match '^func\s+(\w+)\s*\(.*\)\s*->\s*([A-Za-z_]\w*)\s*:') {
			if ($Matches[2] -ne 'void') { $tipos[$Matches[1]] = $Matches[2] }
		}
	}
}
$texto = [System.IO.File]::ReadAllText($Alvo, $enc)

# Casos especiais primeiro
$texto = [regex]::Replace($texto, 'var\s+(\w+)\s*:=\s*m\.get_viewport\(\)\.get_visible_rect\(\)\.size', 'var $1: Vector2 = m.get_viewport().get_visible_rect().size')
$texto = [regex]::Replace($texto, 'var\s+(\w+)\s*:=\s*m\.create_tween\(\)', 'var $1: Tween = m.create_tween()')
$texto = [regex]::Replace($texto, 'var\s+(\w+)\s*:=\s*m\.get_tree\(\)\.create_tween\(\)', 'var $1: Tween = m.get_tree().create_tween()')

# Geral: var X := m.func(  ->  var X: Tipo = m.func(
$n = 0
$texto = [regex]::Replace($texto, 'var\s+(\w+)\s*:=\s*m\.(\w+)\(', {
	param($mt)
	$vn = $mt.Groups[1].Value; $fn = $mt.Groups[2].Value
	if ($script:tipos.ContainsKey($fn)) {
		$script:n++
		return "var ${vn}: $($script:tipos[$fn]) = m.$fn("
	}
	return $mt.Value
})
[System.IO.File]::WriteAllText($Alvo, $texto, $enc)
Write-Host "tipadas: $n (mapa com $($tipos.Count) funcoes)"
# Sobras nao resolvidas
$restos = [regex]::Matches($texto, 'var\s+\w+\s*:=\s*m\.\w+[\(.]')
Write-Host "restantes sem tipo: $($restos.Count)"
foreach ($r in $restos) { Write-Host "  $($r.Value)" }
