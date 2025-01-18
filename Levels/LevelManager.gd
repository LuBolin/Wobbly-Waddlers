class_name LevelManager
extends Node2D

@onready var inputDelayTimer = $InputDelayTimer # wait time of 1s
@onready var terrain: TileMapLayer = $Terrain

var walls: Array[Vector2i]
var quacker: Quacker
var eggs: Array[Egg]
var ducklings: Array[Duckling]

var level_size: Vector2
var tile_size: Vector2 = Vector2(64, 64);

const MAX_INPUT_BUFFER_SIZE: int = 2
var input_buffer: Array[InputEventKey]
var lingering_input: InputEventKey

func _ready():
	level_size = terrain.get_used_rect().size
	
	walls = terrain.get_used_cells_by_id(0)
	
	var quacker_tile_coord = terrain.get_used_cells_by_id(1)
	assert(len(quacker_tile_coord) == 1)
	quacker_tile_coord = quacker_tile_coord[0]
	terrain.set_cell(quacker_tile_coord, -1)  # Set to -1 to remove the tile
	var quacker_world_pos = tile_to_world(quacker_tile_coord)
	quacker = Quacker.summonQuacker()
	quacker.global_position = quacker_world_pos
	add_child.call_deferred(quacker)
	
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
	
	inputDelayTimer.timeout.connect(handle_input)

func _input(event):
	if not(event is InputEventKey and event.pressed):
		return
	if event.is_action("up") or event.is_action("down") \
		or event.is_action("left") or event.is_action("right"):
		input_buffer.append(event)
	
	if inputDelayTimer.is_stopped():
		handle_input()

func handle_input():
	if input_buffer:
		lingering_input = input_buffer.front()
		input_buffer.pop_front()
	
	var event = lingering_input
	if not event:
		return
	
	var anythingMoved = false
	
	if event.is_action("up"):
		anythingMoved = quackerMove(Vector2.UP)
	elif event.is_action("down"):
		anythingMoved = quackerMove(Vector2.DOWN)
	elif event.is_action("left"):
		anythingMoved = quackerMove(Vector2.LEFT)
	elif event.is_action("right"):
		anythingMoved = quackerMove(Vector2.RIGHT)
	
	if anythingMoved:
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
	if target in duckling_tiles:
		return false
	
	for egg in eggs:
		if target == world_to_tile(egg.position):
			egg.hatch()
			eggs.remove_at(eggs.find(egg))
			
	var target_in_world = tile_to_world(target)
	quacker.move(target_in_world, inputDelayTimer.wait_time)
	return true


### Utility
func restart_level():
	var t = get_tree()
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
