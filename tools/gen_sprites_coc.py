# -*- coding: utf-8 -*-
"""Gera sprites SVG isométricos para os edifícios da vila CoC.
Cada tipo tem silhueta própria. Fundo transparente. 128x128.
Saída: assets/cidade/coc/<tipo>.svg
"""
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "cidade", "coc")
os.makedirs(OUT, exist_ok=True)

W = 128
CX = 64

def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" '
            'viewBox="0 0 128 128">\n' + body + '\n</svg>\n')

def base(col="#3a2a16", top="#5a4220"):
    # plataforma isométrica (losango) na base
    return (f'<polygon points="64,96 116,116 64,128 12,116" fill="{col}"/>\n'
            f'<polygon points="64,90 110,108 64,118 18,108" fill="{top}"/>\n')

def shadow():
    return '<ellipse cx="64" cy="112" rx="46" ry="13" fill="#000" opacity="0.22"/>\n'

def roof(x, y, w, h, col):
    # telhado triangular
    return f'<polygon points="{x},{y} {x+w},{y} {x+w/2},{y-h}" fill="{col}"/>\n'

def wall(x, y, w, h, col, stroke="#000"):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="{col}" stroke="{stroke}" stroke-width="2" opacity="0.95"/>\n'

def flag(x, y, col):
    return (f'<line x1="{x}" y1="{y}" x2="{x}" y2="{y-22}" stroke="#cfcfcf" stroke-width="2"/>\n'
            f'<polygon points="{x},{y-22} {x+16},{y-17} {x},{y-12}" fill="{col}"/>\n')

# ── builders por tipo ─────────────────────────────────────────────────────────
def b_prefeitura():
    s = shadow() + base("#5a3a14", "#7a5020")
    s += wall(40, 44, 48, 44, "#c8a24a", "#5a3c10")
    s += roof(36, 44, 56, 24, "#b23030")
    s += wall(56, 64, 16, 24, "#7a5a20")               # porta
    s += '<rect x="46" y="52" width="10" height="10" fill="#2a3a6a"/>\n'
    s += '<rect x="72" y="52" width="10" height="10" fill="#2a3a6a"/>\n'
    s += flag(64, 20, "#ffd23c")
    return svg(s)

def b_tank(col, liquid):
    # tanque/depósito cilíndrico
    s = shadow() + base()
    s += f'<rect x="38" y="46" width="52" height="44" rx="10" fill="{col}" stroke="#000" stroke-width="2"/>\n'
    s += f'<ellipse cx="64" cy="46" rx="26" ry="9" fill="{liquid}"/>\n'
    s += f'<rect x="44" y="60" width="40" height="22" rx="6" fill="{liquid}" opacity="0.6"/>\n'
    return svg(s)

def b_mina(col, gem):
    # monte com picareta + minério
    s = shadow() + base()
    s += '<polygon points="34,90 64,52 94,90" fill="#6a5230" stroke="#000" stroke-width="2"/>\n'
    s += f'<polygon points="56,90 64,68 72,90" fill="{col}"/>\n'
    s += f'<circle cx="64" cy="72" r="6" fill="{gem}"/>\n'
    s += '<line x1="80" y1="48" x2="92" y2="36" stroke="#9a6a30" stroke-width="4"/>\n'
    s += '<path d="M86 30 q10 -2 14 8" stroke="#cfcfcf" stroke-width="5" fill="none"/>\n'
    return svg(s)

def b_tenda(col):
    # acampamento: tenda
    s = shadow() + base("#3a3a1a", "#55551f")
    s += f'<polygon points="64,40 100,92 28,92" fill="{col}" stroke="#000" stroke-width="2"/>\n'
    s += '<polygon points="64,40 72,92 56,92" fill="#000" opacity="0.18"/>\n'
    s += '<polygon points="58,92 64,70 70,92" fill="#20160a"/>\n'
    return svg(s)

def b_quartel(col, dark=False):
    s = shadow() + base()
    base_wall = "#3a3a3a" if dark else "#5a6a7a"
    s += wall(38, 50, 52, 40, base_wall, "#000")
    s += roof(34, 50, 60, 18, col)
    # espada cruzada
    s += '<line x1="50" y1="84" x2="78" y2="60" stroke="#dfe6ee" stroke-width="4"/>\n'
    s += '<line x1="78" y1="84" x2="50" y2="60" stroke="#b9c2cc" stroke-width="4"/>\n'
    s += '<rect x="58" y="70" width="12" height="6" fill="#caa23a"/>\n'
    return svg(s)

def b_fabrica(col, dark=False):
    s = shadow() + base()
    wcol = "#3a2a4a" if dark else "#5a3a6a"
    s += wall(40, 48, 48, 42, wcol, "#000")
    # caldeirão + bolha mágica
    s += f'<ellipse cx="64" cy="74" rx="18" ry="10" fill="{col}"/>\n'
    s += f'<circle cx="64" cy="58" r="9" fill="{col}" opacity="0.85"/>\n'
    s += '<circle cx="58" cy="50" r="4" fill="#ffffff" opacity="0.7"/>\n'
    s += '<rect x="56" y="40" width="16" height="6" fill="#2a1a3a"/>\n'
    return svg(s)

