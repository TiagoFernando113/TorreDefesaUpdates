#!/usr/bin/env python3
"""Dá ao jogo um endereço próprio no Android: cyron://voltar

POR QUE ISTO EXISTE

Depois do login, o jogador está no navegador e precisa voltar ao jogo. Isso
não acontece sozinho, e a razão está medida no aparelho:

  - o Chrome não abre outro aplicativo a partir de um REDIRECIONAMENTO, só a
    partir de um TOQUE (três logins nos registros, sempre igual);
  - e mesmo com um toque ele não abriu. Uma página com três links respondeu por
    quê: falhou a forma com dados, falhou a forma sem dados, e falhou até abrir
    as CONFIGURAÇÕES DO ANDROID.

O terceiro é o que fecha a conta. As Configurações existem em todo aparelho e
também só têm tela de abertura. Se nem elas abrem, o problema não é do jogo.

A causa é o Chrome acrescentar CATEGORY_BROWSABLE a todo intent:// que dispara.
Um app cujo único intent-filter é MAIN/LAUNCHER não declara BROWSABLE, então
nada casa. Por isso o jogo precisa declarar um filtro próprio — e é isso que
este arquivo acrescenta ao manifesto.

POR QUE UM ALIAS NOVO, E NAO UM FILTRO NO QUE JA EXISTE

A primeira versao pendurava o intent-filter no `.GodotAppLauncher`, que e' o
alias de abertura do Godot. O filtro entrava no arquivo e sumia do APK. O
diagnostico na esteira mostrou por que: o manifesto de variante que o Godot
gera na exportacao declara

    <activity-alias tools:node="mergeOnlyAttributes"
                    android:name=".GodotAppLauncher" ...>

`mergeOnlyAttributes` manda o Gradle fundir SO' OS ATRIBUTOS desse no' e
DESCARTAR os filhos vindos dos manifestos de menor prioridade -- que e'
exatamente onde o nosso filtro estava.

Entao nao se disputa esse no'. Cria-se um alias PROPRIO. O Godot nao sabe que
ele existe, nao poe marca nenhuma nele, e a fusao o mantem inteiro.

Alias nao precisa de codigo Java: ele so' aponta para uma atividade que ja'
existe. E como a `.GodotApp` usa launchMode="singleInstancePerTask", abrir o
endereco traz a instancia que JA' ESTA ABERTA para a frente, em vez de comecar
outra -- o jogo volta com o login pendente intacto.

Ele tambem NAO leva a categoria LAUNCHER, entao nao aparece um segundo icone
na gaveta de aplicativos.

POR QUE MEXER NO XML EM VEZ DE PROCURAR TEXTO

O manifesto vem do modelo do Godot e muda entre versões. Um sed procurando uma
linha específica passaria a não achar nada um dia, em silêncio — e o APK sairia
sem o endereço, com a esteira verde. Aqui o XML é lido de verdade: se a
atividade de abertura não for encontrada, isto REPROVA.

E a conferência que vale mesmo é a outra ponta: o exportar_apk_dev.sh confere o
esquema dentro do APK QUE SAIU, não neste arquivo.
"""

import sys
import xml.etree.ElementTree as ET

AND = "http://schemas.android.com/apk/res/android"
ESQUEMA = "cyron"
HOST = "voltar"
NOME_DO_ALIAS = ".CyronVoltar"


def attr(nome: str) -> str:
    return "{%s}%s" % (AND, nome)


def achar_atividade_de_abertura(raiz: ET.Element):
    """O componente que o Android abre ao tocar no ícone.

    Cuidado com o que ele NÃO é. No Godot 4.6.2 a `.GodotApp` está declarada
    com `android:exported="false"` — ela não pode ser aberta de fora. Quem leva
    MAIN/LAUNCHER é um `<activity-alias>` chamado `.GodotAppLauncher`, e é ele
    que é exportado.

    A primeira versão disto procurava só por `<activity>` e não teria achado
    nada. Por isso a busca cobre os dois, e por isso a checagem de `exported`
    logo abaixo existe: pendurar o endereço num componente não exportado daria
    um APK que parece certo e não abre.
    """
    for tag in ("activity", "activity-alias"):
        for comp in raiz.iter(tag):
            for filtro in comp.findall("intent-filter"):
                for cat in filtro.findall("category"):
                    if cat.get(attr("name")) == "android.intent.category.LAUNCHER":
                        return comp
    return None


