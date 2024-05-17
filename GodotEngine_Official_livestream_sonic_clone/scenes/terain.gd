extends Node2D



func _input(event:InputEvent):
	if event.is_action_pressed("ui_cancel"):
		print("pressed cancled")
		get_tree().paused = !get_tree().paused
