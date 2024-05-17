class_name CollectibleNode extends Node2D

var activated := false
@onready var collect_sound = $collectSound


func _ready():
	$AnimationPlayer.play("spin")

func play_sound(pitch : float)-> void:
	if activated:
		return
	$Area2D.set_deferred("monitorable", false)
	#activated = true
	visible = false
	collect_sound.pitch_scale = pitch
	collect_sound.play()

func _on_collect_sound_finished():
	queue_free()
