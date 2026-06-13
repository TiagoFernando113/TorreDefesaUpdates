# Corrige strings double-encoded (mojibake) nos .gd, preservando o sanitizador
# de runtime (linhas com .replace( ficam intactas).
# Chaves construidas programaticamente: char correto -> bytes UTF-8 lidos como
# cp1252 = a sequencia mojibake exata gravada nos arquivos.
$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$cp1252 = [System.Text.Encoding]::GetEncoding(1252)
function Moji([string]$s) { return $cp1252.GetString($utf8.GetBytes($s)) }

# Codepoints corrigiveis (simbolos + acentos pt-BR; 'a-circunflexo' solto nunca e tocado)
$codes = @(0x2500, 0x2014, 0x2013, 0x2026, 0x2192, 0x2190, 0x2694, 0x2665, 0x2212,
	0x2714, 0x201C, 0x201D, 0xE1, 0xE9, 0xED, 0xF3, 0xFA, 0xE3, 0xF5, 0xE2, 0xEA,
	0xF4, 0xE7, 0xC0, 0xC9, 0xC1, 0xCD, 0xD3, 0xDA, 0xC3, 0xC7)
$mapa = [ordered]@{}
foreach ($c in $codes) {
	$certo = [string][char]$c
	if ($c -eq 0x201C -or $c -eq 0x201D) { $certo = '"' }
	$mapa[(Moji ([string][char]$c))] = $certo
}

$totais = 0
Get-ChildItem scripts -Recurse -Filter *.gd | ForEach-Object {
	$linhas = [System.IO.File]::ReadAllLines($_.FullName, $utf8)
	$mudou = $false
	for ($i = 0; $i -lt $linhas.Count; $i++) {
		if ($linhas[$i] -match '\.replace\(') { continue }  # sanitizador de runtime
		$orig = $linhas[$i]
		foreach ($k in $mapa.Keys) {
			if ($linhas[$i].Contains($k)) { $linhas[$i] = $linhas[$i].Replace($k, $mapa[$k]) }
		}
		if ($linhas[$i] -cne $orig) { $mudou = $true; $script:totais++ }
	}
	if ($mudou) {
		[System.IO.File]::WriteAllText($_.FullName, (($linhas -join "`n") + "`n"), $utf8)
		Write-Host "corrigido: $($_.FullName.Replace((Get-Location).Path + '\', ''))"
	}
}
Write-Host "linhas corrigidas: $totais"
