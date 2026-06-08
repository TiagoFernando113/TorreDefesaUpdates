# Notificacoes Push Android

O jogo agora tem a camada Godot `Notificacoes`:

- Autoload: `res://scripts/notificacoes.gd`
- Manifest de avisos: `https://raw.githubusercontent.com/TiagoFernando113/TorreDefesaUpdates/refs/heads/main/notices.json`
- Permissao Android 13+: `permissions/post_notifications=true`
- Plugin Android esperado: singleton `CyronPush`

## O que ja funciona no Godot

- O jogo baixa e interpreta `notices.json`.
- O jogo salva se o jogador ativou/desativou notificacoes.
- O jogo pede `android.permission.POST_NOTIFICATIONS` em Android.
- Se existir um plugin Android chamado `CyronPush`, o jogo chama:
  - `requestToken()`
  - `setEnabled(bool)`
  - `syncNotices(json)`
- Se o plugin emitir sinais, o jogo recebe:
  - `token_received(token)`
  - `notification_received(id, tipo, titulo, corpo)`

## Arquivo notices.json no GitHub

Crie na raiz do repo `TorreDefesaUpdates`:

```json
{
  "version": 1,
  "notices": [
    {
      "id": "update_v11",
      "title": "Atualizacao disponivel",
      "body": "A v11 esta pronta com sistema de conteudo via GitHub.",
      "type": "update",
      "button": "ATUALIZAR",
      "url": "https://github.com/TiagoFernando113/TorreDefesaUpdates/releases/latest"
    }
  ]
}
```

## Para virar push real com o jogo fechado

1. Criar projeto no Firebase.
2. Adicionar app Android com package:
   `com.tiago.cyrondefense`
3. Baixar `google-services.json`.
4. Criar/instalar plugin Android FCM que registre o singleton `CyronPush`.
5. Exportar Android com Gradle/custom build ou AAR plugin.
6. Testar envio pelo Firebase Console.

Sem o plugin nativo/Firebase, o Godot consegue preparar e ler avisos, mas nao recebe push real enquanto o jogo esta fechado.
