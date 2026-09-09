#!/usr/bin/env bash
# Monta o pacote de atualizacao do app de DESENVOLVEDOR e escreve o manifesto.
#
#   PACK_VERSION=7 PACK_URL=https://.../jogo.pck tools/exportar_pacote_dev.sh <godot>
#
# Sai com packs/jogo_v<N>.pck e com o content_manifest_dev.json ja' atualizado,
# pronto para commitar. Quem chama e' a esteira (.github/workflows/pacote-dev.yml).
#
# ---------------------------------------------------------------------------
# POR QUE ISTO EXISTE
#
# Ate' agora, mudar uma linha de codigo custava um APK de 208 MB: alguem baixava
# no celular e instalava por cima, toda vez. O canal de pacotes -- que ja'
# existia e ja' foi provado trocando codigo no aparelho -- so' nunca tinha sido
# ligado na esteira, entao ninguem o usava. Montar pacote na mao e' o mesmo
# problema de sempre: trabalho de maquina esperando lembranca de pessoa.
#
# Com isto, mudanca em scripts/, ui/, scenes/, modulos/ e data/ vira um pacote de
# poucos megabytes que o jogo instalado baixa sozinho na abertura seguinte.
#
# O QUE NAO CABE AQUI (e continua pedindo APK novo)
#
#   - autoload novo, ou qualquer coisa de project.godot
#   - permissao do Android, motor, renderizador, nome do pacote
#   - arte e audio de assets/, e os addons/
#
# Ver docs/o_que_exige_apk_novo.md.
# ---------------------------------------------------------------------------

set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${1:-${GODOT:-godot}}"
VERSAO="${PACK_VERSION:-}"
URL="${PACK_URL:-}"
ID="${PACK_ID:-jogo}"
MANIFESTO="${PACK_MANIFEST:-content_manifest_dev.json}"
# Fora de packs/ por padrao na esteira: pacote e' publicado em Release, e nao
# commitado. Um .pck de ~2 MB por push viraria gigabytes de historico em alguns
# meses -- e git nao esquece arquivo grande depois.
DESTINO="${PACK_DIR:-packs}"

if [ -z "$VERSAO" ] || [ -z "$URL" ]; then
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
fi
case "$VERSAO" in ''|*[!0-9]*) echo "PACK_VERSION tem que ser um numero: '$VERSAO'"; exit 2 ;; esac
case "$URL" in https://*) ;; *) echo "PACK_URL tem que ser https:// (o jogo recusa o resto)"; exit 2 ;; esac

# ---------------------------------------------------------------------------
# 1. O que entra
#
# So' codigo e telas. `assets/` fica de fora de proposito: sao 170 MB, e e'
# justamente o que fez o APK crescer. As fontes e os tres PNGs do menu entram
# assim mesmo, arrastados por preload() -- somam menos de 1 MB e o limite
# la' embaixo confere que nao virou mais que isso.
# ---------------------------------------------------------------------------
mapfile -t ARQUIVOS < <(
  find scripts ui scenes modulos data \
    -type f \( -name '*.gd' -o -name '*.tscn' -o -name '*.tres' -o -name '*.json' \) \
    2>/dev/null | sort
)

if [ "${#ARQUIVOS[@]}" -lt 20 ]; then
  echo "so' achei ${#ARQUIVOS[@]} arquivos para empacotar -- isso e' pouco demais."
  echo "provavelmente o script rodou fora da raiz do projeto."
  exit 1
fi

lista=""
for f in "${ARQUIVOS[@]}"; do
  [ -n "$lista" ] && lista="$lista, "
  lista="$lista\"res://$f\""
done

# O preset e' descartavel, e nao pode passar por cima do de quem exporta o APK
# na propria maquina -- export_presets.cfg nem e' versionado (guarda senha de
# keystore).
if [ -e export_presets.cfg ]; then
  echo "export_presets.cfg existe -- nao vou sobrescrever o seu. Mova e rode de novo."
  exit 2
fi
trap 'rm -f export_presets.cfg' EXIT

# ATENCAO: comentario em ConfigFile do Godot e' ';', nao '#'. Um '#' aqui nao da'
# erro -- ele engole a linha seguinte em silencio. Ja' custou um APK sem
# INTERNET.
cat > export_presets.cfg <<EOF
[preset.0]
name="pacote-dev"
platform="Linux"
runnable=false
export_filter="resources"
export_files=PackedStringArray($lista)
include_filter="modulos/*.json,data/*.json"
exclude_filter="assets/musica/*,assets/mapas/*,assets/arsenal/*"
export_path=""
[preset.0.options]
binary_format/embed_pck=false
EOF

mkdir -p "$DESTINO"
SAIDA="$DESTINO/${ID}_v${VERSAO}.pck"
rm -f "$SAIDA"

