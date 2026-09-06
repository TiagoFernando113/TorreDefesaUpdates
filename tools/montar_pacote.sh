#!/usr/bin/env bash
# Monta um pacote de conteudo (.pck) que o jogo JA INSTALADO baixa e aplica.
#
#   tools/montar_pacote.sh <id> <versao> <godot> <arquivo.gd|res://...> [mais...]
#
# Exemplo:
#   tools/montar_pacote.sh intro 1 ~/Godot_v4.6.2 res://scripts/intro.gd
#
# Sai com o .pck em packs/<id>_v<versao>.pck e imprime a entrada pronta para
# colar no content_manifest.json, ja com o sha256.
#
# ---------------------------------------------------------------------------
# O QUE ESTE CANAL CONSEGUE E O QUE NAO CONSEGUE
#
# Conseguimos provar, com o jogo empacotado rodando de verdade, que um pacote
# TROCA CODIGO no aparelho: uma base compilada com a barra ciano passou a
# desenhar a barra dourada depois de receber um pacote, sem reinstalar nada.
# Funciona porque o Atualizador e' autoload e autoload roda ANTES da cena
# principal -- entao o pacote guardado numa abertura vale na abertura seguinte.
#
# E provamos tambem o limite, e ele custou quase um estrago: um pacote com TODO
# o codigo de setembro QUEBRA a build de junho com
#
#   Parse Error: Identifier "Auth" not declared in the current scope.
#
# `Auth` e' um autoload criado depois de junho. A lista de autoloads mora no
# project.binary, que o motor le' ANTES de qualquer pacote carregar -- entao
# pacote nao cria autoload. Todo script que usa um autoload que a build
# instalada nao tem morre ao ser lido.
#
# REGRA, entao: um pacote so' pode trocar scripts que
#   1. sejam carregados DEPOIS dos autoloads (cena principal em diante), e
#   2. nao usem nenhum autoload que a build instalada nao tenha.
# Mudanca que precisa de autoload novo pede APK novo. Nao ha jeito.
#
# E POR ISSO NAO EXISTE PACOTE "SO' PARA TESTAR": ele vai para todo mundo que
# tem o jogo, fica salvo no aparelho e e' carregado em toda abertura. Se
# quebrar um autoload, o jogo nao abre mais e NAO se conserta sozinho. Teste
# contra a build instalada antes -- tools/foto_de_cena.gd serve para isso.
# ---------------------------------------------------------------------------

set -euo pipefail
cd "$(dirname "$0")/.."

if [ $# -lt 4 ]; then
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
fi

ID="$1"; VERSAO="$2"; GODOT="$3"; shift 3

case "$ID" in
  *[!a-z0-9_-]*) echo "id so' aceita a-z 0-9 _ - (o jogo filtra o resto)"; exit 2 ;;
esac

# O preset e' descartavel: export_presets.cfg NAO e' versionado (guarda a senha
# da keystore), entao montar um na hora e apagar depois evita tanto commitar
# segredo quanto sobrescrever o preset de quem exporta o APK.
if [ -e export_presets.cfg ]; then
  echo "export_presets.cfg existe -- nao vou sobrescrever o seu. Mova e rode de novo."
  exit 2
fi
trap 'rm -f export_presets.cfg' EXIT

lista=""
for f in "$@"; do
  caminho="$f"
  [ "${caminho#res://}" = "$caminho" ] && caminho="res://$caminho"
  [ -n "$lista" ] && lista="$lista, "
  lista="$lista\"$caminho\""
done

cat > export_presets.cfg <<EOF
[preset.0]
name="pacote"
platform="Linux"
runnable=false
export_filter="resources"
export_files=PackedStringArray($lista)
include_filter=""
exclude_filter=""
export_path=""
[preset.0.options]
binary_format/embed_pck=false
EOF

mkdir -p packs
SAIDA="packs/${ID}_v${VERSAO}.pck"
"$GODOT" --headless --path . --export-pack "pacote" "$PWD/$SAIDA" >/tmp/pacote.log 2>&1 || {
  echo "a exportacao falhou:"; tail -5 /tmp/pacote.log; exit 1; }

# O Godot sempre poe os autoloads e o project.binary em qualquer .pck. Os
# autoloads sao inofensivos (carregam antes do pacote, entao a versao nova so'
# vale na proxima abertura) e o project.binary e' inerte (lido no arranque).
# Mas vale MOSTRAR o que entrou: pacote e' coisa que vai para o aparelho dos
# outros, e ninguem deve descobrir o conteudo depois.
echo "Entrou no pacote:"
grep -oa "Storing File: res://[^ ]*" /tmp/pacote.log \
  | sed 's|Storing File: res://|  |; s|\x1b.*||' | sort
echo

SHA=$(sha256sum "$SAIDA" | cut -d' ' -f1)
TAM=$(ls -lh "$SAIDA" | awk '{print $5}')
URL="https://raw.githubusercontent.com/TiagoFernando113/TorreDefesaUpdates/refs/heads/main/${SAIDA}"

echo "$SAIDA  ($TAM)"
echo
echo "Entrada para o content_manifest.json:"
echo "    {"
echo "      \"id\": \"$ID\","
echo "      \"version\": $VERSAO,"
echo "      \"url\": \"$URL\","
echo "      \"sha256\": \"$SHA\","
echo "      \"kind\": \"assets\""
echo "    }"
echo
echo "AVISO: o campo kind. O jogo RECUSA kind script/code/codigo -- e' a regra"
echo "de voces, \"packs nunca devem carregar codigo\". Um pacote com .gdc dentro"
echo "so' passa declarado como \"assets\". Publicar assim e' decidir relaxar essa"
echo "regra, e a decisao e' do dono do jogo, nao desta ferramenta."
