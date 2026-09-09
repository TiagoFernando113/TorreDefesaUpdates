# O que exige APK novo (e o que não exige mais)

Este arquivo existe por causa de uma reclamação concreta:

> "chato de toda hora ter que baixar um novo porque esqueceu de algo e não
> consegue editar agora"

O problema nunca foi o pacote ser fraco. É que **algumas coisas o motor lê no
arranque**, antes de qualquer pacote existir — e quando falta uma delas, não dá
erro nenhum: a possibilidade simplesmente não existe, e a conta só aparece
depois, na forma de mais um APK.

A resposta é pré-instalar as folgas. Abaixo, o que ficou coberto e o que
sobrou.

---

## Como a atualização chega hoje (ninguém baixa nada)

> "quando vamos parar com esse negócio de baixar e instalar por cima? a ideia
> era ele sempre baixar sozinho"

Parou. Toda mudança em `scripts/`, `ui/`, `scenes/`, `modulos/` e `data/` que
chega na `main` vira um **pacote de ~2 MB**, publicado sozinho por
`.github/workflows/pacote-dev.yml`. O app instalado busca o
`content_manifest_dev.json` ao abrir, baixa o pacote, confere o `sha256` e
aplica **na abertura seguinte**. Abrir duas vezes é tudo.

O APK de 208 MB continua existindo, mas só é montado quando é a única saída —
`project.godot`, `assets/`, `addons/`, permissão do Android. É a lista deste
documento.

**A trava que deixa isso rodar sozinho.** O pacote declara de quais autoloads
ele precisa (`requer_autoloads` no manifesto), e o jogo **recusa baixar** se a
build instalada não tiver todos. É a única armadilha que quebra o app de
verdade — o item 1 aqui embaixo — e agora ela é checada por máquina, antes do
download, em vez de depender de alguém lembrar. Quem não pode receber o pacote
fica na versão do APK, funcionando, até instalar um APK novo.

**A irmã silenciosa: `class_name`.** Nome global também é registrado no
arranque (no `global_script_class_cache.cfg`), e também não chega por pacote —
mesma quebra, mesmo sintoma. Só que aqui o jogo não tem como se defender: o
nome não aparece em lista nenhuma que o pacote possa declarar. Então a defesa
está na montagem: `tools/exportar_pacote_dev.sh` **reprova** o pacote se achar
um `class_name`. O projeto hoje não usa nenhum, então isso não custa nada — e
evita que o primeiro uso vire um defeito que aparece semanas depois, sem pista.

Se ainda assim um pacote deixar o jogo sem abrir, o `Carregador` descarta os
pacotes na abertura seguinte e o app volta ao que veio no APK. Um toque, sem
reinstalar.

As duas esteiras usam a **mesma versão do Godot**, e isso é conferido: o pacote
leva bytecode (`.gdc`), que não vale entre versões do motor.

---

## O que um pacote CONSEGUE fazer

Tudo aqui foi conferido rodando, com o jogo empacotado de verdade — não é
suposição:

| coisa | prova |
|---|---|
| trocar código de cena/lógica | build da barra ciano passou a desenhar a dourada só recebendo um pacote |
| trocar código de **autoload** | um pacote mudou `APP_VERSION_NAME` de dentro do `BuildConfig` |
| **criar sistema novo** | um módulo que não existia no APK subiu, rodou e respondeu a uma chamada |
| trocar imagens, sons, textos, JSON | são arquivos como qualquer outro |
| ajustes de tela, FPS, idiomas, barramentos de áudio | têm equivalente em tempo de execução |

O "trocar autoload" só funciona porque o `Carregador` é o **primeiro** autoload
e trabalha no `_init()`. Se alguém o tirar do primeiro lugar, todos os autoloads
declarados antes dele voltam a ficar fora de alcance. `tests/test_manutencao.gd`
reprova se isso acontecer.

---

## O que um pacote NÃO consegue, nunca

### 1. Criar um autoload

A lista de autoloads mora no `project.binary`, lido pelo motor antes de
qualquer pacote. E é pior do que "o autoload não aparece": **todo script que
menciona um autoload inexistente nem chega a compilar**. Foi assim que um pacote
com o código de setembro quebrou a build de junho:

