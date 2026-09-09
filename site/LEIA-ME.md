# A pasta `site/` — a página de voltar ao jogo

## Por que ela existe

O jogador termina o login no navegador e precisa voltar para o jogo. Isso não
acontece sozinho, e a razão está medida:

- O Chrome **não abre outro aplicativo a partir de um redirecionamento**. Só a
  partir de um **toque** na página. Provado nos registros do servidor: o `302`
  para `intent://` saía, e 0,4 s depois o navegador já estava no endereço de
  reserva. Três logins, sempre igual.
- Logo, é preciso um **botão**. Botão exige HTML de verdade.
- E HTML de verdade **não sai de `*.supabase.co`**: o gateway força
  `text/plain` no HTML e, no SVG, injeta `content-disposition: attachment` mais
  um CSP `sandbox` — sobrescrevendo o que a função mandar. O Storage do mesmo
  projeto faz igual. É o domínio inteiro, medida anti-phishing da plataforma.

Sobrou uma página em outro domínio. Esta pasta é essa página, publicada pelo
GitHub Pages **deste repositório** — não no site do portal da Aliança, que é
outro projeto e não deve segurar o login deste jogo.

## Por que dois arquivos, e sem JavaScript

`voltar-dev.html` e `voltar.html` são iguais menos por uma coisa: o nome do
pacote dentro do `intent://`. Um abre o app de desenvolvedor, o outro o jogo
publicado.

Daria para ser um arquivo só, lendo `?d=1` com JavaScript. Não é, por dois
motivos:

1. **O nome do pacote nunca vem da URL.** Se viesse, este endereço viraria um
   jeito de fazer o Android abrir qualquer aplicativo instalado — bastaria
   mandar o link para alguém. Com dois arquivos fixos, não há o que injetar.
2. **Sem JavaScript, não há como o botão falhar.** É um `<a href>`. Quem
   escolhe qual arquivo abrir é a função `entrar`, no servidor, que já tem a
   lista fechada de pacotes.

## O que a página NÃO faz

Ela não faz login, não recebe o `code` e não fala com o Supabase. Quando o
jogador chega aqui, o código **já está guardado na ponte** e o jogo vai
buscá-lo sozinho. O botão é conveniência: encurta o caminho de volta.

Por isso a página funciona mesmo se o botão não abrir o app — o texto embaixo
dele diz o que fazer, e o login se completa do mesmo jeito.

## Como é publicada

`.github/workflows/pagina-voltar.yml`, a cada mudança em `site/`.

**O Pages precisa ser ligado uma vez, na mão.** Tentei fazer a esteira ligar
sozinha (`actions/configure-pages` com `enablement: true`) e não dá:

```
Create Pages site failed.
Error: Resource not accessible by integration
```

O `GITHUB_TOKEN` do Actions **publica** num Pages que já existe, mas não
**cria** o site — criar exige permissão de administração do repositório. É uma
vez só:

> Settings → Pages → Build and deployment → **Source: GitHub Actions**

Enquanto isso não for feito, o primeiro passo do workflow para com essa
instrução impressa, em vez do erro acima, que não diz nada a quem está lendo.

Endereço: `https://tiagofernando113.github.io/TorreDefesaUpdates/voltar-dev.html`
