class_name Player
extends CharacterBody2D

const GameConstants = preload("res://src/core/game_constants.gd")

signal health_changed(current: int, maximum: int)
signal stats_changed
signal crystals_changed(count: int)
signal died

@export var speed: float = 500.0
@export var tear_scene: PackedScene
@export var fire_rate: float = 0.4
@export var max_health: int = 6
@export var damage: int = 1
@export var invincibility_time: float = 1.0

var current_health: int
var crystals: int = 0
var _last_x: int = 0
var _last_y: int = 0
var _can_fire: bool = true
var _invincible: bool = false
var _anim_time: float = 0.0
var _current_frame_idx: int = 0
var active_damage_type: int = GameConstants.DamageType.PHYSICAL

var pierce_count: int = 0
var split_on_hit: bool = false
var explode_on_kill: bool = false

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	health_changed.emit(current_health, max_health)
	crystals_changed.emit(crystals)

func _physics_process(_delta: float) -> void:
	var x := _get_axis("move_left", "move_right", _last_x)
	_last_x = x.last

	var y := _get_axis("move_up", "move_down", _last_y)
	_last_y = y.last

	velocity = Vector2(x.value, y.value).normalized() * speed
	move_and_slide()

func _process(delta: float) -> void:
	_handle_aiming()
	_handle_shooting()
	_animate_sprite(delta)

func _handle_aiming() -> void:
	if not has_node("GunPivot"):
		return
	var mouse_pos = get_global_mouse_position()
	var aim_dir = (mouse_pos - $GunPivot.global_position).normalized()
	$GunPivot.rotation = aim_dir.angle()
	
	if has_node("GunPivot/Pistol"):
		var pistol = $GunPivot/Pistol
		if aim_dir.x < 0:
			pistol.flip_v = true
			pistol.position.y = -2.0
		else:
			pistol.flip_v = false
			pistol.position.y = 2.0
			
	if aim_dir.y < -0.15:
		$GunPivot.z_index = -1
	else:
		$GunPivot.z_index = 1

func _animate_sprite(delta: float) -> void:
	var is_moving = velocity.length() > 0.0
	var anim_frames = [0]
	var frame_speed = 0.25
	
	if is_moving:
		anim_frames = [0, 1, 2, 3, 4, 5, 6, 7]
		frame_speed = 0.08
	else:
		anim_frames = [0]
		frame_speed = 0.25
		
	var mouse_pos = get_global_mouse_position()
	if mouse_pos.x < global_position.x:
		$Sprite2D.flip_h = true
	else:
		$Sprite2D.flip_h = false
		
	_anim_time += delta
	if _anim_time >= frame_speed:
		_anim_time = 0.0
		_current_frame_idx = (_current_frame_idx + 1) % anim_frames.size()
		
	if _current_frame_idx >= anim_frames.size():
		_current_frame_idx = 0
		
	var target_frame = anim_frames[_current_frame_idx]
	if $Sprite2D.frame != target_frame:
		$Sprite2D.frame = target_frame

func _handle_shooting() -> void:
	if not _can_fire:
		return
	
	if Input.is_action_pressed("main_fire"):
		var aim_origin: Vector2 = $GunPivot/Pistol/Muzzle.global_position if has_node("GunPivot/Pistol/Muzzle") else global_position
		var fire_direction: Vector2 = aim_origin.direction_to(get_global_mouse_position())
		_shoot(fire_direction)

func _shoot(direction: Vector2) -> void:
	_can_fire = false
	
	var spawn_pos: Vector2 = $GunPivot/Pistol/Muzzle.global_position if has_node("GunPivot/Pistol/Muzzle") else global_position
	
	var new_tear = tear_scene.instantiate()
	new_tear.global_position = spawn_pos
	new_tear.direction = direction
	new_tear.tear_damage = damage
	new_tear.damage_type = active_damage_type
	new_tear.pierce_count = pierce_count
	new_tear.split_on_hit = split_on_hit
	
	get_parent().add_child(new_tear)
	
	if has_node("GunPivot/Pistol"):
		var pistol = $GunPivot/Pistol
		pistol.position.x = 14.0
		var recoil_tween = create_tween()
		recoil_tween.tween_property(pistol, "position:x", 20.0, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# process_always = false: el cooldown se congela si el juego se pausa
	# (pantalla de Game Over/Victoria). Ref AUDITORIA 3.4.
	await get_tree().create_timer(fire_rate, false).timeout
	_can_fire = true

func set_damage_type(type: int) -> void:
	active_damage_type = type
	stats_changed.emit()

func add_pierce(amount: int) -> void:
	pierce_count += amount
	stats_changed.emit()

func enable_split() -> void:
	split_on_hit = true
	stats_changed.emit()

func enable_explode_on_kill() -> void:
	explode_on_kill = true
	stats_changed.emit()

func take_damage(amount: int) -> void:
	if _invincible:
		return
	
	current_health -= amount
	health_changed.emit(current_health, max_health)
	
	if get_tree().current_scene.has_method("add_shake"):
		get_tree().current_scene.add_shake(15.0, 0.4)
		
	if current_health <= 0:
		died.emit()
		return
	
	_invincible = true
	_start_invincibility_blink()
	await get_tree().create_timer(invincibility_time, false).timeout
	_invincible = false
	modulate.a = 1.0
	
	for area in $Hurtbox.get_overlapping_areas():
		if area.is_in_group("enemy_hitbox"):
			_on_hurtbox_area_entered(area)
			break

func _start_invincibility_blink() -> void:
	while _invincible:
		modulate.a = 0.3
		await get_tree().create_timer(0.1, false).timeout
		if not _invincible:
			break
		modulate.a = 1.0
		await get_tree().create_timer(0.1, false).timeout

func heal(amount: int) -> void:
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func add_speed(amount: float) -> void:
	speed += amount
	stats_changed.emit()

func add_damage(amount: int) -> void:
	damage += amount
	stats_changed.emit()

func reduce_fire_rate(amount: float) -> void:
	fire_rate = maxf(fire_rate - amount, 0.1)
	stats_changed.emit()

func add_max_health(amount: int) -> void:
	max_health += amount
	current_health += amount
	health_changed.emit(current_health, max_health)
	stats_changed.emit()

func add_crystals(amount: int) -> void:
	crystals += amount
	crystals_changed.emit(crystals)
	stats_changed.emit()

func spend_crystals(amount: int) -> bool:
	if crystals >= amount:
		crystals -= amount
		crystals_changed.emit(crystals)
		stats_changed.emit()
		return true
	return false

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var enemy = area.get_parent()
		var contact_damage = 1
		if enemy.has_method("get_contact_damage"):
			contact_damage = enemy.get_contact_damage()
		take_damage(contact_damage)


class AxisState:
	var value: int
	var last: int

	func _init(value: int, last: int) -> void:
		self.value = value
		self.last = last

func _get_axis(negative: StringName, positive: StringName, last: int) -> AxisState:
	var neg := Input.is_action_pressed(negative)
	var pos := Input.is_action_pressed(positive)

	if Input.is_action_just_pressed(positive):
		last = 1
	elif Input.is_action_just_pressed(negative):
		last = -1

	var value: int

	if pos == neg:
		value = last if pos else 0
	else:
		value = 1 if pos else -1

	return AxisState.new(value, last)
