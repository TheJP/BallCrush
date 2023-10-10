extends Node2D


const GRID_HEIGHT = 10
const GRID_WIDTH = 10
const MOVE_ANIMATION_TIME = 0.5


var tile_scene = preload("res://scenes/tile.tscn")
var candy_scene = preload("res://scenes/candy.tscn")


var tiles = []
var candies = []
var current_click = null
var height: float = 100.0
var moves = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	var viewport_size = get_viewport_rect().size
	height = viewport_size.y / (GRID_HEIGHT + 1)
	for y in range(GRID_HEIGHT):
		var tile_row = []
		var candy_row = []
		for x in range(GRID_WIDTH):
			var index = Vector2i(x, y)
			var position = tile_position(index)

			var tile: Tile = tile_scene.instantiate()
			add_child(tile)
			tile.position = position
			tile.index = index
			tile.on_click.connect(_tile_on_click)
			tile_row.append(tile)

			var candy: Candy = candy_scene.instantiate()
			candy.colour = randi_range(0, len(Candy.COLOURS) - 1)
			add_child(candy)
			candy.position = position
			candy.index = index
			candy_row.append(candy)
		tiles.append(tile_row)
		candies.append(candy_row)


func _tile_on_click(index: Vector2i):
	if current_click == null:
		current_click = index
		return
	tiles[current_click.y][current_click.x].clicked = false

	var is_adjacent = (index.x == current_click.x and abs(index.y - current_click.y) == 1) or\
		(index.y == current_click.y and abs(index.x - current_click.x) == 1)
	if not is_adjacent:
		current_click = index
		return

	moves += 1

	var tween: Tween = get_tree().create_tween().set_parallel()
	tween.tween_property(candies[index.y][index.x], "position", tile_position(current_click), MOVE_ANIMATION_TIME)
	tween.tween_property(candies[current_click.y][current_click.x], "position", tile_position(index), MOVE_ANIMATION_TIME)

	var tmp = candies[index.y][index.x]
	candies[index.y][index.x] = candies[current_click.y][current_click.x]
	candies[current_click.y][current_click.x] = tmp

	tiles[index.y][index.x].clicked = false

	check_win(index)
	check_win(current_click)

	current_click = null


func check_win(index: Vector2i):
	pass


func tile_position(index: Vector2i) -> Vector2:
	return Vector2((index.x + 1) * height, (index.y + 1) * height)


func _process(delta):
	%Moves.text = "Moves: %d" % moves