def achar_aplicacao(raiz: ET.Element):
    return raiz.find("application")


def ja_tem_o_alias(aplicacao: ET.Element) -> bool:
    for alias in aplicacao.findall("activity-alias"):
        if alias.get(attr("name")) == NOME_DO_ALIAS:
            return True
    return False


def alvo_do_alias(abertura: ET.Element) -> str:
    """Para onde o alias novo aponta.

    Se a abertura ja' e' um alias, o alvo dela e' a atividade de verdade -- e e'
    para essa que se aponta, nao para o alias (alias de alias nao existe).
    """
    if abertura.tag == "activity-alias":
        return abertura.get(attr("targetActivity"), "")
    return abertura.get(attr("name"), "")


def main() -> int:
    if len(sys.argv) != 2:
        print("uso: endereco_proprio_android.py <AndroidManifest.xml>")
        return 2
    caminho = sys.argv[1]

    ET.register_namespace("android", AND)
    ET.register_namespace("tools", "http://schemas.android.com/tools")

    try:
        arvore = ET.parse(caminho)
    except (OSError, ET.ParseError) as e:
        print("nao consegui ler o manifesto em %s: %s" % (caminho, e))
        return 1

    raiz = arvore.getroot()
    aplicacao = achar_aplicacao(raiz)
    if aplicacao is None:
        print("nao achei <application> no manifesto.")
        return 1

    abertura = achar_atividade_de_abertura(raiz)
    if abertura is None:
        print("nao achei a atividade de abertura (MAIN/LAUNCHER) no manifesto.")
        print("o modelo do Godot deve ter mudado de formato -- sem ela nao da'")
        print("para saber para onde o alias novo aponta.")
        return 1

    alvo = alvo_do_alias(abertura)
    if not alvo:
        print("a abertura (%s) nao diz para qual atividade aponta." % abertura.tag)
        return 1

    if ja_tem_o_alias(aplicacao):
        print("o alias %s ja' existe -- nada a fazer" % NOME_DO_ALIAS)
        return 0

    alias = ET.SubElement(aplicacao, "activity-alias", {
        attr("name"): NOME_DO_ALIAS,
        attr("targetActivity"): alvo,
        # Sem exported=true nenhum outro app pode abrir -- e o navegador e'
        # outro app. E' a linha que faz a coisa toda funcionar.
        attr("exported"): "true",
    })
    filtro = ET.SubElement(alias, "intent-filter")
    ET.SubElement(filtro, "action", {attr("name"): "android.intent.action.VIEW"})
    # DEFAULT porque o intent chega sem componente definido; BROWSABLE porque e'
    # exatamente a categoria que o navegador acrescenta -- sem ela nada casa, que
    # e' o defeito inteiro. Nada de LAUNCHER: isso poria um segundo icone na
    # gaveta de aplicativos.
    ET.SubElement(filtro, "category", {attr("name"): "android.intent.category.DEFAULT"})
    ET.SubElement(filtro, "category", {attr("name"): "android.intent.category.BROWSABLE"})
    ET.SubElement(filtro, "data", {attr("scheme"): ESQUEMA, attr("host"): HOST})

    arvore.write(caminho, encoding="utf-8", xml_declaration=True)
    print("alias %s -> %s com %s://%s" % (NOME_DO_ALIAS, alvo, ESQUEMA, HOST))

    # Ler de volta o que foi gravado. Escrever e supor que deu certo e' como o
    # preset com a chave errada: nao da' erro, so' fica sem efeito.
    conferencia = ET.parse(caminho)
    de_volta = achar_aplicacao(conferencia.getroot())
    if de_volta is None or not ja_tem_o_alias(de_volta):
        print("gravei o manifesto mas o alias nao esta la' na releitura.")
        return 1
    print("conferido na releitura do arquivo.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