```
Parse Error: Identifier "Auth" not declared in the current scope.
```

**Coberto agora:**

- `Modulos` — o jeito certo. Um pacote substitui `res://modulos/lista.json`,
  manda os `.gd` junto, e o sistema novo existe. Use `Modulos.pegar("loja")`,
  que resolve em tempo de execução e devolve `null` quando não está instalado.
- `Reserva1`, `Reserva2`, `Reserva3` — três vagas vazias, para o único caso que
  o `Modulos` não cobre: quando o código precisa do **nome global já em tempo de
  compilação**. Gastar uma é definitivo até o próximo APK. São três.

### 2. Ligar o log em arquivo

`debug/file_logging/enable_file_logging` é lido no arranque, e no Android vem
**desligado** de fábrica. Sem ele não existe registro de erro nenhum no
aparelho — "foi mas está sem áudio" era literalmente tudo que dava para saber.

**Coberto agora:** ligado no `project.godot`, e o `DevPainel` mostra na tela.

### 3. Ver o que deu errado / desfazer um pacote ruim

O descarte automático do `Carregador` só dispara depois de uma abertura que
**travou**. Um pacote que apenas deixa o jogo errado — tela torta, sistema
mudo, botão que não responde — não trava nada, e ficaria grudado até
reinstalar.

**Coberto agora:** `DevPainel`. Cinco toques no canto superior esquerdo, dentro
de três segundos. Mostra versão, pacotes aplicados, módulos ativos e recusados,
e os últimos erros do log. Tem botão de descartar pacotes. Só existe no app de
desenvolvedor; no app público o autoload se apaga sozinho no `_ready`.

### 4. Aumentar o tempo de download de um pacote

Era 45 s, fixo dentro de um autoload. Dá conta de um pacote de código
(kilobytes) e não dá dos ~96 MB da trilha sonora, que morria pela metade em
qualquer 4G.

**Coberto agora:** 600 s no app de desenvolvedor, 45 s no público (onde pacote é
ajuste pequeno de propósito).

### 5. Permissões do Android

Moram no `AndroidManifest.xml`, gerado na exportação a partir do
`export_presets.cfg` — que **não é versionado** (guarda a senha da keystore).
Então elas não vêm do repositório: dependem do preset de quem exporta.

O padrão do Godot é pior do que parece. Um preset vazio gera um APK **sem
`INTERNET`** e com o pacote `com.example.cyrondefense` — conferido exportando.
O preset é tudo.

O APK de desenvolvedor atual foi exportado com:

| permissão | para quê |
|---|---|
| `INTERNET` | sem ela não há login, ranking nem pacote |
| `ACCESS_NETWORK_STATE` | distinguir "sem internet" de "servidor fora" |
| `POST_NOTIFICATIONS` | obrigatória no Android 13+ para qualquer notificação |
| `VIBRATE` | retorno tátil |
| `WAKE_LOCK` | tela acesa em partida longa |

(`DUMP` entra sozinha em build de depuração.)

> Só marque o que tem uso previsto. Permissão pedida "por via das dúvidas"
> aparece para o usuário e não faz nada.

### 5b. O deep link `cyron://` — e por que NÃO foi adicionado

O `auth_supabase.gd` declara uma constante `_SCHEME_AND = "cyron://auth"` que
não está ligada a nada. A tentação é "só" adicionar o intent-filter no
manifesto. **Não adiante: não resolveria.**

Conferido, não suposto:

- o template Android do Godot 4.6.2 não trata `onNewIntent` nem `ACTION_VIEW`
  em lugar nenhum;
- o motor não expõe nenhuma API de intent ao GDScript.

Ou seja, com o intent-filter o Android abriria o app — e o `code` do login
morreria no caminho, porque nenhum script conseguiria lê-lo. Seria linha morta
no manifesto dando falsa sensação de recurso pronto.

O loopback que existia aqui **foi removido**, e o parágrafo que o descrevia
estava errado: no Android ele nunca funcionou. O navegador conecta em
`127.0.0.1` e fica girando para sempre, porque o Android congela o app em
segundo plano — a conexão é aceita e nunca atendida. Conferido no aparelho.

Hoje o login volta por uma **ponte**: a página de retorno guarda o `code` numa
tabela de uso único no Supabase do próprio jogo, e o app pergunta por ele.
Sobrevive até o app ser morto.

