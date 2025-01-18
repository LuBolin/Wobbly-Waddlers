extends Node2D

@onready var terrain: TileMapLayer = $Terrain

var walls: Array[Vector2i]
var quacker: Quacker
var crates: Array[Crate]
var crate_coord_array: Array[Array]
var level_size: Vector2
var level_offset: Vector2i
var tile_size: Vector2 = Vector2(64, 64);


func _ready():
	level_size = terrain.get_used_rect().size
	level_offset = terrain.get_used_rect().position
	
	for i in range(level_size.y):
		crate_coord_array.append([])  
		for j in range(level_size.x):
			crate_coord_array[i].append(0)
	
	walls = terrain.get_used_cells_by_id(0)
	
	var quacker_tile_coord = terrain.get_used_cells_by_id(1)[0]
	terrain.set_cell(quacker_tile_coord, -1)  # Set to -1 to remove the tile
	var quacker_world_position = tile_to_world(quacker_tile_coord)
	quacker = Quacker.summonQuacker()
	quacker.global_position = quacker_world_position
	get_parent().add_child.call_deferred(quacker)
	
	for crate_coords in terrain.get_used_cells_by_id(2):
		#	Regular spawning into world and removing from tilemap
		var crate_world_pos = tile_to_world(crate_coords)
		var crate = Crate.summonCrate()
		crate.global_position = crate_world_pos
		get_parent().add_child.call_deferred(crate)
		crates.append(crate)
		#	Stores crates int crate_coord_array. minus terrain rect since crate coord's anchor is center
		crate_coord_array[crate_coords.y - level_offset.y][crate_coords.x - level_offset.x] = crate
		terrain.set_cell(crate_coords, -1)
	for row in crate_coord_array:
			print(row)
	print(crates)
	print(walls)
	

func _input(event):
	if not(event is InputEventKey and event.pressed):
		return
		
	if event.is_action("up"):
		quackerMove(Vector2.UP)
	elif event.is_action("down"):
		quackerMove(Vector2.DOWN)
	elif event.is_action("left"):
		quackerMove(Vector2.LEFT)
	elif event.is_action("right"):
		quackerMove(Vector2.RIGHT)


func quackerMove(direction: Vector2i):
	var anyMoved = false;
	var tile_coords = world_to_tile(quacker.position)
	var target = tile_coords + direction
	print(target)
	if target in walls:
		return false
	elif target in get_crate_tiles():
		var move_crate_array : Array[Crate]
		#	appends immediate crate to array
		var first_crate_coord := Vector2i(target.x, target.y) - level_offset
		move_crate_array.append(crate_coord_array[first_crate_coord.y][first_crate_coord.x])
		
		#	appending next crates
		var next_coord : Vector2i = first_crate_coord + direction
		while(typeof(crate_coord_array[next_coord.y][next_coord.x]) != TYPE_INT):
			print("extra")
			move_crate_array.append(crate_coord_array[next_coord.y][next_coord.x])
			next_coord = next_coord + direction
		print("crate array" , move_crate_array)
		print_crate_coord_array()
		
		#	checking if last crate will push into wall
		var last_crate : Crate = move_crate_array[-1]
		var last_crate_coord = world_to_tile(last_crate.position)
		var last_crate_target = last_crate_coord + direction
		if(last_crate_target not in walls):
			var target_in_world = tile_to_world(target)
			var moved = quacker.move(target_in_world)
			move_crate_array.reverse()
			for crate in move_crate_array:
				var crate_coord = world_to_tile(crate.position)
				var crate_target_in_world = tile_to_world(crate_coord + direction)
				var crate_moved = crate.move(crate_target_in_world)
				update_crate_coord_array(crate_coord.x - level_offset.x, crate_coord.y - level_offset.y, direction)
				print_crate_coord_array()

		
		
	else:
		var target_in_world = tile_to_world(target)
		var moved = quacker.move(target_in_world)
		if moved:
			anyMoved = true;


### Utility
func update_crate_coord_array(init_x : int, init_y : int, direction : Vector2):
	print("initial  spot", crate_coord_array[init_y][init_x] )
	print("initial new spot", crate_coord_array[init_y + direction.y][init_x + direction.x])
	crate_coord_array[init_y + direction.y][init_x + direction.x] = crate_coord_array[init_y][init_x] 
	print("updated new spot", crate_coord_array[init_y + direction.y][init_x + direction.x])
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
	
				
