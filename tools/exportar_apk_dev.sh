#!/usr/bin/env bash
# Exporta o APK do app de DESENVOLVEDOR, com tudo que o pacote nao alcanca.
#
#   tools/exportar_apk_dev.sh <godot> [saida.apk]
#
# Exemplo:
#   tools/exportar_apk_dev.sh ~/Godot_v4.6.2-stable_linux.x86_64
#
# ---------------------------------------------------------------------------
# POR QUE ESTE ARQUIVO EXISTE
#
# `export_presets.cfg` nao e' versionado -- guarda a senha da keystore de
# release. A consequencia e' que o preset morava num computador so', e tudo que
# ele decide (permissoes, nome do pacote, arquiteturas) se perdia junto.
#
# Foi assim que o APK de desenvolvedor ficou meses com DUAS permissoes,
# `INTERNET` e `DUMP`, e sem o audio. Ninguem errou nada: a informacao
# simplesmente nao existia em lugar nenhum que desse para consultar.
#
# Um preset VAZIO no Godot nao produz um padrao razoavel -- produz um APK sem
# INTERNET e com o pacote `com.example.cyrondefense`. Conferido exportando.
#
# Entao o preset de desenvolvedor mora aqui, montado na hora. Sem segredo
# nenhum: a keystore de DEPURACAO tem senha publica e fixa ("android"), a mesma
# em qualquer instalacao do Android. A keystore de RELEASE nao e' tocada por
# este script, e nao deve ser.
# ---------------------------------------------------------------------------

set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${1:-}"
SAIDA="${2:-$PWD/dev/CyronDEV.apk}"
if [ -z "$GODOT" ] || { ! command -v "$GODOT" >/dev/null 2>&1 && [ ! -x "$GODOT" ]; }; then
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
fi

KEYSTORE="${KEYSTORE_DEBUG:-$HOME/.local/share/godot/keystores/debug.keystore}"
if [ ! -f "$KEYSTORE" ]; then
  echo "Nao achei a keystore de depuracao em: $KEYSTORE"
  echo "Gere uma com:"
  echo "  keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android \\"
  echo "    -keystore \"$KEYSTORE\" -storepass android -validity 10000 \\"
  echo "    -dname 'CN=Android Debug,O=Android,C=US'"
  exit 2
fi

# O preset e' descartavel: montar e apagar evita sobrescrever o de quem exporta
# o APK de release nesta mesma maquina.
if [ -e export_presets.cfg ]; then
  echo "export_presets.cfg existe -- nao vou sobrescrever o seu. Mova e rode de novo."
  exit 2
fi
trap 'rm -f export_presets.cfg' EXIT

CODIGO="${VERSION_CODE:-15}"
NOME="${VERSION_NAME:-0.12.0-dev15}"

cat > export_presets.cfg <<EOF
[preset.0]

name="dev"
platform="Android"
runnable=true
advanced_options=true
dedicated_server=false
; A marca que liga o DevPainel e o canal de pacotes de desenvolvedor. Sem ela
; este APK vira, para todos os efeitos, o app publico.
custom_features="dev_build"
export_filter="all_resources"
; O modulos/lista.json precisa ir junto: e' o arquivo que um pacote substitui
; para instalar sistema novo.
include_filter="*.json"
exclude_filter=""
export_path=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]

; COMPILACAO GRADLE, e nao a exportacao simples.
;
; Custa mais tempo e tem mais o que dar errado, e mesmo assim e' o unico
; caminho: o manifesto do modelo padrao nao aceita intent-filter novo, e sem
; intent-filter proprio NENHUM app pode ser aberto pelo navegador -- medido no
; aparelho, incluindo as Configuracoes do Android como controle.
;
; De quebra e' o que permite plugin nativo, entao o CyronPush (notificacoes)
; deixa de ser letra morta neste APK.
gradle_build/use_gradle_build=true
package/unique_name="com.tiagofernando.cyrondev"
; Nome diferente de proposito: este APK instala AO LADO do jogo de verdade.
package/name="Cyron DEV"
package/signed=true
package/app_category=2
package/show_in_app_library=true
version/code=$CODIGO
version/name="$NOME"
keystore/debug="$KEYSTORE"
keystore/debug_user="androiddebugkey"
keystore/debug_password="android"
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
screen/immersive_mode=true
screen/support_small=true
screen/support_normal=true
screen/support_large=true
screen/support_xlarge=true
; Sem estas cinco linhas o APK sai com DUAS permissoes e nem internet tem.
permissions/internet=true
permissions/access_network_state=true
permissions/vibrate=true
permissions/wake_lock=true
permissions/post_notifications=true
EOF

