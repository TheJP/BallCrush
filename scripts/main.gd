extends Node2D


const GRID_HEIGHT = 10
const GRID_WIDTH = 10
const MOVE_ANIMATION_TIME = 0.2
const CRUSH_ANIMATION_TIME = 0.5


var tile_scene = preload("res://scenes/tile.tscn")
var candy_scene = preload("res://scenes/candy.tscn")


var tiles = []
var candies = []
var current_click = null
var height: float = 100.0
var moves = 0
var crushes = 0
var disable_input = false
var move_blocked = false
var game_started = false
var move_animation_time = 0.0
var crush_animation_time = 0.0



func _process(delta):
	%Moves.text = "Moves: %d" % moves
	%Crushes.text = "Crushes: %d" % crushes

	if not move_blocked and disable_input:
		move_down()
		if not move_blocked:
			check_win_all()
		if not move_blocked:
			disable_input = false
			if not game_started:
				start_game()


func _ready():
	var viewport_size = get_viewport_rect().size
	height = viewport_size.y / (GRID_HEIGHT + 1)
	for y in range(GRID_HEIGHT):
		var tile_row = []
		var candy_row = []
		for x in range(GRID_WIDTH):
			var index = Vector2i(x, y)

			var tile: Tile = tile_scene.instantiate()
			add_child(tile)
			tile.position = tile_position(index)
			tile.index = index
			tile.on_click.connect(_tile_on_click)
			tile_row.append(tile)

			candy_row.append(create_candy(index))
		tiles.append(tile_row)
		candies.append(candy_row)
	check_win_all()
	if not disable_input:
		start_game()


func _tile_on_click(index: Vector2i):
	if disable_input:
		tiles[index.y][index.x].clicked = false
		return

	if current_click == null:
		current_click = index
		return
	if current_click != index:
		tiles[current_click.y][current_click.x].clicked = false

	var is_adjacent = (index.x == current_click.x and abs(index.y - current_click.y) == 1) or\
		(index.y == current_click.y and abs(index.x - current_click.x) == 1)
	if not is_adjacent:
		current_click = index
		return

	moves += 1

	var tween: Tween = get_tree().create_tween().set_parallel()
	tween.tween_property(candies[index.y][index.x], "position", tile_position(current_click), move_animation_time)
	tween.tween_property(candies[current_click.y][current_click.x], "position", tile_position(index), move_animation_time)

	var tmp = candies[index.y][index.x]
	candies[index.y][index.x] = candies[current_click.y][current_click.x]
	candies[current_click.y][current_click.x] = tmp

	tiles[index.y][index.x].clicked = false

	check_win(index)
	check_win(current_click)

	current_click = null


func start_game():
	if game_started:
		return
	game_started = true
	moves = 0
	crushes = 0
	move_animation_time = MOVE_ANIMATION_TIME
	crush_animation_time = CRUSH_ANIMATION_TIME


func check_win_all():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			check_win(Vector2i(x, y))


func check_win(index: Vector2i):
	var centre_candy = candies[index.y][index.x]

	# Flood fill to find candies of the same colour
	var queue = [index]
	var visited = {index: true}
	var result: Array[Vector2i] = []
	while not queue.is_empty():
		var current = queue.pop_front()
		var current_candy = candies[current.y][current.x]
		if current_candy.colour != centre_candy.colour:
			continue
		result.append(current)
		for permutation in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next = current + permutation
			if next.x < 0 or next.x >= GRID_WIDTH or next.y < 0 or next.y >= GRID_HEIGHT:
				continue
			if visited.has(next) or candies[next.y][next.x].marked_for_remove:
				continue
			queue.push_back(next)
			visited[next] = true

	if len(result) < 3:
		return

	crushes += len(result)
	disable_input = true
	move_blocked = true

	var tween = get_tree().create_tween().set_parallel()
	for current in result:
		var current_candy = candies[current.y][current.x]
		current_candy.marked_for_remove = true
		tween.tween_property(current_candy, "scale", Vector2.ZERO, crush_animation_time).set_delay(move_animation_time)

	tween.set_parallel(false).tween_callback(func(): remove_candies(result))


func remove_candies(indices: Array[Vector2i]):
	for index in indices:
		var candy = candies[index.y][index.x]
		candies[index.y][index.x] = null
		candy.queue_free()
	move_blocked = false


func tile_position(index: Vector2i) -> Vector2:
	return Vector2((index.x + 1) * height, (index.y + 1) * height)


func create_candy(index: Vector2i) -> Candy:
	var candy: Candy = candy_scene.instantiate()
	candy.colour = randi_range(0, len(Candy.COLOURS) - 1)
	add_child(candy)
	candy.position = tile_position(index)
	candy.index = index
	return candy


func move_down():
	var did_move = false
	var tween = get_tree().create_tween().set_parallel()
	for y in range(GRID_HEIGHT - 1, -1, -1):
		for x in range(GRID_WIDTH):
			var index = Vector2i(x, y)
			if candies[y][x] == null:
				did_move = true
				if y > 0 and candies[y - 1][x] != null:
					candies[y][x] = candies[y - 1][x]
					candies[y - 1][x] = null
					tween.tween_property(candies[y][x], "position", tile_position(index), move_animation_time)
				if y == 0:
					var new_candy = create_candy(index)
					candies[y][x] = new_candy
					new_candy.scale = Vector2.ZERO
					tween.tween_property(new_candy, "scale", Vector2.ONE, move_animation_time)

	if did_move:
		move_blocked = true
		tween.set_parallel(false).tween_callback(func(): move_blocked = false)
