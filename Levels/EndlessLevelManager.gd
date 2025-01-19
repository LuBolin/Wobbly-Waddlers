class_name EndlessLevelManager
extends LevelManager

func _ready():
	level_size = terrain.get_used_rect().size
	level_offset = terrain.get_used_rect().position
	
	Singleton.restart.connect(self.restart_level)
	
	inputDelayTimer.set_wait_time(Global.TICK_DURATION)
	# Endless
	inputDelayTimer.timeout.connect(endless_drop_random_tiles)
	
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
		return false
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

func get_torque():
	var torque_at_1 = 0
	var entities = [quacker] + ducklings + eggs + crates
	for entity: Node2D in entities:
		torque_at_1 += (entity.global_position.x - stand_x_val)
	return torque_at_1

func set_stand_x(x: float):
	stand_indicator_line.clear_points()
	stand_x_val = x
	var height = 324 # un-hardcode later
	var topPoint = Vector2(x, -height)
	var btmPoint = Vector2(x, height)
	stand_indicator_line.add_point(topPoint)
	stand_indicator_line.add_point(btmPoint)


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


# Endless extras
var ticks_since_last_tile = 0
const TICKS_UNTIL_NEXT_TILE = 3
func endless_drop_random_tiles():
	# quacker offmap
	var tile_coords = world_to_tile(quacker.position) - level_offset
	if tile_coords.x < 2 or tile_coords.x > level_size.x - 3 or tile_coords.y < 2 or tile_coords.y > level_size.y - 3:
		quacker.die()
	
	# remove edge crates
	for i in range(level_size.y):
		if crate_coord_array[i][1] is Crate:
			var c = crate_coord_array[i][1]
			crate_coord_array[i][1] = 0
			for j in range(crates.size()):
				if crates[j] == c:
					crates.remove_at(j)
					break
			c.queue_free()
		if crate_coord_array[i][level_size.x - 2] is Crate:
			var c = crate_coord_array[i][level_size.x - 2]
			crate_coord_array[i][level_size.x - 2] = 0
			for j in range(crates.size()):
				if crates[j] == c:
					crates.remove_at(j)
					break
			c.queue_free()
	for i in range(level_size.y):
		if crate_coord_array[1][i] is Crate:
			var c = crate_coord_array[1][i]
			crate_coord_array[1][i] = 0
			for j in range(crates.size()):
				if crates[j] == c:
					crates.remove_at(j)
					break
			c.queue_free()
		if crate_coord_array[level_size.y - 2][i] is Crate:
			var c = crate_coord_array[level_size.y - 2][i]
			crate_coord_array[level_size.y - 2][i] = 0
			for j in range(crates.size()):
				if crates[j] == c:
					crates.remove_at(j)
					break
			c.queue_free()
	
	
	ticks_since_last_tile += 1
	if ticks_since_last_tile >= TICKS_UNTIL_NEXT_TILE:
		ticks_since_last_tile = 0
		#drop item
		var item = endless_choose_random_item()
		var item_coords = endless_choose_random_coords()
		print(item_coords)
		item.global_position = tile_to_world(item_coords)
		add_child.call_deferred(item)
		if item is Egg:
			eggs.append(item)
		if item is Crate:
			crates.append(item)
			print(crate_coord_array.size())
			print(crate_coord_array[0].size())
			crate_coord_array[item_coords.y - level_offset.y][item_coords.x - level_offset.x] = item
		terrain.set_cell(item_coords, -1)

# Egg, Block
func endless_choose_random_item():
	match randi_range(0, 1):
		0: 
			return Egg.summonEgg()
		1:
			return Crate.summonCrate()

func endless_choose_random_coords():
	var choice_array = []
	for i in range(2, level_size.y - 2):
		for j in range(2, level_size.x - 2):
			if crate_coord_array[i][j] is Crate:
				continue
			choice_array.append([i, j])
	var chosen = choice_array.pick_random()
	return Vector2(chosen[1] + level_offset.x, chosen[0] + level_offset.y)