# ---------------------------------------------------------------------------
# O MODELO DE COMPILACAO
#
# A compilacao Gradle roda sobre uma copia do projeto Android do Godot, em
# android/build/. Ela sai de dentro dos proprios modelos de exportacao
# (android_source.zip), entao nao ha' o que baixar alem do que ja' se baixa.
#
# Extrair na mao, em vez de usar --install-android-build-template, evita uma
# exportacao inteira so' para instalar o modelo -- seriam ~200 MB montados e
# jogados fora antes da montagem que vale.
# ---------------------------------------------------------------------------
FONTE_ANDROID="$(ls -d "$HOME"/.local/share/godot/export_templates/*/android_source.zip 2>/dev/null | head -1)"
if [ -z "$FONTE_ANDROID" ]; then
  echo "nao achei o android_source.zip nos modelos de exportacao."
  echo "sem ele nao ha' compilacao Gradle, e sem Gradle o APK sai sem o"
  echo "endereco proprio do jogo -- que e' a razao de tudo isto existir."
  ls -la "$HOME"/.local/share/godot/export_templates/*/ 2>/dev/null | head -20
  exit 1
fi

echo "Instalando o modelo de compilacao a partir de $FONTE_ANDROID"
rm -rf android/build
mkdir -p android/build
unzip -q "$FONTE_ANDROID" -d android/build
echo "4.6.2.stable" > android/.build_version

# src/main/ e' o layout padrao do Gradle. Eu tinha chutado a raiz de
# android/build/, e a esteira reprovou na primeira tentativa dizendo onde o
# arquivo estava de verdade -- que e' exatamente o servico que esta linha presta.
MANIFESTO="android/build/src/main/AndroidManifest.xml"
if [ ! -f "$MANIFESTO" ]; then
  echo "o modelo de compilacao veio sem $MANIFESTO."
  echo "os manifestos que vieram, para o caso de o layout ter mudado:"
  find android/build -name 'AndroidManifest.xml' | sed 's/^/  /'
  exit 1
fi
python3 tools/endereco_proprio_android.py "$MANIFESTO" || exit 1

# ---------------------------------------------------------------------------
# O CARIMBO DA VERSAO
#
# O jogo nao sabia qual APK era. BuildConfig.APP_VERSION_CODE era uma constante
# fixa em 12 enquanto o APK ja' estava no 19 -- entao o painel de manutencao,
# cuja unica funcao e' dizer o que esta rodando, mostrava "code 12" em qualquer
# aparelho. E e' o mesmo numero que decide se o app publico mostra "atualizacao
# disponivel": preso em 12, o banner ficaria escondido para sempre.
#
# Este arquivo NAO entra nos pacotes (o pacote leva scripts/, ui/, scenes/,
# modulos/ e data/ -- nao a raiz). Assim um pacote nunca sobrescreve a versao
# do APK em que esta rodando.
# ---------------------------------------------------------------------------
python3 - "$CODIGO" "$NOME" <<'PYSTAMP'
import json, sys
json.dump({"code": int(sys.argv[1]), "name": sys.argv[2]},
          open("versao_build.json", "w"), ensure_ascii=False)
PYSTAMP
echo "Carimbo da versao: $(cat versao_build.json)"

mkdir -p "$(dirname "$SAIDA")"
echo "Exportando (demora: Gradle + o audio, que sozinho tem ~100 MB)..."
"$GODOT" --headless --path . --export-debug "dev" "$SAIDA" >/tmp/exportar_apk_dev.log 2>&1 || {
  echo "a exportacao falhou:"; tail -15 /tmp/exportar_apk_dev.log; exit 1; }

echo
echo "$SAIDA  ($(du -h "$SAIDA" | cut -f1))"
echo

# O remendo entrou antes da exportacao. Se o Godot reescreve o manifesto no
# meio do caminho, ele sai -- e o APK fica sem endereco com a esteira achando
# que fez tudo certo. Esta linha responde qual dos dois aconteceu, em vez de
# deixar adivinhando.
echo "Manifestos depois da exportacao (procurando o BROWSABLE):"
find android/build -name 'AndroidManifest.xml' 2>/dev/null | while read -r mf; do
  if grep -q "BROWSABLE" "$mf" 2>/dev/null; then
    echo "  TEM   $mf"
  else
    echo "  sem   $mf"
  fi
done
echo

# O filtro sobrevive em src/main e some na fusao. Quem mais fala da atividade
# de abertura e' o manifesto de variante que o Godot GERA na exportacao -- e' de
# la' que vem o nome do pacote e as permissoes. Se ele redeclarar a atividade
# com tools:node="replace", a fusao joga fora os filhos vindos do src/main,
# inclusive o nosso intent-filter.
#
# Em vez de supor, olhar. Sao poucas linhas.
for VAR in debug release; do
  MF="android/build/src/$VAR/AndroidManifest.xml"
  [ -f "$MF" ] || continue
  echo "----- $MF -----"
  cat "$MF"
  echo
done
echo "----- o que a fusao guardou sobre a atividade de abertura -----"
MERGED="$(find android/build/build/intermediates -name 'AndroidManifest.xml' -path '*merged_manifest*' 2>/dev/null | head -1)"
if [ -n "$MERGED" ]; then
  grep -oE '<(activity|activity-alias)[^>]*|<intent-filter>|</intent-filter>|<(action|category|data)[^>]*' "$MERGED" \
    | sed 's/^/  /' | head -40
else
  echo "  (nao achei manifesto fundido)"
fi
echo
# Conferir o APK QUE SAIU, e nao o preset que entrou.
#
# Isto nao e' zelo: uma chave escrita errada no preset nao da' erro nenhum, so'
# fica sem efeito. Aconteceu montando este proprio script -- comentario com `#`
# em vez de `;` (o formato do Godot comenta com `;`) engoliu a linha seguinte,
# e o APK saiu SEM INTERNET. Passou despercebido ate' esta conferencia.
#
# Por isso ela REPROVA, e nao so' informa. Relatorio que ninguem le' nao teria
# pegado nada.
python3 - "$SAIDA" <<'PY' || exit 1
import re, sys, zipfile

OBRIGATORIAS = {
    "INTERNET": "sem ela nao ha login, ranking nem pacote",
    "ACCESS_NETWORK_STATE": "distinguir 'sem internet' de 'servidor fora'",
    "POST_NOTIFICATIONS": "obrigatoria no Android 13+",
    "VIBRATE": "retorno tatil",
    "WAKE_LOCK": "tela acesa em partida longa",
}

z = zipfile.ZipFile(sys.argv[1])
m = z.read("AndroidManifest.xml").decode("utf-16-le", "ignore")
tem = {p.split(".")[-1] for p in re.findall(r"android\.permission\.[A-Z_]+", m)}

print("Permissoes que realmente entraram:")
for p in sorted(tem):
    print("   ", p)

problemas = ["falta %s (%s)" % (p, por) for p, por in OBRIGATORIAS.items() if p not in tem]
if "com.example" in m:
    problemas.append("saiu com com.example -- o preset nao foi aplicado")
if "com.tiagofernando.cyrondev" not in m:
    problemas.append("o nome do pacote nao e' com.tiagofernando.cyrondev")

# O ENDERECO PROPRIO. E' a razao de este APK ser compilado com Gradle.
#
# Sem ele o botao "VOLTAR AO JOGO" da pagina de login nao abre o app -- e nao
# avisa: o navegador simplesmente vai para o endereco de reserva. Um APK sem
# isto parece perfeito e falha exatamente onde ninguem olha.
# CUIDADO COM O QUE SE PROCURA: "cyron" sozinho NAO serve, porque o nome do
# pacote e' com.tiagofernando.cyrondev e casaria sempre. Foi assim que esta
# conferencia deu um "passou" falso na primeira montagem com Gradle -- so' a
# linha do BROWSABLE reprovou, e ela e' que estava certa.
#
# O host "voltar" e a categoria BROWSABLE so' existem no manifesto por causa do
# intent-filter novo. Sao esses que valem.
if "android.intent.category.BROWSABLE" not in m:
    problemas.append("falta BROWSABLE no manifesto -- e' a categoria que o navegador acrescenta; sem ela nada casa")
if "voltar" not in m:
    problemas.append("o host 'voltar' nao esta no manifesto -- o endereco cyron://voltar nao entrou")

aud = sum(i.file_size for i in z.infolist() if re.search(r"\.(ogg|mp3|wav)", i.filename))
print("Audio embarcado: %.1f MB" % (aud / 1e6))
if aud < 50e6:
    problemas.append("audio de menos (%.1f MB) -- o app sairia mudo de novo" % (aud / 1e6))

nomes = z.namelist()
if not any("modulos" in n and "lista" in n for n in nomes):
    problemas.append("modulos/lista.json nao entrou -- pacote nao teria o que substituir")

# O carimbo da versao. Sem ele o app volta a nao saber qual APK e' -- e o painel
# de manutencao volta a mentir, que foi o defeito que motivou tudo isto.
if not any("versao_build" in n for n in nomes):
    problemas.append("versao_build.json nao entrou -- o app nao saberia qual APK esta rodando")

if problemas:
    print("\nREPROVADO:")
    for p in problemas:
        print("  -", p)
    sys.exit(1)
print("\nOK: permissoes, pacote, audio e lista de modulos conferidos no APK.")
PY