def b_lab():
    s = shadow() + base()
    s += wall(40, 48, 48, 42, "#4a2e6a", "#000")
    # frasco/erlenmeyer
    s += '<polygon points="58,54 70,54 78,84 50,84" fill="#9a5cff" stroke="#000" stroke-width="2" opacity="0.9"/>\n'
    s += '<rect x="58" y="48" width="12" height="8" fill="#cbb3ee"/>\n'
    s += '<rect x="52" y="74" width="24" height="8" fill="#c8ff5a" opacity="0.85"/>\n'
    s += '<circle cx="62" cy="78" r="2.5" fill="#fff" opacity="0.8"/>\n'
    return svg(s)

def b_canhao():
    s = shadow() + base("#2a2a2a", "#3f3f3f")
    s += '<rect x="44" y="66" width="40" height="22" rx="6" fill="#555" stroke="#000" stroke-width="2"/>\n'
    s += '<circle cx="64" cy="70" r="14" fill="#3a3a3a" stroke="#000" stroke-width="2"/>\n'
    s += '<rect x="62" y="38" width="14" height="34" rx="5" fill="#6a6a6a" stroke="#000" stroke-width="2" transform="rotate(28 64 64)"/>\n'
    s += '<circle cx="64" cy="70" r="5" fill="#222"/>\n'
    return svg(s)

def b_torre_arq():
    s = shadow() + base("#3a2a14", "#5a3c1c")
    s += '<rect x="48" y="44" width="32" height="46" fill="#8a6a3a" stroke="#000" stroke-width="2"/>\n'
    s += '<polygon points="44,44 84,44 64,28" fill="#6a4a22"/>\n'
    # flecha
    s += '<line x1="50" y1="60" x2="82" y2="60" stroke="#dfe6ee" stroke-width="3"/>\n'
    s += '<polygon points="82,60 74,56 74,64" fill="#dfe6ee"/>\n'
    s += '<rect x="56" y="74" width="16" height="14" fill="#3a2a14"/>\n'
    return svg(s)

def b_morteiro():
    s = shadow() + base("#2a2a2a", "#3f3f3f")
    s += '<rect x="42" y="70" width="44" height="18" rx="5" fill="#4a4a4a" stroke="#000" stroke-width="2"/>\n'
    # tubo curto largo apontando pra cima
    s += '<polygon points="50,72 78,72 72,44 56,44" fill="#5f5f5f" stroke="#000" stroke-width="2"/>\n'
    s += '<ellipse cx="64" cy="44" rx="9" ry="4" fill="#222"/>\n'
    s += '<circle cx="64" cy="38" r="6" fill="#1a1a1a"/>\n'
    return svg(s)

def b_def_aerea():
    s = shadow() + base("#1f2a2a", "#2f4040")
    s += '<rect x="46" y="70" width="36" height="18" rx="5" fill="#2f5a5a" stroke="#000" stroke-width="2"/>\n'
    # canos duplos pra cima
    s += '<rect x="54" y="40" width="6" height="34" fill="#6acaca" transform="rotate(-12 57 60)"/>\n'
    s += '<rect x="68" y="40" width="6" height="34" fill="#6acaca" transform="rotate(12 71 60)"/>\n'
    s += '<circle cx="64" cy="74" r="6" fill="#1f3a3a"/>\n'
    return svg(s)

def b_torre_mago():
    s = shadow() + base("#26203a", "#3a3056")
    s += '<rect x="50" y="48" width="28" height="42" fill="#5a4a8a" stroke="#000" stroke-width="2"/>\n'
    s += '<polygon points="46,48 82,48 64,26" fill="#3a2a6a"/>\n'
    s += '<circle cx="64" cy="58" r="9" fill="#b48cff"/>\n'
    s += '<circle cx="64" cy="58" r="9" fill="none" stroke="#fff" stroke-width="1.5" opacity="0.6"/>\n'
    s += '<circle cx="64" cy="20" r="4" fill="#d8c0ff"/>\n'
    return svg(s)

def b_tesla():
    s = shadow() + base("#1f2a30", "#2f4048")
    s += '<rect x="54" y="60" width="20" height="28" rx="4" fill="#3a4a55" stroke="#000" stroke-width="2"/>\n'
    s += '<circle cx="64" cy="50" r="12" fill="#2a3a44" stroke="#000" stroke-width="2"/>\n'
    s += '<circle cx="64" cy="50" r="6" fill="#7ee0ff"/>\n'
    s += '<polyline points="64,38 58,30 68,24 60,16" fill="none" stroke="#9af0ff" stroke-width="2"/>\n'
    s += '<polyline points="76,52 86,48 82,40" fill="none" stroke="#9af0ff" stroke-width="2"/>\n'
    return svg(s)

