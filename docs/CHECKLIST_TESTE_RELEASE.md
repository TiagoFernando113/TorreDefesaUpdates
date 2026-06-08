# Checklist de teste - Cyron Defense

Use este checklist antes de gerar qualquer build de teste ou release. Marque tudo que passou e anote o que falhou.

## 1. Preparacao

- [ ] Abrir o projeto no Godot sem erro de script.
- [ ] Confirmar que a cena inicial abre: `res://scenes/Intro.tscn`.
- [ ] Confirmar que o jogo nao mostra textos de debug para jogador comum.
- [ ] Confirmar que o save usado no teste e o correto: conta zerada ou conta completa.
- [ ] Fazer backup do save antes de testar mudancas grandes.

## 2. Conta zerada

- [ ] Iniciar com conta/save zerado.
- [ ] Verificar se nao aparecem itens gratis indevidos na mochila.
- [ ] Verificar se baus iniciais, premios e recompensas aparecem apenas quando deveriam.
- [ ] Criar perfil com nome, email e senha.
- [ ] Sair e entrar de novo na conta.
- [ ] Confirmar que o save local carrega sem duplicar itens.
- [ ] Confirmar que o save online nao sobrescreve errado a conta zerada.

## 3. Menu principal

- [ ] Logo Cyron Defense aparece alinhado e sem icone redondo estranho.
- [ ] Perfil nao encosta no titulo.
- [ ] Botoes Jogar, Loja, Inventario, Talentos e Sair estao alinhados.
- [ ] Botao Avaliacao nao sobrepoe perfil ou outros elementos.
- [ ] Botoes laterais Acesso, Config, Ranking e Discord funcionam.
- [ ] Fundo do menu nao tem faixa azul forte ou recorte estranho.
- [ ] Versao aparece no canto certo.

## 4. Perfil

- [ ] Abrir perfil.
- [ ] Nome e email aparecem corretamente.
- [ ] Avatares podem ser selecionados.
- [ ] Recordes aparecem sem texto quebrado.
- [ ] Botao Estatisticas abre a tela certa.
- [ ] Estatisticas globais nao mostram caracteres quebrados.
- [ ] Fechar perfil volta ao menu sem travar.

## 5. Inventario

- [ ] Abrir inventario com conta zerada.
- [ ] Abrir inventario com conta cheia.
- [ ] Abas Tudo, Arsenal, Skin, Habil., Cmd. e Cons. filtram corretamente.
- [ ] Cards nao ficam se mexendo dentro do slot.
- [ ] Cards da mochila nao saem do bloco.
- [ ] Imagem de comandante na mochila mostra rosto e nao fica cortada errado.
- [ ] Detalhes do item aparecem com borda e imagem legivel.
- [ ] Card grande do comandante preenche o slot sem sobra lateral.
- [ ] Imagem do comandante mostra bem o topo/bandeira e o corpo.
- [ ] Slots equipados escondem o nome da categoria quando tem item equipado.
- [ ] Itens equipados nao ficam cobertos pelo tema/borda do slot.
- [ ] Estatisticas mostram bonus de comandante, arsenal, defesa, artefato e outros itens.
- [ ] Estatisticas nao passam da linha/painel.
- [ ] Equipar e remover itens atualiza as estatisticas na hora.

## 6. Loja

- [ ] Abrir loja.
- [ ] Comprar melhoria com ouro suficiente.
- [ ] Tentar comprar melhoria sem ouro suficiente.
- [ ] Comprar consumiveis.
- [ ] Comprar/visualizar skins.
- [ ] Itens premium mostram aviso correto se Google Play Billing ainda nao estiver conectado.
- [ ] Textos da loja aparecem sem caracteres quebrados.

## 7. Talentos

- [ ] Abrir arvore de talentos.
- [ ] Aba Ramos funciona.
- [ ] Aba Fusoes funciona.
- [ ] Aba Especiais funciona.
- [ ] Aba Ascensao funciona.
- [ ] Textos "FUSOES", "NODULOS DE FUSAO", "SITUACIONAIS" e "compraveis" aparecem corretos.
- [ ] Titulo e subtitulos nao encostam nos emblemas.
- [ ] Comprar talento com cristais suficientes.
- [ ] Tentar comprar talento sem requisito.
- [ ] Fechar talentos volta ao menu sem travar.

## 8. Mapas

