extends Node
## Autoload vazio, guardado de proposito. Nao faz nada -- e' esse o ponto.
##
## POR QUE EXISTE
##
## Um pacote nao cria autoload (a lista mora no project.binary, lido no
## arranque). E um script que MENCIONA autoload inexistente nem compila. Entao,
## sem isto, todo nome global novo custa um APK novo.
##
## Estes tres nomes ja' nascem registrados e vazios. Um pacote troca o script de
## um deles, e na abertura seguinte `Reserva1` e' o sistema que faltava --
## inclusive para outros scripts do pacote que o citam pelo nome, o que
## `Modulos.pegar()` nao consegue oferecer.
##
## PREFIRA O `Modulos`. Ele da' nome de verdade ("loja"), aceita quantos modulos
## quiser e nao gasta vaga. Estas reservas sao a saida para o unico caso que ele
## nao cobre: quando o codigo precisa do nome global ja' em tempo de compilacao.
##
## Gastar uma reserva e' definitivo ate' o proximo APK. Sao tres. Nao gaste por
## comodidade.
