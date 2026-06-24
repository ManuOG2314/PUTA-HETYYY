extends Control

@onready var hp_bar: ProgressBar = $HealthContainer/MarginContainer/HBoxContainer/HPBar
@onready var hp_val: Label = $HealthContainer/MarginContainer/HBoxContainer/HPVal

@onready var dmg_val: Label = $StatsContainer/MarginContainer/VBoxContainer/StatsGrid/DmgVal
@onready var spd_val: Label = $StatsContainer/MarginContainer/VBoxContainer/StatsGrid/SpdVal
@onready var rate_val: Label = $StatsContainer/MarginContainer/VBoxContainer/StatsGrid/RateVal

func update_hud(player: Node2D) -> void:
	hp_bar.max_value = player.max_health
	hp_bar.value = player.current_health
	hp_val.text = str(player.current_health) + " / " + str(player.max_health)
	
	dmg_val.text = str(player.damage)
	spd_val.text = str(player.speed)
	rate_val.text = "%.2fs" % player.fire_rate