- [ ] Abrir tela de mapas.
- [ ] Selecionar MAPA1.
- [ ] Iniciar partida e confirmar que MAPA1 aparece.
- [ ] Repetir para MAPA2.
- [ ] Repetir para MAPA3.
- [ ] Repetir para MAPA4.
- [ ] Repetir para MAPA5.
- [ ] Repetir para MAPA6.
- [ ] Trocar mapa e confirmar que a partida nao continua usando fundo antigo.
- [ ] Voltar ao menu e confirmar que o mapa salvo permanece selecionado.

## 9. Partida

- [ ] Iniciar partida normal.
- [ ] Pausar e voltar.
- [ ] Testar velocidade 1x.
- [ ] Testar velocidade 1.5x.
- [ ] Testar velocidade 2x.
- [ ] Testar velocidade 3x.
- [ ] Confirmar que HUD nao sobrepoe botoes ou mapa.
- [ ] Confirmar que inimigos entram e seguem rota.
- [ ] Confirmar que tiros acertam inimigos.
- [ ] Confirmar que ouro, score, wave e kills atualizam.
- [ ] Confirmar que vida da torre atualiza.
- [ ] Confirmar que game over abre corretamente.
- [ ] Confirmar que fim de partida salva progresso.

## 10. Zoom e tamanho de tela

- [ ] Testar zoom normal.
- [ ] Testar zoom minimo.
- [ ] Testar zoom maximo.
- [ ] Usar habilidade de alcance e confirmar que o mapa nao quebra.
- [ ] Confirmar que o fundo cobre a area toda em todos os zooms.
- [ ] Confirmar que o mapa nao fica com borda preta indesejada.
- [ ] Testar janela 1280x720.
- [ ] Testar janela menor.
- [ ] Testar janela maior.
- [ ] Testar tela cheia.

## 11. Habilidades e consumiveis

- [ ] Usar Pulso.
- [ ] Usar Bomba.
- [ ] Usar Pulso Final.
- [ ] Usar habilidade do comandante.
- [ ] Usar Barreira.
- [ ] Usar Orbe.
- [ ] Usar Runa.
- [ ] Confirmar cargas sendo consumidas corretamente.
- [ ] Confirmar cooldowns.
- [ ] Confirmar que icones e textos nao quebram no HUD.

## 12. Ranking e online

- [ ] Enviar score para ranking.
- [ ] Abrir ranking.
- [ ] Confirmar posicao com "1o/2o/3o" corrigido para "1º/2º/3º" na interface.
- [ ] Confirmar premios top 3.
- [ ] Testar sem internet.
- [ ] Testar reconectar internet.
- [ ] Confirmar que o jogo nao trava se Supabase falhar.
- [ ] Confirmar save online upload.
- [ ] Confirmar save online download.

## 13. Acessibilidade e audio

- [ ] Abrir configuracoes.
- [ ] Alterar volume de musica.
- [ ] Alterar volume de efeitos.
- [ ] Testar acessibilidade ligada.
- [ ] Testar acessibilidade desligada.
- [ ] Confirmar que TTS nao trava se nao houver chave ou internet.
- [ ] Confirmar que textos falados fazem sentido.

## 14. Android

- [ ] Exportar build Android de teste.
- [ ] Instalar em celular real.
- [ ] Abrir jogo no celular.
- [ ] Testar toque nos menus.
- [ ] Testar toque durante partida.
- [ ] Testar botao voltar do Android.
- [ ] Minimizar e voltar ao jogo.
- [ ] Fechar e abrir novamente.
- [ ] Confirmar que save permanece.
- [ ] Confirmar que nao ha permissoes estranhas pedidas ao usuario.
- [ ] Confirmar performance sem travadas fortes.
- [ ] Confirmar que tela nao corta UI em celular pequeno.

## 15. Release futuro Play Store

- [ ] Confirmar que `BuildConfig.is_store_build()` desliga atualizador externo de APK em Android.
- [ ] Confirmar que build Android usa feature `store_build`.
- [ ] Exportar em formato AAB para loja.
- [ ] Conferir package id definitivo.
- [ ] Conferir version code.
- [ ] Conferir version name.
- [ ] Conferir icone do app.
- [ ] Conferir feature graphic.
- [ ] Conferir screenshots.
- [ ] Conferir politica de privacidade.
- [ ] Preencher nome do responsavel na politica de privacidade.
- [ ] Preencher email de suporte na politica de privacidade.
- [ ] Hospedar politica de privacidade em URL publica antes de enviar para a Play Store.
- [ ] Conferir Data Safety.
- [ ] Conferir classificacao indicativa.
- [ ] Conferir que o atualizador nao baixa APK por fora no Android.

## Resultado do teste

- Data:
- Build:
- Testador:
- Aparelho:
- Passou:
- Falhou:
- Bugs encontrados:
- Prioridade para corrigir:
