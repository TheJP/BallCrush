class_name Tile
extends Node2D


const DEFAULT_COLOUR = Color(0.341, 0.341, 0.341)
const CLICKED_COLOUR = Color.MEDIUM_SEA_GREEN


signal on_click(index)


var index: Vector2i
var mouse_over: bool
var clicked: bool


func _process(delta):
		update_colour()


func _input(event):
	var is_click = mouse_over and\
		event is InputEventMouseButton and\
		event.button_index == MOUSE_BUTTON_LEFT and\
		event.is_pressed()
	if is_click:
		clicked = true
		on_click.emit(index)


func _on_area_2d_mouse_entered():
	mouse_over = true


func _on_area_2d_mouse_exited():
	mouse_over = false


func update_colour():
	var alpha = 1.0 if mouse_over else 0.7
	if clicked:
		$Background.modulate = Color(CLICKED_COLOUR, alpha)
	else:
		$Background.modulate = Color(DEFAULT_COLOUR, alpha)
