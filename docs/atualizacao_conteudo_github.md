# Atualizacao de Conteudo via GitHub

O jogo usa dois caminhos de atualizacao:

- APK/EXE: somente para builds de teste fora da loja. Em Android/Play Store o aviso externo fica bloqueado por `BuildConfig.allow_external_apk_update()`.
- Conteudo: packs `.pck` ou `.zip` com assets/configs, baixados por manifest e carregados com `ProjectSettings.load_resource_pack()`.

## Manifest

Hospede este arquivo em:

`https://raw.githubusercontent.com/TiagoFernando113/TorreDefesaUpdates/refs/heads/main/content_manifest.json`

Exemplo:

```json
{
  "version": 1,
  "packs": [
    {
      "id": "mapas",
      "version": 1,
      "kind": "assets",
      "url": "https://github.com/TiagoFernando113/TorreDefesaUpdates/releases/download/conteudo-v1/mapas_v1.pck",
      "sha256": "COLOQUE_O_SHA256_DE_64_CARACTERES_AQUI"
    }
  ]
}
```

## Regras de seguranca

- `url` precisa comecar com `https://`.
- `sha256` precisa ter 64 caracteres hexadecimais.
- `kind` nao pode ser `scripts`, `code`, `apk`, `exe` ou equivalente.
- O arquivo precisa terminar em `.pck` ou `.zip`.

## O que pode entrar no pack

- Fundos de mapa.
- Sprites.
- Musicas e sons.
- Configs e dados de balanceamento.
- Imagens de UI.

Evite colocar scripts GDScript nos packs de loja. Para mudanca de codigo, lance um novo APK/AAB.