echo "empacotando ${#ARQUIVOS[@]} arquivos..."
# O Godot exige caminho absoluto aqui; um relativo ele resolve contra a raiz do
# projeto. Colar "$PWD/" sem olhar quebrava PACK_DIR absoluto, virando um
# caminho colado no meio do outro -- e a mensagem do motor nao explicava nada.
ABS="$SAIDA"
case "$ABS" in /*) ;; *) ABS="$PWD/$SAIDA" ;; esac
"$GODOT" --headless --path . --export-pack "pacote-dev" "$ABS" \
  > /tmp/pacote_dev.log 2>&1 || {
    echo "a exportacao falhou:"; tail -20 /tmp/pacote_dev.log; exit 1; }

if [ ! -s "$SAIDA" ]; then
  echo "o Godot saiu sem erro mas nao deixou pacote nenhum em $SAIDA."
  tail -20 /tmp/pacote_dev.log
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Conferir O PACOTE QUE SAIU, nao o que eu pedi
#
# Preset com chave errada nao da' erro no Godot -- so' fica sem efeito. Foi
# assim que saiu um APK sem permissao de INTERNET. Entao aqui nada e' assumido:
# le-se o que o motor gravou.
# ---------------------------------------------------------------------------
DENTRO=$(grep -oa "Storing File: res://[^ ]*" /tmp/pacote_dev.log \
  | sed 's|Storing File: ||; s|\x1b.*||' | sort -u)

falhas=()

# O Godot nao guarda o .gd: ele guarda o .gdc compilado e um .gd.remap que
# aponta para ele. Procurar pelo ".gd" cru nunca acharia nada -- e o teste
# passaria a reprovar todo pacote, inclusive os bons.
for obrigatorio in \
  "scripts/atualizador.gd" \
  "scripts/carregador.gd" \
  "scripts/auth_supabase.gd" \
  "scripts/menu.gd" \
  "modulos/lista.json"
do
  base="res://$obrigatorio"
  achou=0
  for forma in "$base" "${base%.gd}.gdc" "$base.remap"; do
    if echo "$DENTRO" | grep -qxF "$forma"; then achou=1; break; fi
  done
  [ "$achou" = 1 ] || falhas+=("faltou $obrigatorio no pacote")
done

BYTES=$(stat -c %s "$SAIDA")
LIMITE=$((30 * 1024 * 1024))
MINIMO=$((200 * 1024))

# O teto nao e' economia: e' alarme. Se o pacote passar disso, alguem colocou um
# preload() apontando para audio ou mapa, e o pacote acabou de arrastar a
# biblioteca inteira junto. Melhor reprovar aqui do que mandar 100 MB para o
# celular de alguem por engano.
if [ "$BYTES" -gt "$LIMITE" ]; then
  falhas+=("pacote com $((BYTES / 1024 / 1024)) MB, acima do teto de 30 MB -- procure um preload() novo apontando para assets/")
  echo "os maiores arquivos que entraram:"
  echo "$DENTRO" | sed 's|res://||' | while read -r a; do
    [ -f "$a" ] && stat -c '%s %n' "$a"
  done | sort -rn | head -10 | awk '{printf "  %6.1f MB  %s\n", $1/1048576, $2}'
fi
[ "$BYTES" -lt "$MINIMO" ] && falhas+=("pacote com so' $BYTES bytes -- entrou vazio")

if [ "${#falhas[@]}" -gt 0 ]; then
  echo
  echo "PACOTE REPROVADO:"
  for f in "${falhas[@]}"; do echo "  - $f"; done
  rm -f "$SAIDA"
  exit 1
fi

# ---------------------------------------------------------------------------
# 3. Os autoloads exigidos
#
# O pacote so' pode ser aplicado por uma build que tenha TODOS os autoloads que
# o codigo dele menciona. Autoload mora no project.binary, lido antes de
# qualquer pacote -- pacote nao cria autoload, e script que cita um autoload
# ausente nem compila. O jogo confere esta lista antes de baixar (ver
# _tem_todos_autoloads no atualizador.gd) e simplesmente ignora o pacote quando
# falta algum, em vez de baixar e nao abrir mais.
# ---------------------------------------------------------------------------
AUTOLOADS=$(sed -n '/^\[autoload\]/,/^\[/p' project.godot \
  | grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' | sed 's/=$//' | sort -u)
if [ -z "$AUTOLOADS" ]; then
  echo "nao consegui ler a secao [autoload] do project.godot"
  exit 1
fi
JSON_AUTOLOADS=$(echo "$AUTOLOADS" | awk '{printf "%s\"%s\"", (NR>1 ? ", " : ""), $0}')

SHA=$(sha256sum "$SAIDA" | cut -d' ' -f1)

cat > "$MANIFESTO" <<EOF
{
  "version": 1,
  "packs": [
    {
      "id": "$ID",
      "version": $VERSAO,
      "url": "$URL",
      "sha256": "$SHA",
      "kind": "script",
      "requer_autoloads": [$JSON_AUTOLOADS]
    }
  ]
}
EOF

python3 -c "import json,sys; json.load(open('$MANIFESTO'))" || {
  echo "o manifesto que eu escrevi nao e' JSON valido"; cat "$MANIFESTO"; exit 1; }

echo
echo "pacote:    $SAIDA  ($(( BYTES / 1024 )) KB, ${#ARQUIVOS[@]} arquivos pedidos)"
echo "sha256:    $SHA"
echo "manifesto: $MANIFESTO"
echo
cat "$MANIFESTO"