def b_xbow():
    s = shadow() + base("#2a2a30", "#3f3f48")
    s += '<rect x="50" y="66" width="28" height="20" rx="5" fill="#4a4a55" stroke="#000" stroke-width="2"/>\n'
    s += '<path d="M40 56 q24 -18 48 0" fill="none" stroke="#8a8a99" stroke-width="4"/>\n'
    s += '<line x1="40" y1="56" x2="88" y2="56" stroke="#5a5a66" stroke-width="2"/>\n'
    s += '<line x1="64" y1="56" x2="64" y2="40" stroke="#dfe6ee" stroke-width="3"/>\n'
    s += '<polygon points="64,40 60,46 68,46" fill="#dfe6ee"/>\n'
    return svg(s)

def b_muralha():
    s = shadow() + base("#2e2e2e", "#454545")
    s += '<rect x="40" y="56" width="48" height="32" rx="3" fill="#8a8a8a" stroke="#000" stroke-width="2"/>\n'
    # ameias
    for x in (40, 54, 68, 82):
        s += f'<rect x="{x}" y="48" width="10" height="12" fill="#9a9a9a" stroke="#000" stroke-width="1.5"/>\n'
    s += '<line x1="40" y1="70" x2="88" y2="70" stroke="#555" stroke-width="2"/>\n'
    s += '<line x1="56" y1="56" x2="56" y2="70" stroke="#555" stroke-width="2"/>\n'
    s += '<line x1="72" y1="70" x2="72" y2="88" stroke="#555" stroke-width="2"/>\n'
    return svg(s)

def b_cabana():
    s = shadow() + base("#3a2a14", "#5a3c1c")
    s += wall(42, 54, 44, 34, "#b9742a", "#000")
    s += roof(38, 54, 52, 18, "#8a4a1a")
    # martelo
    s += '<line x1="58" y1="82" x2="70" y2="64" stroke="#9a6a30" stroke-width="4"/>\n'
    s += '<rect x="66" y="58" width="16" height="9" rx="2" fill="#c0c0c0" stroke="#000" stroke-width="1.5"/>\n'
    return svg(s)

def b_castelo():
    s = shadow() + base("#2e2e2e", "#454545")
    s += wall(40, 52, 48, 36, "#9a9aa6", "#000")
    for x in (38, 66):
        s += f'<rect x="{x}" y="40" width="22" height="48" fill="#8a8a96" stroke="#000" stroke-width="2"/>\n'
        s += f'<rect x="{x}" y="34" width="8" height="8" fill="#8a8a96"/>\n'
        s += f'<rect x="{x+14}" y="34" width="8" height="8" fill="#8a8a96"/>\n'
    s += '<rect x="56" y="66" width="16" height="22" rx="6" fill="#3a2a1a"/>\n'
    s += flag(64, 30, "#b23030")
    return svg(s)

def b_altar(col):
    s = shadow() + base("#2a2030", "#3f3048")
    s += '<rect x="46" y="64" width="36" height="22" rx="4" fill="#5a4a6a" stroke="#000" stroke-width="2"/>\n'
    s += f'<polygon points="64,34 72,60 56,60" fill="{col}"/>\n'      # cristal/herói
    s += f'<circle cx="64" cy="48" r="6" fill="{col}" opacity="0.9"/>\n'
    s += f'<circle cx="64" cy="34" r="3" fill="#ffffff" opacity="0.8"/>\n'
    return svg(s)

BUILDERS = {
    "prefeitura":       b_prefeitura,
    "mina_ouro":        lambda: b_mina("#caa23a", "#ffd23c"),
    "deposito_ouro":    lambda: b_tank("#b9902f", "#ffd23c"),
    "coletor_elixir":   lambda: b_mina("#c046c0", "#ff7cff"),
    "deposito_elixir":  lambda: b_tank("#a23aa2", "#ff7cff"),
    "mina_escura":      lambda: b_mina("#5a3a7a", "#9a5cff"),
    "deposito_escuro":  lambda: b_tank("#3a2a4a", "#7a3aff"),
    "quartel":          lambda: b_quartel("#b23030", False),
    "quartel_escuro":   lambda: b_quartel("#5a2a6a", True),
    "acampamento":      lambda: b_tenda("#3a8a4a"),
    "fabrica_feitico":  lambda: b_fabrica("#b48cff", False),
    "fabrica_escura":   lambda: b_fabrica("#7a3aff", True),
    "laboratorio":      b_lab,
    "canhao":           b_canhao,
    "torre_arqueiros":  b_torre_arq,
    "morteiro":         b_morteiro,
    "def_aerea":        b_def_aerea,
    "torre_mago":       b_torre_mago,
    "tesla":            b_tesla,
    "xbow":             b_xbow,
    "muralha":          b_muralha,
    "cabana_construtor":b_cabana,
    "castelo_cla":      b_castelo,
    "altar_rei":        lambda: b_altar("#ffd23c"),
    "altar_rainha":     lambda: b_altar("#ff7cff"),
}

count = 0
for tipo, fn in BUILDERS.items():
    path = os.path.join(OUT, tipo + ".svg")
    with open(path, "w", encoding="utf-8") as f:
        f.write(fn())
    count += 1
print("Gerados %d sprites SVG em %s" % (count, os.path.normpath(OUT)))
