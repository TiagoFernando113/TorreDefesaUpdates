#!/usr/bin/env bash
# Roda TODOS os testes de tests/ e diz quais passaram.
#
#   tools/rodar_testes.sh [caminho-do-godot]
#
# Por que existe: os 19 testes sao cenas separadas. Rodar todos exigia abrir 19
# cenas na mao, uma por uma, e ler a saida de cada uma. Ninguem faz isso -- na
# pratica os testes nao rodavam, e um teste que nao roda e' so' um arquivo.
#
# Cada teste roda no PROPRIO processo do Godot, e nao todos juntos num so'. Nao
# e' capricho: cada teste termina com `get_tree().quit(codigo)`, que derruba a
# aplicacao inteira. Num processo unico, o primeiro teste mataria os outros
# dezoito. Processo separado tambem isola crash: um teste que quebra o motor
# nao leva a bateria junto.
#
# O veredito de cada teste e' o CODIGO DE SAIDA -- 0 passou, resto falhou --,
# que e' exatamente o que os testes ja' faziam com `quit(0)` / `quit(1)`. Nada
# aqui pede que eles sejam reescritos.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

GODOT="${1:-${GODOT:-godot}}"
if ! command -v "$GODOT" >/dev/null 2>&1 && [ ! -x "$GODOT" ]; then
  echo "Nao achei o Godot em '$GODOT'."
  echo "Use: tools/rodar_testes.sh /caminho/para/Godot_v4.6-stable_linux.x86_64"
  exit 2
fi

# Um teste travado nao pode segurar a bateria para sempre: os que usam rede
# (test_notices_fetch) dependem de um servidor que pode nao responder.
LIMITE="${LIMITE_SEGUNDOS:-120}"

passaram=0
falharam=()
pulados=()
saida_tmp="$(mktemp)"
trap 'rm -f "$saida_tmp"' EXIT

echo "Rodando os testes de Cyron Defense"
echo "Godot: $("$GODOT" --version 2>/dev/null | tail -1)"
echo

for cena in tests/test_*.tscn; do
  [ -e "$cena" ] || continue
  nome="$(basename "$cena" .tscn)"
  printf '  %-38s' "$nome"

  timeout "$LIMITE" "$GODOT" --headless --path . "res://$cena" >"$saida_tmp" 2>&1
  codigo=$?

  if [ $codigo -eq 0 ]; then
    # Um teste que passou PULANDO conferencia nao e' a mesma coisa que um teste
    # que conferiu tudo. Esconder isso aqui refaria, um nivel acima, o defeito
    # que os pulos vieram consertar: um "ok" que nao quer dizer o que parece.
    # `grep -c` JA' imprime 0 quando nao acha nada -- e sai com codigo 1. Com um
    # `|| echo 0` no fim, os dois zeros se somavam na string ("0\n0") e o teste
    # numerico abaixo reclamava em toda linha que nao tinha pulo.
    pulos="$(grep -ac '^PULADO:' "$saida_tmp" 2>/dev/null || true)"
    pulos="${pulos:-0}"
    if [ "$pulos" -gt 0 ]; then
      echo "ok ($pulos pulado(s))"
      while IFS= read -r linha; do pulados+=("$nome|${linha#PULADO: }"); done \
        < <(grep -a '^PULADO:' "$saida_tmp")
    else
      echo "ok"
    fi
    passaram=$((passaram + 1))
  elif [ $codigo -eq 124 ]; then
    echo "TRAVOU (passou de ${LIMITE}s)"
    falharam+=("$nome|travou depois de ${LIMITE}s")
  else
    echo "FALHOU (codigo $codigo)"
    # So' as linhas que explicam a falha. A saida crua do Godot traz dezenas de
    # linhas de importacao que enterrariam o motivo.
    motivo="$(grep -aE "FALHA|ERROR|SCRIPT ERROR|Parse Error|push_error" "$saida_tmp" \
      | grep -avE "^\[|Unicode parsing" | head -3 | tr '\n' ' ')"
    falharam+=("$nome|${motivo:-sem mensagem; rode sozinho para ver}")
  fi
done

echo
if [ ${#pulados[@]} -gt 0 ]; then
  echo "Conferencias puladas (${#pulados[@]}) -- normais num clone limpo:"
  for p in "${pulados[@]}"; do
    echo "  - ${p%%|*}: ${p#*|}"
  done
  echo
fi

if [ ${#falharam[@]} -eq 0 ]; then
  echo "$passaram testes passaram."
  exit 0
fi

echo "$passaram passaram, ${#falharam[@]} falharam:"
echo
for f in "${falharam[@]}"; do
  echo "  x ${f%%|*}"
  echo "    ${f#*|}"
done
exit 1
