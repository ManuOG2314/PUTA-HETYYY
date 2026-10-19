extends Node
## Autoload "Audio": punto unico para reproducir SFX.
##
## Los scripts no cargan streams por su cuenta: llaman a Audio.play("nombre").
## Los efectos se generaron proceduralmente a partir de este proyecto (scripts/generate_sfx.py)
## y viven en assets/audio/. (Ver TECHNICAL_LOG.md Entrada 6.)

## Mapa nombre -> ruta. Agregar aqui cualquier SFX nuevo.
## Se usa load() lazy (no preload) para no romper el parse la primera vez
## que Godot escanea el proyecto antes de importar los .wav.
const SFX_PATHS := {
	"shoot": "res://assets/audio/shoot.wav",
	"hit": "res://assets/audio/hit.wav",
	"enemy_die": "res://assets/audio/enemy_die.wav",
	"pickup": "res://assets/audio/pickup.wav",
	"player_hurt": "res://assets/audio/player_hurt.wav",
	"explosion": "res://assets/audio/explosion.wav",
}

const POOL_SIZE := 8

var _cache := {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_idx := 0

func _ready() -> void:
	# Pool de players reutilizables para no instanciar por cada sonido
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_pool.append(p)

	# El gameplay emite senales genericas; Audio decide como suenan.
	# (Desacopla sistema de audio del resto del juego)
	Events.shoot_sfx.connect(func() -> void: play("shoot", -6.0))
	Events.hit_sfx.connect(func() -> void: play("hit", -4.0))
	Events.pickup_sfx.connect(func() -> void: play("pickup", -4.0))
	Events.player_hurt_sfx.connect(func() -> void: play("player_hurt", -2.0))
	Events.enemy_died_sfx.connect(func() -> void: play("enemy_die", -3.0))
	Events.explosion_sfx.connect(func() -> void: play("explosion", -3.0))

func play(name: String, volume_db: float = 0.0) -> void:
	if not SFX_PATHS.has(name):
		push_warning("Audio: SFX desconocido '%s'" % name)
		return
	if not _cache.has(name):
		_cache[name] = load(SFX_PATHS[name])
	var player := _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	player.stream = _cache[name]
	player.volume_db = volume_db
	player.play()
