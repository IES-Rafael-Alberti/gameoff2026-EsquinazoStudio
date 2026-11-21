extends Control

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
func _on_continue_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
func _on_level_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
func _on_options_button_pressed():
	print("Abrir opciones")

func _on_exit_button_pressed():
	get_tree().quit()
