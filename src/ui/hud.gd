extends Control

const GameConstants = preload("res://src/core/game_constants.gd")

@onready var hp_bar: ProgressBar = $HealthContainer/MarginContainer/HBoxContainer/HPBar
@onready var hp_val: Label = $HealthContainer/MarginContainer/HBoxContainer/HPVal

@onready var dmg_val: Label = $StatsContainer/MarginContainer/VBoxContainer/StatsGrid/DmgVal
@onready var spd_val: Label = $StatsContainer/MarginContainer/VBoxContainer/StatsGrid/SpdVal
@onready var rate_val: Label = $StatsContainer/MarginContainer/VBoxContainer/StatsGrid/RateVal
@onready var elem_val: Label = $StatsContainer/MarginContainer/VBoxContainer/StatsGrid/ElemVal
@onready var chips_val: Label = $StatsContainer/MarginContainer/VBoxContainer/StatsGrid/ChipsVal

@onready var crystal_val: Label = $CrystalsContainer/MarginContainer/HBoxContainer/CrystalVal
@onready var minimap = $MinimapContainer/MarginContainer/VBoxContainer/MinimapView

@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var victory_panel: PanelContainer = $VictoryPanel
@onready var restart_btn: Button = $GameOverPanel/CenterContainer/VBoxContainer/RestartButton
@onready var victory_btn: Button = $VictoryPanel/CenterContainer/VBoxContainer/VictoryButton

@onready var boss_container: PanelContainer = $BossContainer
@onready var boss_name_label: Label = $BossContainer/MarginContainer/VBoxContainer/BossName
@onready var boss_hp_bar: ProgressBar = $BossContainer/MarginContainer/VBoxContainer/BossHPBar

func _ready() -> void:
	restart_btn.pressed.connect(_on_restart_pressed)
	victory_btn.pressed.connect(_on_restart_pressed)
	
	game_over_panel.visible = false
	victory_panel.visible = false
	boss_container.visible = false

func setup_minimap(grid: Dictionary) -> void:
	if minimap:
		minimap.setup_minimap(grid)

func update_current_room(coord: Vector2i) -> void:
	if minimap:
		minimap.set_current_room(coord)

func update_hud(player: Node2D) -> void:
	hp_bar.max_value = player.max_health
	hp_bar.value = player.current_health
	hp_val.text = str(player.current_health) + " / " + str(player.max_health)
	crystal_val.text = str(player.crystals)
	
	dmg_val.text = str(player.damage)
	spd_val.text = str(int(player.speed))
	rate_val.text = "%.2fs" % player.fire_rate
	
	# Mostrar elemento activo
	match player.active_damage_type:
		GameConstants.DamageType.FIRE:
			elem_val.text = "Fuego 🔥"
			elem_val.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
		GameConstants.DamageType.ICE:
			elem_val.text = "Hielo ❄️"
			elem_val.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
		GameConstants.DamageType.POISON:
			elem_val.text = "Veneno 🧪"
			elem_val.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		GameConstants.DamageType.ELECTRIC:
			elem_val.text = "Rayo ⚡"
			elem_val.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
		_:
			elem_val.text = "Físico"
			elem_val.add_theme_color_override("font_color", Color.WHITE)
			
	# Mostrar chips equipados
	var chips: Array[String] = []
	if player.pierce_count > 0:
		chips.append("Pierce +" + str(player.pierce_count))
	if player.split_on_hit:
		chips.append("Split")
	if player.explode_on_kill:
		chips.append("Explosión")
		
	if chips.size() > 0:
		chips_val.text = ", ".join(chips)
		chips_val.add_theme_color_override("font_color", Color(0.9, 0.5, 1.0))
	else:
		chips_val.text = "Ninguno"
		chips_val.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func show_game_over() -> void:
	game_over_panel.visible = true
	# Pausar temporalmente los procesos del juego para que los enemigos dejen de moverse
	get_tree().paused = true

func show_victory() -> void:
	victory_panel.visible = true
	get_tree().paused = true

func show_boss_health(boss_name: String, max_hp: int) -> void:
	boss_name_label.text = boss_name
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = max_hp
	boss_container.visible = true

func update_boss_health(current_hp: int) -> void:
	boss_hp_bar.value = current_hp

func hide_boss_health() -> void:
	boss_container.visible = false

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
