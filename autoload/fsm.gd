extends Node

class StateMachine:
	var debug := false

	var name_ref: String
	var prev_state
	var current_state
	var state_changed := false
	var state_enum
	var states := {}
	var obj
	var first_run := true

	func _init(state_enum_, initial_state, self_obj, name_ref_: String):
		state_enum = state_enum_
		current_state = initial_state
		obj = self_obj
		name_ref = name_ref_
		var keys = state_enum.keys()
		debug_log("State Machine created. Initial State: %s" % keys[initial_state])
	
	func debug_log(msg: String):
		print("[FSM][%s] %s" % [ name_ref, msg ])

	func register_state(state, class_):
		states[state] = class_.new(self, obj)

	func on_change(prev_state_, new_state_):
		if debug:
			var keys = state_enum.keys()
			debug_log("Previous State: %s, New State: %s" % [keys[prev_state_], keys[new_state_]])
	
	func change_state(new_state):
		if new_state != null and new_state != current_state:
			on_change(current_state, new_state)
			if prev_state != null:
				states[current_state].on_exit(new_state)
			states[new_state].on_enter(current_state)

			prev_state = current_state
			current_state = new_state
			state_changed = true
			states[current_state].frames_active = 0
			states[current_state].seconds_active = 0.0
	
	func force_change(new_state):
		change_state(new_state)

	func physics_process(delta):
		if first_run:
			states[current_state].on_enter(prev_state)
			first_run = false

		var new_state = states[current_state].get_next_state()
		state_changed = false

		for state in states:
			if states[state].force_state_change():
				new_state = state

		change_state(new_state)

		states[current_state].physics_process(delta)
		states[current_state].frames_active += 1
		states[current_state].seconds_active += delta


class State:
	var fsm
	var obj
	var frames_active := 0
	var seconds_active := 0.0

	func _init(fsm_, obj_):
		fsm = fsm_
		obj = obj_

	func force_state_change():
		return false

	func get_next_state():
		return fsm.current_state

	func on_enter(_previous_state):
		pass

	func on_exit(_next_state):
		pass

	func physics_process(_delta):
		pass
