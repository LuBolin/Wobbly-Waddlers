class_name LevelManager
extends Node2D

@onready var inputDelayTimer: Timer = $InputDelayTimer # wait time of 1s
@onready var terrain: TileMapLayer = $Terrain

var walls: Array[Vector2i]
var quacker: Quacker
var crates: Array[Crate]
var crate_coord_array: Array[Array]
var eggs: Array[Egg]
var ducklings: Array[Duckling]

var level_size: Vector2
var level_offset: Vector2i
var tile_size: Vector2 = Vector2(64, 64);

const MAX_INPUT_BUFFER_SIZE: int = 2
var input_buffer: Array[InputEventKey]
var lingering_input: InputEventKey

var ended: bool = false

func _ready():
	level_size = terrain.get_used_rect().size
	level_offset = terrain.get_used_rect().position
	
	Singleton.restart.connect(self.restart_level)
	
	inputDelayTimer.set_wait_time(Global.TICK_DURATION)
	inputDelayTimer.timeout.connect(handle_input)
	
	parse_tilemaplayer()
	
	Singleton.lose.connect(finish_level)

func parse_tilemaplayer():
	for i in range(level_size.y):
		crate_coord_array.append([])  
		for j in range(level_size.x):
			crate_coord_array[i].append(0)
	
	walls = terrain.get_used_cells_by_id(0)
	
	var quacker_tile_coord = terrain.get_used_cells_by_id(1)
	assert(len(quacker_tile_coord) == 1)
	quacker_tile_coord = quacker_tile_coord[0]
	terrain.set_cell(quacker_tile_coord, -1)  # Set to -1 to remove the tile
	var quacker_world_pos = tile_to_world(quacker_tile_coord)
	quacker = Quacker.summonQuacker()
	quacker.global_position = quacker_world_pos
	add_child(quacker)
	
	for crate_coords in terrain.get_used_cells_by_id(2):
	#	Regular spawning into world and removing from tilemap
		var crate_world_pos = tile_to_world(crate_coords)
		var crate = Crate.summonCrate()
		crate.global_position = crate_world_pos
		add_child.call_deferred(crate)
		crates.append(crate)
		#	Stores crates int crate_coord_array. minus terrain rect since crate coord's anchor is center
		crate_coord_array[crate_coords.y - level_offset.y][crate_coords.x - level_offset.x] = crate
		terrain.set_cell(crate_coords, -1)

	for egg_coords in terrain.get_used_cells_by_id(3):
		var egg_world_pos = tile_to_world(egg_coords)
		var egg = Egg.summonEgg()
		egg.global_position = egg_world_pos
		add_child.call_deferred(egg)
		eggs.append(egg)
		terrain.set_cell(egg_coords, -1)
	
	await get_tree().process_frame.connect(
		func():
			for duckling_coords in terrain.get_used_cells_by_id(4):
				quacker.addDuckling()
				terrain.set_cell(duckling_coords, -1)
	)

func _input(event):
	if not(event is InputEventKey and event.pressed):
		return
	
	if event.is_action("restart"): # not affected by input delay
		Singleton.restart.emit()
	
	if event.is_action("up") or event.is_action("down") \
		or event.is_action("left") or event.is_action("right"):
			if len(input_buffer) < MAX_INPUT_BUFFER_SIZE:
				input_buffer.append(event)
	
	if inputDelayTimer.is_stopped():
		handle_input()

func handle_input():
	if ended:
		return
		
	if input_buffer:
		lingering_input = input_buffer.front()
		input_buffer.pop_front()
	
	var event = lingering_input
	if not event:
		return
	
	var anythingMoved = false
	
	var direction: Vector2
	if event.is_action("up"):
		direction = Vector2.UP
	elif event.is_action("down"):
		direction = Vector2.DOWN
	elif event.is_action("left"):
		direction = Vector2.LEFT
	elif event.is_action("right"):
		direction = Vector2.RIGHT
	
	anythingMoved = quackerMove(direction)
	if not anythingMoved:
		var rotation = quacker.rotation
		if snapped(rotation, PI/2.0) != direction.angle():
			var tile_coords = world_to_tile(quacker.position)
			var target = Vector2(tile_coords) + direction
			var target_in_world = tile_to_world(target)
			quacker.tweenRotation(target_in_world, Global.TICK_DURATION / 2.0)
		quacker.die()
	inputDelayTimer.start()