Um plugin Android (Kotlin) continua sendo o único jeito de ler um intent de
dentro do GDScript, mas o login não precisa mais disso.

### 5c. Por que o app NÃO volta sozinho — e por que não é falta de APK

Aqui estava escrito que o app voltava para a frente sozinho por um `intent://`
disparado pelo navegador. **Não volta.** Isso foi afirmado sem prova e a prova,
quando veio, disse o contrário.

Os registros do servidor, de um login real no aparelho:

```
19:23:21.167   ?code=98d3c0ee…&d=1&s=J_KU…   → 302   servidor mandou o intent://
19:23:21.559   ?s=J_KU…&t=1                  → 200   0,4 s depois: o navegador
                                                     pediu o endereço de reserva
```

O servidor faz a parte dele. O Chrome recebe o `intent://`, **recusa abrir o
app e vai direto para o `S.browser_fallback_url`**. Repetido em três logins
diferentes (16:45, 17:03, 19:23), sempre o mesmo desenho.

O motivo é política do Chrome: ele não abre outro aplicativo a partir de um
**redirecionamento**, só a partir de um **toque** na página. O gesto que
existiu lá atrás — escolher a conta do Google — não atravessa a cadeia de
redirecionamentos entre domínios.

Duas conclusões, para não se repetir a tentativa:

1. **Não adianta trocar o esquema.** `cyron://` com intent-filter no manifesto
   esbarra na mesma política: o bloqueio é do redirecionamento, não do
   esquema. Isso continua não sendo motivo para APK novo.
2. **Voltar sozinho, sem ninguém tocar em nada, não é alcançável por este
   caminho.** O que dá para fazer é um **botão**.

**O 302 foi removido** (função `entrar` v4). Ele só gastava um salto e chegava
no mesmo lugar.

**O texto passou a dizer a verdade.** Antes: *"Pode fechar esta aba e voltar
para o jogo — ele já entrou sozinho."* Fechar a aba não traz o jogo para a
frente, e a pessoa ficava olhando a tela esperando algo que nunca vinha. Agora
pede o que funciona: voltar pelo botão do celular. O login em si continua
automático — o código está na ponte e o jogo o busca sozinho.

### 5d. Nenhuma página com botão sai de `*.supabase.co`

Achei um caminho promissor e ele **morreu no teste**. Fica registrado inteiro,
porque parece uma boa ideia até a hora de medir.

O `content-type` do SVG passa, ao contrário do HTML:

```
pedi: text/html               -> content-type: text/plain
pedi: application/xhtml+xml   -> content-type: text/plain
pedi: image/svg+xml           -> content-type: image/svg+xml   ← passa
```

Como SVG tem `<a href>`, parecia caber um botão. Mas no aparelho o Chrome
**baixou o arquivo** em vez de mostrar a página — o print veio com o endereço
`content://media/external/...`, ou seja, uma cópia salva. E de um arquivo local
nenhum `intent://` funciona.

O motivo apareceu nos cabeçalhos completos, que eu não tinha olhado:

```
content-disposition: attachment
content-security-policy: default-src 'none'; sandbox
```

O gateway **injeta os dois**. E não dá para contornar: mandei
`Content-Disposition: inline` e um CSP frouxo da função, e voltou `attachment`
e `sandbox` do mesmo jeito — ele **sobrescreve**, não completa.

Também não é só das Edge Functions. Subi um HTML para o Storage do mesmo
projeto (o upload é feito pela própria função, com a chave de serviço que já
mora no ambiente dela — a chave nunca sai do servidor) e a resposta foi
idêntica: `text/plain` mais o mesmo CSP `sandbox`.

**É o domínio `*.supabase.co` inteiro**, medida anti-phishing da plataforma.
Nenhuma página interativa sai de lá, por nenhum serviço. O bucket e o arquivo
de teste foram removidos; a função `teste_html_descartavel` ficou inerte
(não há como apagar Edge Function por ferramenta, dá para remover pelo painel).

Isso também fecha os **App Links** (o link `https` verificado que o Android
abre sozinho, sem toque e sem passar pela política do Chrome): eles exigem um
`assetlinks.json` servido como `application/json`, e aqui sairia `text/plain`.

