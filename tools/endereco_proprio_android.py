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


def attr(nome: str) -> str:
    return "{%s}%s" % (AND, nome)


def achar_atividade_de_abertura(raiz: ET.Element):
    """A atividade que o Android abre ao tocar no ícone.

    É nela que o filtro novo tem de entrar: é a que já existe, já é exportada e
    já é a cara do app. Criar outra atividade exigiria código Java.
    """
    for atividade in raiz.iter("activity"):
        for filtro in atividade.findall("intent-filter"):
            for cat in filtro.findall("category"):
                if cat.get(attr("name")) == "android.intent.category.LAUNCHER":
                    return atividade
    return None


def ja_tem_o_endereco(atividade: ET.Element) -> bool:
    for filtro in atividade.findall("intent-filter"):
        for dado in filtro.findall("data"):
            if dado.get(attr("scheme")) == ESQUEMA:
                return True
    return False


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
    atividade = achar_atividade_de_abertura(raiz)
    if atividade is None:
        print("nao achei a atividade de abertura (MAIN/LAUNCHER) no manifesto.")
        print("o modelo do Godot deve ter mudado de formato -- sem isso o jogo")
        print("nao ganha endereco proprio, e o botao de voltar nao abre o app.")
        return 1

    nome = atividade.get(attr("name"), "(sem nome)")
    if ja_tem_o_endereco(atividade):
        print("a atividade %s ja' tem %s:// -- nada a fazer" % (nome, ESQUEMA))
        return 0

    filtro = ET.SubElement(atividade, "intent-filter")
    ET.SubElement(filtro, "action", {attr("name"): "android.intent.action.VIEW"})
    # DEFAULT porque o intent chega sem componente definido; BROWSABLE porque e'
    # exatamente a categoria que o navegador acrescenta -- sem ela nada casa, que
    # e' o defeito inteiro.
    ET.SubElement(filtro, "category", {attr("name"): "android.intent.category.DEFAULT"})
    ET.SubElement(filtro, "category", {attr("name"): "android.intent.category.BROWSABLE"})
    ET.SubElement(filtro, "data", {attr("scheme"): ESQUEMA, attr("host"): HOST})

    arvore.write(caminho, encoding="utf-8", xml_declaration=True)
    print("endereco %s://%s acrescentado a atividade %s" % (ESQUEMA, HOST, nome))

    # Ler de volta o que foi gravado. Escrever e supor que deu certo e' como o
    # preset com a chave errada: nao da' erro, so' fica sem efeito.
    conferencia = ET.parse(caminho)
    de_volta = achar_atividade_de_abertura(conferencia.getroot())
    if de_volta is None or not ja_tem_o_endereco(de_volta):
        print("gravei o manifesto mas o endereco nao esta la' na releitura.")
        return 1
    print("conferido na releitura do arquivo.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
