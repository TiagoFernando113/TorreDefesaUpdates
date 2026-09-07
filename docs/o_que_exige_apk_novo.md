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

### 5. Permissões do Android e o link `cyron://`

Moram no `AndroidManifest.xml`, gerado na exportação. **Não estão cobertos pelo
repositório**, porque `export_presets.cfg` não é versionado (guarda a senha da
keystore).

O APK de desenvolvedor de hoje tem só `INTERNET` e `DUMP`. Conferido abrindo o
manifesto do `dev/CyronDEV.apk`: não há `scheme`, nem `VIEW`, nem `BROWSABLE` —
ou seja, **não existe intent-filter de deep link**, apesar de o
`auth_supabase.gd` declarar uma constante `cyron://auth`. O que aparece no
manifesto com a palavra "cyron" é só o nome do pacote,
`com.tiagofernando.cyrondev`.

Ao exportar o APK de desenvolvedor, marcar também:

- `POST_NOTIFICATIONS` — obrigatório no Android 13+ para qualquer notificação
- `ACCESS_NETWORK_STATE` — distinguir "sem internet" de "servidor fora"
- `VIBRATE` — retorno tátil
- `WAKE_LOCK` — tela acesa em partida longa

E, para o login voltar sozinho ao app no Android, um intent-filter com
`scheme="cyron"`. Sem isso o retorno continua sendo na mão.

> Só marque o que tem uso previsto. Permissão pedida "por via das dúvidas" é
> permissão que aparece para o usuário e não faz nada.

### 6. O resto, que não tem jeito

Motor (Godot 4.6), método de renderização (`mobile`), nome do pacote, ícone,
plugins nativos. Mudar qualquer um é APK novo, e ponto.

---

## Regra prática

Antes de publicar um pacote, a pergunta é sempre a mesma:

> **Ele menciona algum autoload que a build instalada não tem?**

Se menciona, o script não compila lá — e não é um erro barulhento, é um sistema
que simplesmente não sobe. Use `Modulos.pegar()` em vez do nome global, ou gaste
uma `Reserva`.

E teste contra a build instalada antes de mandar. `tools/foto_de_cena.gd` serve
para isso.
