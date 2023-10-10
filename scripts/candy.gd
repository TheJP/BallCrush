class_name Candy
extends Node2D


const COLOURS = [
	Color.CRIMSON,
	Color.DODGER_BLUE,
	Color.LIME_GREEN,
	Color.PURPLE,
	Color.YELLOW,
	Color.ORANGE,
]


var index: Vector2i
var colour = 0

func _ready():
	$Sprite.modulate = COLOURS[colour]


func _process(delta):
	pass
