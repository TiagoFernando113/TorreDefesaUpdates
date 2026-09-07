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

gradle_build/use_gradle_build=false
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

mkdir -p "$(dirname "$SAIDA")"
echo "Exportando (demora: o audio sozinho tem ~100 MB)..."
"$GODOT" --headless --path . --export-debug "dev" "$SAIDA" >/tmp/exportar_apk_dev.log 2>&1 || {
  echo "a exportacao falhou:"; tail -15 /tmp/exportar_apk_dev.log; exit 1; }

echo
echo "$SAIDA  ($(du -h "$SAIDA" | cut -f1))"
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

aud = sum(i.file_size for i in z.infolist() if re.search(r"\.(ogg|mp3|wav)", i.filename))
print("Audio embarcado: %.1f MB" % (aud / 1e6))
if aud < 50e6:
    problemas.append("audio de menos (%.1f MB) -- o app sairia mudo de novo" % (aud / 1e6))

nomes = z.namelist()
if not any("modulos" in n and "lista" in n for n in nomes):
    problemas.append("modulos/lista.json nao entrou -- pacote nao teria o que substituir")

if problemas:
    print("\nREPROVADO:")
    for p in problemas:
        print("  -", p)
    sys.exit(1)
print("\nOK: permissoes, pacote, audio e lista de modulos conferidos no APK.")
PY
