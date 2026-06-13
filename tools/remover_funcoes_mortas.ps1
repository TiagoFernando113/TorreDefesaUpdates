# Remove funcoes privadas sem caller (lista validada manualmente).
# Cada funcao: da linha 'func' ate a linha antes da proxima 'func' (inclui
# blank lines de separacao no fim). Remove de tras pra frente por arquivo.
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)

$alvos = @{
	"scripts\main.gd"             = @("_spawnar_mob_em_DUMMY", "_posicao_borda_aleatoria", "_verificar_revive_loja", "_confirmar_game_over")
	"scripts\ui.gd"               = @("_cor_texto_card", "_adicionar_label_card")
	"scripts\torre.gd"            = @("_achar_segundo_alvo")
	"scripts\mob.gd"              = @("_invocar_para_boss", "_grito_de_guerra")
	"scripts\menu.gd"             = @("_gerar_mobs_deco", "_draw_torre_deco", "_draw_titulo", "_mostrar_popup_premio_discord", "_comandante_menu_bg", "_draw_texture_contain_region", "_draw_item_sprite_contain", "_draw_reward_card_portrait_cutouts", "_criar_patente_recurso", "_criar_patente_nav_inferior", "_criar_patente_modulo", "_ui_add_button_texture_icon", "_ui_trim_fit", "_ui_top_button")
	"scripts\menu\loja.gd"        = @("_criar_card_revive")
	"scripts\menu\inventario.gd"  = @("_abrir_baus")
}
# _spawnar_mob_em e _enviar excluidos (tem chamada por string)

$totalRemovidas = 0
$totalLinhas = 0
foreach ($arq in $alvos.Keys) {
	$linhas = [System.IO.File]::ReadAllLines($arq, $enc)
	# Mapa: nome -> [inicio0, fim0]
	$funcStarts = @()
	for ($i = 0; $i -lt $linhas.Count; $i++) {
		if ($linhas[$i] -match '^func\s+(\w+)') { $funcStarts += [PSCustomObject]@{ Idx = $i; Nome = $Matches[1] } }
	}
	# Faixas a remover (0-based inclusivas), de tras pra frente
	$faixas = @()
	foreach ($nome in $alvos[$arq]) {
		if ($nome -match 'DUMMY') { continue }
		$fs = $funcStarts | Where-Object { $_.Nome -eq $nome }
		if ($fs -eq $null) { throw "$arq : funcao $nome nao encontrada" }
		$ini = $fs.Idx
		# fim = linha antes da proxima func (ou EOF)
		$proxima = ($funcStarts | Where-Object { $_.Idx -gt $ini } | Select-Object -First 1)
		$fim = if ($proxima) { $proxima.Idx - 1 } else { $linhas.Count - 1 }
		# encolhe blank lines finais ate deixar exatamente as 2 de separacao? remove tudo ate a proxima func
		$faixas += [PSCustomObject]@{ Ini = $ini; Fim = $fim; Nome = $nome }
	}
	$faixas = $faixas | Sort-Object Ini -Descending
	$lista = New-Object System.Collections.Generic.List[string]
	$lista.AddRange([string[]]$linhas)
	foreach ($fx in $faixas) {
		$cnt = $fx.Fim - $fx.Ini + 1
		$lista.RemoveRange($fx.Ini, $cnt)
		$script:totalRemovidas++
		$script:totalLinhas += $cnt
	}
	[System.IO.File]::WriteAllText($arq, (($lista -join "`n") + "`n"), $enc)
	Write-Host "$arq : -$($alvos[$arq].Where({$_ -notmatch 'DUMMY'}).Count) funcoes"
}
Write-Host "TOTAL: $totalRemovidas funcoes, $totalLinhas linhas"
