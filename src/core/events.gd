extends Node
## EventBus global del juego (autoload "Events").
##
## Regla: los sistemas NO se comunican con get_tree().current_scene ni con
## rutas de nodos; emiten señales aqui y quien le interesa se conecta.
## (ver AUDITORIA.md 2.4 / 6)

## Pedido de sacudida de camara (cualquier sistema puede pedirlo:
## player al recibir dano, enemigos al recibir hits, explosiones...)
signal shake_requested(intensity: float, duration: float)

## Feedback rapido para el Audio autoload (o VFX en el futuro)
signal shoot_sfx
signal hit_sfx
signal pickup_sfx
signal player_hurt_sfx
signal enemy_died_sfx
signal explosion_sfx