**Conclusão:** o botão — e qualquer chance de voltar sozinho — depende de **uma
página em outro domínio**, dentro do projeto do próprio jogo. O caminho barato
é o GitHub Pages deste repositório: é grátis, não é o site do portal, e a
função `entrar` só precisa passar a redirecionar para lá depois de guardar o
código na ponte (redirecionamento saindo da função não passa pela lista de
endereços do Auth, então nada muda na configuração do login).

### 5e. O botão existe, é tocado, e mesmo assim não abre o app

A página com o botão foi publicada e o toque acontece — o `intent://` dispara,
falha, e cai no plano B (a página recarrega). *"Carrega e não vai."*

Duas causas eram possíveis, com consertos muito diferentes, então em vez de
adivinhar foi ao ar uma página com três links. **Os três falharam**, incluindo
o terceiro, que era o que fechava a conta:

| # | link | resultado |
|---|---|---|
| 1 | a forma com dados (`scheme=https` + `MAIN`/`LAUNCHER`) | não abriu |
| 2 | a mesma coisa **sem dados** (`intent:#Intent;package=…`) | não abriu |
| 3 | **Configurações do Android**, sem dados | **não abriu** |

O 3 é decisivo: as Configurações existem em todo aparelho e também só têm tela
de abertura. Se nem elas abrem, **o problema não é do Cyron nem da forma do
link**.

A causa é o Chrome: ele acrescenta `CATEGORY_BROWSABLE` a todo `intent://` que
dispara. Um app cujo único filtro é `MAIN`/`LAUNCHER` não declara `BROWSABLE`,
então nada casa e o navegador vai para o endereço de reserva.

**Consequência:** para o jogo poder ser aberto pelo navegador, ele precisa
declarar um endereço próprio no `AndroidManifest.xml` — um `<intent-filter>`
com `VIEW` + `DEFAULT` + `BROWSABLE`.

### 5f. O que trava o endereço próprio (e as notificações junto)

O `AndroidManifest.xml` do modelo padrão do Godot **não aceita intent-filter
novo**. Para mexer nele é preciso a *build customizada*: instalar o modelo de
compilação (`--install-android-build-template`), ligar `use_gradle_build` no
preset e compilar com Gradle.

O mesmo bloqueio segura outra coisa: o `Notificacoes` fala com um plugin nativo
`CyronPush` que **não existe no APK montado pela esteira** — plugin nativo
também só entra por build customizada. Por isso `plugin_disponivel()` é falso
no app de desenvolvedor, e a saída "avisar por notificação para a pessoa tocar
e voltar" está fechada pelo mesmo motivo.

Ou seja: **uma mudança destrava as duas.** Mas ela troca a exportação simples
por uma compilação Gradle completa — mais lenta, com mais o que dar errado, num
caminho que hoje funciona. Não é uma decisão para tomar sozinho no fim de uma
sessão longa.

Enquanto isso não for feito, o login funciona assim: escolher a conta, tocar em
◁ (voltar), e o jogo já está logado. A página diz exatamente isso.

### 6. O resto, que não tem jeito

Motor (Godot 4.6), método de renderização (`mobile`), nome do pacote, ícone,
plugins nativos. Mudar qualquer um é APK novo, e ponto.

---

## Regra prática

A pergunta continua sendo a mesma — só que agora quem responde é a máquina:

> **O pacote menciona algum autoload que a build instalada não tem?**

Se menciona, o script não compila lá, e como o pacote é aplicado no arranque, o
jogo para de abrir. Por isso o campo `requer_autoloads` existe e o
`_tem_todos_autoloads` do `atualizador.gd` recusa o download.
`tests/test_pacote_sozinho.gd` reprova se alguém tirar qualquer uma das duas
pontas.

Ainda assim, ao **escrever** o código a regra de sempre vale: prefira
`Modulos.pegar()` ao nome global de um autoload, ou gaste uma `Reserva`. Assim
a mesma mudança serve para quem está no APK antigo, em vez de ficar esperando
um APK novo.

Se acrescentar um autoload for inevitável, o APK sai sozinho no mesmo push
(`project.godot` está no filtro do `apk-dev.yml`) — e aí sim é instalar por
cima, uma vez.