func quackerMove(direction: Vector2i):
	var anyMoved = false;
	var tile_coords = world_to_tile(quacker.position)
	var target = tile_coords + direction
	
	if target in walls:
		return false
	
	var duckling_tiles = []
	for duckling in ducklings:
		duckling_tiles.append(world_to_tile(duckling.position))
	print(duckling_tiles, " ", target)
	if target in duckling_tiles:
		return false
   
	elif target in get_crate_tiles():
		var move_crate_array : Array[Crate]
		#	appends immediate crate to array
		var first_crate_coord := Vector2i(target.x, target.y) - level_offset
		move_crate_array.append(crate_coord_array[first_crate_coord.y][first_crate_coord.x])
		
		#	appending next crates
		var next_coord : Vector2i = first_crate_coord + direction
		while(crate_coord_array[next_coord.y][next_coord.x]):
			move_crate_array.append(crate_coord_array[next_coord.y][next_coord.x])
			next_coord = next_coord + direction
		# print_crate_coord_array()
		
		#	checking if last crate will push into wall
		var last_crate : Crate = move_crate_array[-1]
		var last_crate_coord = world_to_tile(last_crate.position)
		var last_crate_target = last_crate_coord + direction
		for duckling in ducklings:
			if world_to_tile(duckling.global_position) == last_crate_target:
				duckling.die()
				ducklings.remove_at(ducklings.find(duckling))
		
		for egg in eggs:
			if world_to_tile(egg.global_position) == last_crate_target:
				egg.die()
				eggs.remove_at(eggs.find(egg))
				if len(eggs) == 0:
					Singleton.win.emit()
		if(last_crate_target not in walls):
			var target_in_world = tile_to_world(target)
			var moved = quacker.move(target_in_world)
			move_crate_array.reverse()
			for crate in move_crate_array:
				var crate_coord = world_to_tile(crate.position)
				var crate_target_in_world = tile_to_world(crate_coord + direction)
				var crate_moved = crate.move(crate_target_in_world)
				update_crate_coord_array(crate_coord.x - level_offset.x, crate_coord.y - level_offset.y, direction)
		return true
	else:
		for egg in eggs:
			if target == world_to_tile(egg.position):
				egg.hatch()
				eggs.remove_at(eggs.find(egg))
		var target_in_world = tile_to_world(target)
		quacker.move(target_in_world)
		return true
	return false

func finish_level():
	ended = true

### Utility
func update_crate_coord_array(init_x : int, init_y : int, direction : Vector2):
	# print("initial  spot", crate_coord_array[init_y][init_x] )
	# print("initial new spot", crate_coord_array[init_y + direction.y][init_x + direction.x])
	crate_coord_array[init_y + direction.y][init_x + direction.x] = crate_coord_array[init_y][init_x] 
	# print("updated new spot", crate_coord_array[init_y + direction.y][init_x + direction.x])
	crate_coord_array[init_y][init_x] = 0
	
func print_crate_coord_array():
	for row in crate_coord_array:
		var s = ""
		for element in row:
			if element is Crate:  # Replace 'InstanceClass' with the actual class name
				s += "1 "
			else:
				s += "0 "
		print(s)  # For a newline after the array is printed

func get_crate_tiles():
	var crate_tiles: Array[Vector2i] = []
	for crate in crates:
		crate_tiles.append(world_to_tile(crate.position))
	return crate_tiles
	
func clear_all():
	quacker.queue_free()
	for duckling in ducklings:
		duckling.queue_free()
	for egg in eggs:
		egg.queue_free()
	for crate in crates:
		crate.queue_free()
	
func restart_level():
	var t = get_tree()
	clear_all()
	if t:
		t.reload_current_scene()
	else:
		pass

func world_to_tile(world_pos: Vector2):
	var local = terrain.to_local(world_pos)
	var tile = terrain.local_to_map(local)
	return tile

func tile_to_world(tile_coords: Vector2):
	var local = terrain.map_to_local(tile_coords)
	var global = terrain.to_global(local)
	return global

func check_win_lose():
	pass
